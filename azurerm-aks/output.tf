output "kube-admin-config" {
  value       = try(azurerm_kubernetes_cluster.default[0].kube_admin_config_raw, "no-luster")
  description = "Kubernetes admin config."
  sensitive   = true
}

resource "azurerm_key_vault_secret" "kube-admin-config" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "${var.aks_cluster_name}-kube-admin-config"
  value        = try(azurerm_kubernetes_cluster.default[0].kube_admin_config_raw, "nocluster")
}

output "client-key" {
  value       = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].client_key, "nocluster")
  description = "Kubernetes client key."
  sensitive   = true
}

resource "azurerm_key_vault_secret" "client-key" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "${var.aks_cluster_name}-client-key"
  value        = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].client_key, "nocluster")
}

output "client-certificate" {
  value       = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].client_certificate, "nocluster")
  description = "Kubernetes client cert."
  sensitive   = true
}

resource "azurerm_key_vault_secret" "client-certificate" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "${var.aks_cluster_name}-client-certificate"
  value        = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].client_certificate, "nocluster")
}

output "cluster-ca-certificate" {
  value       = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].cluster_ca_certificate, "nocluster")
  description = "Kubernetes cluster CA cert."
  sensitive   = true
}

resource "azurerm_key_vault_secret" "cluster-ca-certificate" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "${var.aks_cluster_name}-cluster-ca-certificate"
  value        = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].cluster_ca_certificate, "nocluster")
}

output "host" {
  value       = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].host, "nocluster")
  description = "Kubernetes host."
  sensitive   = true
}

resource "azurerm_key_vault_secret" "host" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "${var.aks_cluster_name}-host"
  value        = try(azurerm_kubernetes_cluster.default[0].kube_admin_config[0].host, "nocluster")
}

resource "azurerm_key_vault_secret" "azure-sp-id" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "azure-sp-id"
  value        = azuread_service_principal.service_principal[0].id
}

resource "azurerm_key_vault_secret" "azure-sp-secret" {
  key_vault_id = data.azurerm_key_vault.target.id
  name         = "azure-sp-secret"
  value        = azuread_service_principal_password.service_principal_sp_pwd[0].value
}


