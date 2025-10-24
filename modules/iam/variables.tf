variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user to add to the k8s group"
  type        = string
}

variable "iam_group_name" {
  description = "Name for the IAM group that will manage K8s resources"
  type        = string
  default     = "k8s-admins"
}

variable "compartment_name" {
  description = "Name (not OCID) of the compartment where resources will be created"
  type        = string
}