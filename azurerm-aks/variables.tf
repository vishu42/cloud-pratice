variable "aks_enable_cluster" {
  description = "Deploy AKS cluster?"
  default     = "1"
  validation {
    condition     = can(regex("0|1", var.aks_enable_cluster))
    error_message = "The variable has to be one of 0 or 1."
  }
}

variable "aks_cluster_name" {
  description = "Name of the aks cluster being deployed"
  default = "myCluster"
}

variable "aks_cidr" {
  description = "CIDR for the AKS cluster"
  default     = "10.1.0.0/16"
}

variable "tags" {
  description = "Tags for the AKS cluster"
  default     = {"environment" = "dev"}
}

variable "aks_k8s_version" {
  description = "Kubernetes version for the AKS cluster"
  default     = "1.27"
}

