terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "kamilm-tf-monitor-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "to_monitor" {
  name                     = "kamilmonitorsa123"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_action_group" "main" {
  name                = "example-actiongroup"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "exampleact"

  webhook_receiver {
    name        = "callmyapi"
    service_uri = "http://example.com/alert"
  }

  
}

resource "azurerm_monitor_metric_alert" "example" {
  name                = "example-metricalert2"
  resource_group_name = azurerm_resource_group.example.name
  scopes              = [azurerm_storage_account.to_monitor.id]
  description         = "Action will be triggered when Transactions count is greater than 50."

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Transactions"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 50

    dimension {
      name     = "ApiName"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "acctest-01"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = "tfexample"
  target_resource_id = azurerm_storage_account.to_monitor.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

#   log {
#     category = "StorageWrite"
#     enabled  = true

#     retention_policy {
#       enabled = false
#     }
#   }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

data "azurerm_monitor_diagnostic_categories" "example" {
  resource_id = azurerm_resource_group.to_monitor.id
}

output "log-categories" {
  value = data.azurerm_monitor_diagnostic_categories.example.logs
}

output "metric-categories" {
  value = data.azurerm_monitor_diagnostic_categories.example.metrics
}