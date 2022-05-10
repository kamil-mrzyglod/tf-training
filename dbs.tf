resource "azurerm_mssql_server" "training" {
  name = "kamilm-tf-sqlserver"
  resource_group_name = azurerm_resource_group.training.name
  location = azurerm_resource_group.training.location
  version = "12.0"
  administrator_login = "test_admin"
  administrator_login_password = local.sql_admin_password
}