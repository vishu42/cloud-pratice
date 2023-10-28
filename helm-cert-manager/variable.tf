variable "aks_cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "certmanager_enable" {
  description = "Enable cert manager?"
  default     = "1"
  validation {
    condition     = can(regex("0|1", var.certmanager_enable))
    error_message = "The variable has to be one of 0 or 1."
  }
}

variable "namespace" {
  description = "Value of namespace."
  type        = string
}