# IAM Module for setting up required permissions
module "iam" {
  source = "./modules/iam"

  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  iam_group_name   = var.iam_group_name
  compartment_name = var.compartment_name
}

# VCN
resource "oci_core_vcn" "k8s_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "k8s-vcn"
  dns_label      = "k8svcn"

  # Add dependency on IAM module to ensure permissions exist
  depends_on = [module.iam]
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  display_name   = "k8s-internet-gateway"
  vcn_id         = oci_core_vcn.k8s_vcn.id
}

# Route Table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
}

# Security List
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.k8s_vcn.id
  display_name   = "k8s-security-list"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  ingress_security_rules {
    protocol  = "all"
    source    = "10.0.0.0/16"
    stateless = false
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      max = 22
      min = 22
    }
  }

  ingress_security_rules {
    protocol  = "6"
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      max = 6443
      min = 6443
    }
  }
}

# Subnet
resource "oci_core_subnet" "k8s_subnet" {
  cidr_block        = "10.0.1.0/24"
  compartment_id    = var.compartment_ocid
  vcn_id           = oci_core_vcn.k8s_vcn.id
  display_name      = "k8s-subnet"
  route_table_id    = oci_core_route_table.route_table.id
  security_list_ids = [oci_core_security_list.security_list.id]
}

# Kubernetes Cluster
resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  vcn_id            = oci_core_vcn.k8s_vcn.id

  options {
    service_lb_subnet_ids = [oci_core_subnet.k8s_subnet.id]
    
    add_ons {
      is_kubernetes_dashboard_enabled = true
      is_tiller_enabled             = false
    }

    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.k8s_subnet.id
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = var.node_pool_name
  node_shape         = "VM.Standard.A1.Flex"

  node_shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  node_config_details {
    size = 2
    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.ads.availability_domains
      content {
        availability_domain = placement_configs.value.name
        subnet_id          = oci_core_subnet.k8s_subnet.id
      }
    }
  }

  node_source_details {
    # Use Oracle Linux 8.10 ARM image
    source_type = "IMAGE"
    image_id    = coalesce(try(data.oci_core_images.node_pool_images.images[0].id, null), 
                          "ocid1.image.oc1.uk-london-1.aaaaaaaaavhcvlf3o2ven2l6cia3i4ton4gurepucrfhrcwj2qfekrr3pqha") # Fallback to known Oracle Linux 8.10 ARM image
  }

  ssh_public_key = var.ssh_public_key
}

# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid # Changed to tenancy_ocid as ADs are at tenancy level
}

# Get available k8s versions
data "oci_containerengine_cluster_option" "cluster_options" {
    cluster_option_id = "all"
    compartment_id    = var.compartment_ocid
}

# Get OKE node pool options
data "oci_containerengine_node_pool_option" "node_pool_options" {
    node_pool_option_id = "all"
    compartment_id      = var.compartment_ocid
}

# Get Oracle Linux image for node pool
data "oci_core_images" "node_pool_images" {
    compartment_id = var.tenancy_ocid
    operating_system = "Oracle Linux"
    operating_system_version = "8"
    shape = "VM.Standard.A1.Flex"
    sort_by = "TIMECREATED"
    sort_order = "DESC"

    # Look for the latest Oracle Linux 8.10 ARM image
    filter {
        name = "display_name"
        values = ["Oracle-Linux-8.10-aarch64-2025.09.16-0"]
        regex = false
    }
}

# Output debugging information
output "debug_info" {
  value = {
    node_pool_options = data.oci_containerengine_node_pool_option.node_pool_options
    selected_image    = data.oci_core_images.node_pool_images.images[*]
  }
}

# Output IAM information
output "iam_info" {
  value = {
    group_name = oci_identity_group.k8s_group.name
    group_id   = oci_identity_group.k8s_group.id
    policies   = {
      network = oci_identity_policy.k8s_network_policy.name
      cluster = oci_identity_policy.k8s_cluster_policy.name
      compute = oci_identity_policy.k8s_compute_policy.name
      lb      = oci_identity_policy.k8s_lb_policy.name
    }
  }
}

output "available_kubernetes_versions" {
    value = data.oci_containerengine_cluster_option.cluster_options.kubernetes_versions
}