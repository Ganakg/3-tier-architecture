# modules/rbac/main.tf - RBAC module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Custom RBAC Role for Network Operations
resource "azurerm_role_definition" "network_operator" {
  name        = "Network Operator"
  scope       = "/subscriptions/${var.dev_subscription_id}"
  description = "Custom role for network operations"
  
  permissions {
    actions = [
      "Microsoft.Network/*/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/routeTables/write",
      "Microsoft.Network/virtualNetworks/subnets/write"
    ]
    not_actions = [
      "Microsoft.Network/virtualNetworks/delete"
    ]
  }
  
  assignable_scopes = [
    "/subscriptions/${var.dev_subscription_id}",
    "/subscriptions/${var.prod_subscription_id}"
  ]
}

# Role Assignments for Development Subscription
resource "azurerm_role_assignment" "dev_assignments" {
  for_each = var.role_assignments
  
  scope                = "/subscriptions/${var.dev_subscription_id}"
  role_definition_name = each.value.dev_role
  principal_id         = each.value.group_object_id
}

# Role Assignments for Production Subscription
resource "azurerm_role_assignment" "prod_assignments" {
  for_each = var.role_assignments
  
  scope                = "/subscriptions/${var.prod_subscription_id}"
  role_definition_name = each.value.prod_role
  principal_id         = each.value.group_object_id
}

# Additional Security Reader assignment for Key Vaults
data "azurerm_resources" "key_vaults" {
  type = "Microsoft.KeyVault/vaults"
}

resource "azurerm_role_assignment" "keyvault_security" {
  for_each = toset(data.azurerm_resources.key_vaults.resources[*].id)
  
  scope                = each.value
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.role_assignments.security_team.group_object_id
}