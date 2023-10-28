locals {
  aks_cluster_name = "cluster01"
  tags            = { "environment" = "todelete" }
}

module "vault" {
  source = "../azurerm-vault"
  tags   = local.tags
}

module "aks" {
  source             = "../azurerm-aks"
  aks_enable_cluster = "1"
  aks_cluster_name   = local.aks_cluster_name
  aks_cidr           = "10.1.0.0/16"
  tags               = local.tags
  aks_k8s_version    = "1.27"
  depends_on         = [module.vault]
}



