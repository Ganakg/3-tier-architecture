# modules/environment/main.tf - Environment module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.environment_name}-${var.location}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment_name}-${var.location}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.address_space
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets
  
  name                 = "${each.value.name}-${var.environment_name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  
  # Delegate subnet for database tier
  dynamic "delegation" {
    for_each = each.value.tier == "database" ? [1] : []
    content {
      name = "delegation"
      service_delegation {
        name = "Microsoft.Sql/managedInstances"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
        ]
      }
    }
  }
}

# Network Security Groups
resource "azurerm_network_security_group" "subnets" {
  for_each = var.subnets
  
  name                = "nsg-${each.value.name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# NSG Rules for Public Subnet
resource "azurerm_network_security_rule" "public_inbound" {
  for_each = { for k, v in var.subnets : k => v if v.tier == "public" }
  
  name                        = "Allow-HTTP-HTTPS"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["80", "443"]
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.subnets[each.key].name
}

# NSG Rules for Private Subnet
resource "azurerm_network_security_rule" "private_inbound" {
  for_each = { for k, v in var.subnets : k => v if v.tier == "private" }
  
  name                        = "Allow-From-Public-Subnet"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefixes    = var.subnets.public.address_prefixes
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.subnets[each.key].name
}

# NSG Rules for Database Subnet
resource "azurerm_network_security_rule" "database_inbound" {
  for_each = { for k, v in var.subnets : k => v if v.tier == "database" }
  
  name                        = "Allow-From-Private-Subnet"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range          = "*"
  destination_port_ranges    = ["1433", "3306", "5432"]
  source_address_prefixes    = var.subnets.private.address_prefixes
  destination_address_prefix = "*"
  resource_group_name        = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.subnets[each.key].name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "subnets" {
  for_each = var.subnets
  
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv-${var.environment_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"
  
  purge_protection_enabled   = var.environment_name == "prod"
  soft_delete_retention_days = var.environment_name == "prod" ? 90 : 7
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    virtual_network_subnet_ids = [
      azurerm_subnet.subnets["private"].id,
      azurerm_subnet.subnets["database"].id
    ]
  }
  
  tags = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_client_config" "current" {}