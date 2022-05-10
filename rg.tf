terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "kamilm-nestbank-backend-tf-rg"
    storage_account_name = "tfbackendkamilm"
    container_name       = "tfstate"
    key                  = "training.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "training" {
  name     = "kamilm-nestbank-2-tf-rg"
  location = "westeurope"
}