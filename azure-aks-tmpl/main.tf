locals {
  aks_cluster_name = "myCluster"
}

module "vault" {
  source = "../azurerm-vault"
}

module "aks" {
  source             = "../azurerm-aks"
  aks_enable_cluster = "1"
  aks_cluster_name   = local.aks_cluster_name
  aks_cidr           = "10.1.0.0/16"
  tags               = { "environment" = "temp" }
  aks_k8s_version    = "1.27"
  depends_on         = [module.vault]
}

module "helm-cert-manager" {
  source = "../helm-cert-manager"
  depends_on = [module.aks]
  aks_cluster_name = local.aks_cluster_name
  cert-manager-enable = "true"
  namespace = "cert-manager"
}


