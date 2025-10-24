# IAM Group for K8s cluster management
resource "oci_identity_group" "k8s_group" {
  compartment_id = var.tenancy_ocid
  name           = var.iam_group_name
  description    = "Group for managing OKE cluster resources"
}

# Add specified user to the K8s group
resource "oci_identity_user_group_membership" "user_membership" {
  user_id  = var.user_ocid
  group_id = oci_identity_group.k8s_group.id
}

# Network policy for VCN management
resource "oci_identity_policy" "k8s_network_policy" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-network-policy"
  description    = "Allow k8s group to manage virtual network resources"
  statements = [
    "allow group ${oci_identity_group.k8s_group.name} to manage virtual-network-family in compartment ${var.compartment_name}"
  ]
}

# Cluster management policy
resource "oci_identity_policy" "k8s_cluster_policy" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-cluster-policy"
  description    = "Allow k8s group to manage cluster resources"
  statements = [
    "allow group ${oci_identity_group.k8s_group.name} to manage cluster-family in compartment ${var.compartment_name}"
  ]
}

# Compute management policy
resource "oci_identity_policy" "k8s_compute_policy" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-compute-policy"
  description    = "Allow k8s group to manage compute resources"
  statements = [
    "allow group ${oci_identity_group.k8s_group.name} to manage compute-family in compartment ${var.compartment_name}"
  ]
}

# Load balancer policy
resource "oci_identity_policy" "k8s_lb_policy" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-load-balancer-policy"
  description    = "Allow k8s group to manage load balancers"
  statements = [
    "allow group ${oci_identity_group.k8s_group.name} to manage load-balancer-family in compartment ${var.compartment_name}"
  ]
}