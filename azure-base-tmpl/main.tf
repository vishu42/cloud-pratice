module "vault" {
    source = "github.com/vishu42/cloud-pratice/tree/develop/vault"
    tags   = { "environment" = "temp" }
}

module "aks" {
  source             = "github.com/vishu42/cloud-pratice/tree/develop/aks"
  aks_enable_cluster = "1"
  aks_cluster_name   = "myCluster"
  aks_cidr           = "10.1.0.0/16"
  tags               = { "environment" = "temp" }
  aks_k8s_version    = "1.27"
}


