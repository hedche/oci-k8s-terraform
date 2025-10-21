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
  description = "The version of kubernetes to use"
  type        = string
  default     = "v1.26.2"  # Update this to the latest available version
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