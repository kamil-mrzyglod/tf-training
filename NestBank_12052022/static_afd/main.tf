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

resource "azurerm_resource_group" "training" {
  name     = "nestbank-tf-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "name" {
  name                     = "kamilmnesttfstorage"
  resource_group_name      = azurerm_resource_group.training.name
  location                 = azurerm_resource_group.training.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.name.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "index.html"
  content_type           = "text/html; charset=utf-8"
}

resource "azurerm_storage_blob" "error404" {
  name                   = "404.html"
  storage_account_name   = azurerm_storage_account.name.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "404.html"
  content_type           = "text/html; charset=utf-8"
}

resource "azurerm_frontdoor" "training" {
  name                = "kamilm-nest-afd"
  resource_group_name = azurerm_resource_group.training.name

  routing_rule {
    name               = "routingRule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["frontend"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "static-backend"
    }
  }

  backend_pool_load_balancing {
    name = "loadBalancing"
  }

  backend_pool_health_probe {
    name = "healthProbe"
  }

  backend_pool {
    name = "static-backend"
    backend {
      host_header = azurerm_storage_account.name.primary_web_host
      address     = azurerm_storage_account.name.primary_web_host
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "loadBalancing"
    health_probe_name   = "healthProbe"
  }

  frontend_endpoint {
    name      = "frontend"
    host_name = "kamilm-nest-afd.azurefd.net"
  }
}