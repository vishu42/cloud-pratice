data "azurerm_subscription" "default" {
}

locals {
    key_vault_stub = replace(lower(data.azurerm_subscription.default.display_name), " ", "-")
}

# create a resource group for the key vault with the same name as the subscription but lowercase and without spaces
resource "azurerm_resource_group" "default" {
  name     = "${local.key_vault_stub}-rg"
  location = "West Europe"
}

# create a key vault
resource "azurerm_key_vault" "mykeyvault" {
  name                        = "shared-${local.key_vault_stub}-kv"
  location                    = azurerm_resource_group.default.location
  resource_group_name         = azurerm_resource_group.default.name
  tenant_id                   = "1c721276-b529-4426-8bd0-29192fb2b12a"  # Replace with your Azure AD tenant ID
  sku_name                    = "standard"
  enabled_for_deployment      = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
}
