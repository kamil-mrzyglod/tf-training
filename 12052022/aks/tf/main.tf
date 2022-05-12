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
  name     = "nestbank-tf-aks-rg"
  location = "West Europe"
}

resource "azurerm_container_registry" "training" {
  name                = "kamilmnestacr"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  sku                 = "Standard"
}

resource "azurerm_virtual_network" "vnet" {
  name = "nest-vnet"
  address_space = [ "10.0.0.0/16" ]
  resource_group_name = azurerm_resource_group.training.name
  location = azurerm_resource_group.training.location
}

resource "azurerm_subnet" "vnet" {
  name = "aks"
  address_prefixes = [ "10.0.1.0/24" ]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.training.name
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "kamilm-nest-aks"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  dns_prefix          = "kamilmnestaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = azurerm_subnet.vnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr = "10.0.4.0/24"
    dns_service_ip = "10.0.4.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }
}

resource "azurerm_role_assignment" "training" {
  principal_id                     = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.training.id
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault" "training" {
  name                = "kamilmtfnestkv"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  tenant_id           = "c2d4fe14-0652-4dac-b415-5a65748fd6c9"
  sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "policy1" {
  key_vault_id            = azurerm_key_vault.training.id
  tenant_id               = "c2d4fe14-0652-4dac-b415-5a65748fd6c9"
  object_id               = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  key_permissions         = ["Get"]
  secret_permissions      = ["Get"]
  certificate_permissions = ["Get"]
}

resource "azurerm_key_vault_access_policy" "policy2" {
  key_vault_id            = azurerm_key_vault.training.id
  tenant_id               = "c2d4fe14-0652-4dac-b415-5a65748fd6c9"
  object_id               = "326fd6c4-7296-4637-9f1d-10876158a6d2"
  secret_permissions      = ["Get", "List", "Set"]
}

resource "azurerm_storage_account" "name" {
  name                     = "kamilaksnest"
  resource_group_name      = azurerm_resource_group.training.name
  location                 = azurerm_resource_group.training.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault_secret" "name" {
  depends_on = [
    azurerm_key_vault_access_policy.policy2
  ]

  name = "storage-account-connection-string"
  key_vault_id = azurerm_key_vault.training.id
  value = azurerm_storage_account.name.primary_connection_string
}

resource "azurerm_user_assigned_identity" "identity" {
  name = "nest-app-mi"
  location = azurerm_resource_group.training.location
  resource_group_name = azurerm_kubernetes_cluster.example.node_resource_group
}

resource "azurerm_key_vault_access_policy" "policy3" {
  key_vault_id            = azurerm_key_vault.training.id
  tenant_id               = "c2d4fe14-0652-4dac-b415-5a65748fd6c9"
  object_id               = resource.azurerm_user_assigned_identity.identity.principal_id
  secret_permissions      = ["Get", "List"]
}

resource "azurerm_role_assignment" "mi-operator" {
  principal_id                     = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  role_definition_name             = "Managed Identity Operator"
  scope                            = "/subscriptions/58ac7037-efcc-4fb6-800d-da6ca2ee6aed/resourceGroups/${azurerm_kubernetes_cluster.example.node_resource_group}"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vm-contributor" {
  principal_id                     = azurerm_kubernetes_cluster.example.kubelet_identity[0].object_id
  role_definition_name             = "Virtual Machine Contributor"
  scope                            = "/subscriptions/58ac7037-efcc-4fb6-800d-da6ca2ee6aed/resourceGroups/${azurerm_kubernetes_cluster.example.node_resource_group}"
  skip_service_principal_aad_check = true
}
