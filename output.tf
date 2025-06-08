# outputs.tf - Output values
output "dev_environment" {
  description = "Development environment details"
  value = {
    resource_group_name = module.dev_environment.resource_group_name
    vnet_id            = module.dev_environment.vnet_id
    subnet_ids         = module.dev_environment.subnet_ids
    key_vault_id       = module.dev_environment.key_vault_id
  }
}

output "prod_environment" {
  description = "Production environment details"
  value = {
    resource_group_name = module.prod_environment.resource_group_name
    vnet_id            = module.prod_environment.vnet_id
    subnet_ids         = module.prod_environment.subnet_ids
    key_vault_id       = module.prod_environment.key_vault_id
  }
}

output "custom_roles" {
  description = "Custom RBAC roles created"
  value = {
    network_operator_id = module.rbac.network_operator_role_id
  }
}