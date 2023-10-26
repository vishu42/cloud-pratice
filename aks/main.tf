# Load subscription details for vault
data "azurerm_subscription" "default" {
}

data "azuread_client_config" "current" {}

locals {
  tags_azuread = formatlist("%s=\"%s\"", keys(var.tags), values(var.tags))
  years        = 10
  subnet_prefix_lengths = [
    for i in range(2) : cidrsubnet(var.aks_cidr, 8, i)
  ]
}

# Create active directory application
resource "azuread_application" "service_principal" {
  count        = var.aks_enable_cluster
  owners       = concat([data.azuread_client_config.current.object_id])
  display_name = "${var.aks_cluster_name}rootSp"
  web {
    homepage_url = "https://${var.aks_cluster_name}rootSp"
  }

  depends_on = [
    azurerm_resource_group.default,
  ]

  provisioner "local-exec" {
    command = "sleep 60"
  }

  tags = local.tags_azuread
}

# Create the service principal
resource "azuread_service_principal" "service_principal" {
  count          = var.aks_enable_cluster
  application_id = azuread_application.service_principal[0].application_id

  owners = concat([data.azuread_client_config.current.object_id])
  tags   = local.tags_azuread

  depends_on = [
    azurerm_resource_group.default,
    azuread_application.service_principal,
  ]
}

# Set the password
resource "azuread_service_principal_password" "service_principal_sp_pwd" {
  count                = var.aks_enable_cluster
  service_principal_id = azuread_service_principal.service_principal[0].id
  end_date             = timeadd(timestamp(), "${local.years * 24 * 365}h")

  depends_on = [
    azuread_application.service_principal,
    azuread_service_principal.service_principal,
  ]
}

# Add role to service principle.
resource "azurerm_role_assignment" "service_principal" {
  count                = var.aks_enable_cluster
  scope                = azurerm_resource_group.default[count.index].id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.service_principal[0].id

  depends_on = [
    azurerm_resource_group.default,
  ]
}

# Create a resource group
resource "azurerm_resource_group" "default" {
  count    = 1
  name     = "${var.aks_cluster_name}-aks-rg"
  location = "West Europe"
}

# Create the virtual network
resource "azurerm_virtual_network" "default" {
  count               = var.aks_enable_cluster
  name                = "${var.aks_cluster_name}-network"
  location            = azurerm_resource_group.default.0.location
  resource_group_name = azurerm_resource_group.default.0.name
  address_space       = [var.aks_cidr]
  tags                = var.tags
}

# add role "Network Contributor" to the service principle
resource "azurerm_role_assignment" "network_contributor" {
  count                = var.aks_enable_cluster
  scope                = azurerm_virtual_network.default[count.index].id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.service_principal[0].id

  depends_on = [
    azurerm_resource_group.default,
    azurerm_virtual_network.default,
  ]
}

# create a private dns zone
resource "azurerm_private_dns_zone" "blob" {
  count               = var.aks_enable_cluster
  name                = "myprivatednszone.net"
  resource_group_name = azurerm_resource_group.default[0].name
  tags                = var.tags

  depends_on = [azurerm_resource_group.default]
}

# Create the subnet
resource "azurerm_subnet" "default" {
  count                = var.aks_enable_cluster
  name                 = "${var.aks_cluster_name}-subnet-default"
  resource_group_name  = azurerm_resource_group.default[count.index].name
  address_prefixes     = [local.subnet_prefix_lengths[0]]
  virtual_network_name = azurerm_virtual_network.default[0].name
}

# create another subnet for application gateway
resource "azurerm_subnet" "appgw" {
  count                = var.aks_enable_cluster
  name                 = "${var.aks_cluster_name}-subnet-appgw"
  resource_group_name  = azurerm_resource_group.default[count.index].name
  address_prefixes     = [local.subnet_prefix_lengths[1]]
  virtual_network_name = azurerm_virtual_network.default[0].name
}

# associate the private dns zone with the vnet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count                 = var.aks_enable_cluster
  name                  = "${var.aks_cluster_name}-dns-vnet-link"
  resource_group_name   = "${var.aks_cluster_name}-aks-rg"
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.default[0].id
  tags                  = var.tags
}

# create kubernetes service
resource "azurerm_kubernetes_cluster" "default" {
  count               = var.aks_enable_cluster
  name                = "${var.aks_cluster_name}-aks-cluster"
  location            = azurerm_resource_group.default.0.location
  resource_group_name = azurerm_resource_group.default.0.name
  kubernetes_version  = var.aks_k8s_version

  # Setup the Agent pool for the cluster.
  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = element(concat(azurerm_subnet.default.*.id, [""]), 0)
    # Note - AKS requires lowercase nodepool labels
    node_labels                  = { "nodepool" : "default" }
    orchestrator_version         = var.aks_k8s_version
    only_critical_addons_enabled = false
  }

  # Assign the service principle to the cluster
  service_principal {
    client_id     = azuread_application.service_principal[0].application_id
    client_secret = azuread_service_principal_password.service_principal_sp_pwd[0].value
  }

  ingress_application_gateway {
    subnet_id = element(concat(azurerm_subnet.appgw.*.id, [""]), 0)
  }

  dns_prefix = "${var.aks_cluster_name}-aks-cluster"

  tags = var.tags

  # Setup dependencies
  depends_on = [
    azurerm_resource_group.default,
    azurerm_role_assignment.service_principal,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
  name                  = "internal"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default[0].id
  vm_size               = "Standard_B2s"
  node_count            = 1
  tags                  = var.tags
}



