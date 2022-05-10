resource "azurerm_service_plan" "training" {
  name                = "kamilm-tf-appserviceplan"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "training" {
  name                = "kamilm-tf-webapp"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  service_plan_id     = azurerm_service_plan.training.id

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.training.instrumentation_key
  }

  site_config {

  }
}

resource "azurerm_application_insights" "training" {
  name                = "kamilm-tf-ai"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "training" {
  name                 = "kamilm-tf-functionapp"
  resource_group_name  = azurerm_resource_group.training.name
  location             = azurerm_resource_group.training.location
  service_plan_id      = azurerm_service_plan.training.id
  storage_account_name = "kmfunctionstorage"

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.training.instrumentation_key
  }

  site_config {
      application_stack {
        dotnet_version = "6.0"
      }
  }
}

module "function-app-storage-account" {
  source = "./modules/storage-account"

  storage_account_name = "kmfunctionstoragetf"
  resource_group_name  = azurerm_resource_group.training.name
  location             = azurerm_resource_group.training.location
}
