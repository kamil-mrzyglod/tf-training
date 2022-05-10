resource "azurerm_mssql_server" "training" {
  name                         = "kamilm-tf-sqlserver"
  resource_group_name          = azurerm_resource_group.training.name
  location                     = azurerm_resource_group.training.location
  version                      = "12.0"
  administrator_login          = local.sql_login
  administrator_login_password = local.sql_admin_password
}

resource "azurerm_mssql_database" "training" {
  name        = "kamilm-tf-sqldb"
  server_id   = azurerm_mssql_server.training.id
  sku_name    = "S0"
  max_size_gb = 10
}

resource "azurerm_key_vault_secret" "secret4" {
  name = "sql-connection-string"
  value = "Server=tcp:${azurerm_mssql_server.training.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.training.name};Persist Security Info=False;User ID=${local.sql_login};Password=${local.sql_admin_password};MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.training.id
}
