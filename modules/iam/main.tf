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

# Combined policy for all required permissions
resource "oci_identity_policy" "k8s_policy" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-cluster-policy"
  description    = "Policy for OKE cluster management"
  statements = [
    "allow group ${oci_identity_group.k8s_group.name} to manage cluster-family in tenancy",
    "allow group ${oci_identity_group.k8s_group.name} to manage virtual-network-family in tenancy",
    "allow group ${oci_identity_group.k8s_group.name} to manage instance-family in tenancy",
    "allow group ${oci_identity_group.k8s_group.name} to inspect compartments in tenancy"
  ]
}

# Output the created resources
output "group_name" {
  description = "Name of the created IAM group"
  value       = oci_identity_group.k8s_group.name
}

output "group_id" {
  description = "OCID of the created IAM group"
  value       = oci_identity_group.k8s_group.id
}

output "policy" {
  description = "Created policy details"
  value = {
    name        = oci_identity_policy.k8s_policy.name
    id          = oci_identity_policy.k8s_policy.id
    statements  = oci_identity_policy.k8s_policy.statements
  }
}