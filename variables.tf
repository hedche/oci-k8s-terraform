variable "tenancy_ocid" {
  description = "The OCID of your tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "region" {
  description = "The OCI region"
  type        = string
}

variable "compartment_ocid" {
  description = "The OCID of the compartment"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OKE cluster"
  type        = string
  default     = "oci-free-k8s-cluster"
}

variable "kubernetes_version" {
  description = "The version of kubernetes to use. As of Oct 2025, should be at least v1.30.x"
  type        = string
  # We'll set this dynamically based on available versions
  validation {
    condition     = can(regex("^v1\\.(3[0-9]|[4-9][0-9])", var.kubernetes_version))
    error_message = "Kubernetes version must be v1.30.0 or higher as of Oct 2025"
  }
}

# IAM Variables
variable "iam_group_name" {
  description = "Name for the IAM group that will manage K8s resources"
  type        = string
  default     = "k8s-admins"
}

variable "compartment_name" {
  description = "Name (not OCID) of the compartment where resources will be created"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user to add to the k8s group (optional)"
  type        = string
  default     = ""
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
  default     = "free-tier-node-pool"
}

variable "ssh_public_key" {
  description = "The SSH public key for node access"
  type        = string
}