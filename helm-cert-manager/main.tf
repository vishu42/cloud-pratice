# get current subscription
data "azurerm_subscription" "default" {}

# get vault details
data "azurerm_key_vault" "target" {
  name                = "shared-${local.key_vault_stub}-kv"
  resource_group_name = "${local.key_vault_stub}-rg"
}

data "azurerm_key_vault_secret" "host" {
  name         = "${var.aks_cluster_name}-host"
  key_vault_id = data.azurerm_key_vault.target.id
}

data "azurerm_key_vault_secret" "client_key" {
  name         = "${var.aks_cluster_name}-client-key"
  key_vault_id = data.azurerm_key_vault.target.id
}

data "azurerm_key_vault_secret" "client_certificate" {
  name         = "${var.aks_cluster_name}-client-certificate"
  key_vault_id = data.azurerm_key_vault.target.id
}

data "azurerm_key_vault_secret" "cluster_ca_certificate" {
  name         = "${var.aks_cluster_name}-cluster-ca-certificate"
  key_vault_id = data.azurerm_key_vault.target.id
}

data "azurerm_key_vault_secret" "kube_admin_config" {
  name         = "${var.aks_cluster_name}-kube-admin-config"
  key_vault_id = data.azurerm_key_vault.target.id
}

locals {
  cluster_ca_certificate = try(base64decode(data.azurerm_key_vault_secret.cluster_ca_certificate.value), "")
  client_key             = try(base64decode(data.azurerm_key_vault_secret.client_key.value), "")
  client_certificate     = try(base64decode(data.azurerm_key_vault_secret.client_certificate.value), "")
  host                   = try(data.azurerm_key_vault_secret.host.value, "")
  kube_config            = try(data.azurerm_key_vault_secret.kube_admin_config.value, "")
  key_vault_stub         = replace(lower(data.azurerm_subscription.default.display_name), " ", "-")
  kube_config_path       = "kube-config-${var.aks_cluster_name}"
}

resource "helm_release" "cert-manager" {
  count            = var.certmanager_enable
  name             = "${var.namespace}"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = var.namespace
  version          = "v1.13.0"
  timeout          = 120
  verify           = false
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }
}

# issuer for cert-manager
resource "local_file" "issuer_manifest" {
  count    = var.certmanager_enable
  filename = "issuer.yaml"
  content = <<-EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: tewatiavishal3@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging
    # Enable the HTTP-01 challenge provider
    solvers:
      - http01:
           ingress:
              class: azure/application-gateway
EOF
  depends_on = [
    helm_release.cert-manager,
    # local_file.kube_config
  ]
}

# create issuer
resource "kubectl_manifest" "issuer" {
  count    = var.certmanager_enable
  yaml_body = local_file.issuer_manifest[0].content
  depends_on = [
    helm_release.cert-manager,
    local_file.issuer_manifest
  ]
}