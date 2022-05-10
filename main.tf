module "first-storage-account" {
  source = "./modules/storage-account"

  storage_account_name = "moduledtfkamilm1"
  resource_group_name  = azurerm_resource_group.training.name
  location             = azurerm_resource_group.training.location
}

module "second-storage-account" {
  source = "./modules/storage-account"

  storage_account_name = "moduledtfkamilm2"
  resource_group_name  = azurerm_resource_group.training.name
  location             = azurerm_resource_group.training.location
}

module "third-storage-account" {
  source = "./modules/storage-account"

  storage_account_name = "moduledtfkamilm3"
  resource_group_name  = azurerm_resource_group.training.name
  location             = azurerm_resource_group.training.location
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "training" {
  name                       = "kamiltfkvbackend"
  location                   = azurerm_resource_group.training.location
  resource_group_name        = azurerm_resource_group.training.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  sku_name                   = "standard"

  access_policy {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = data.azurerm_client_config.current.object_id
      secret_permissions      = ["Get", "List", "Set"]
  }
}

resource "azurerm_key_vault_secret" "secret1" {
  name = "static-storage-connection-string1"
  value = module.first-storage-account.primary_connection_string
  key_vault_id = azurerm_key_vault.training.id
}

resource "azurerm_key_vault_secret" "secret2" {
  name = "static-storage-connection-string2"
  value = module.second-storage-account.primary_connection_string
  key_vault_id = azurerm_key_vault.training.id
}

resource "azurerm_key_vault_secret" "secret3" {
  name = "static-storage-connection-string3"
  value = module.third-storage-account.primary_connection_string
  key_vault_id = azurerm_key_vault.training.id
}

resource "azurerm_key_vault_secret" "secret-sql-admin-password" {
  name = "ssql-admin-password"
  value = local.sql_admin_password
  key_vault_id = azurerm_key_vault.training.id
}