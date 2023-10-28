data "azurerm_subscription" "default" {
}

locals {
  key_vault_stub = replace(lower(data.azurerm_subscription.default.display_name), " ", "-")
}

# get the current client config
data "azurerm_client_config" "current" {
}

# create a resource group for the key vault with the same name as the subscription but lowercase and without spaces
resource "azurerm_resource_group" "default" {
  name     = "${local.key_vault_stub}-rg"
  location = "West Europe"
  tags     = var.tags
}

# create a key vault
resource "azurerm_key_vault" "mykeyvault" {
  name                            = "shared-${local.key_vault_stub}-kv"
  location                        = azurerm_resource_group.default.location
  resource_group_name             = azurerm_resource_group.default.name
  tenant_id                       = "1c721276-b529-4426-8bd0-29192fb2b12a" # Replace with your Azure AD tenant ID
  sku_name                        = "standard"
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true
  soft_delete_retention_days      = 7
  tags                            = var.tags
}

resource "azurerm_key_vault_access_policy" "vault" {
  key_vault_id        = azurerm_key_vault.mykeyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
  key_permissions = [ "Get", "Delete", "Purge", "List", "Update", "Create" ]
  secret_permissions = [  "Get","List","Set", "Delete", "Recover", "Backup", "Restore", "Purge" ]

  depends_on = [azurerm_key_vault.mykeyvault]
}
