# main.tf - Root module for Azure Landing Zone
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# Data sources for existing resources
data "azurerm_client_config" "current" {}

data "azuread_group" "devops_team" {
  display_name = "DevOpsTeam"
}

data "azuread_group" "security_team" {
  display_name = "SecurityTeam"
}

# Development Environment
module "dev_environment" {
  source = "./modules/environment"
  
  environment_name     = "dev"
  subscription_id      = var.dev_subscription_id
  location            = var.location
  address_space       = ["10.1.0.0/16"]
  
  subnets = {
    public = {
      name             = "public-subnet"
      address_prefixes = ["10.1.1.0/24"]
      tier            = "public"
    }
    private = {
      name             = "private-subnet"
      address_prefixes = ["10.1.2.0/24"]
      tier            = "private"
    }
    database = {
      name             = "database-subnet"
      address_prefixes = ["10.1.3.0/24"]
      tier            = "database"
    }
  }
  
  tags = local.common_tags
}

# Production Environment
module "prod_environment" {
  source = "./modules/environment"
  
  environment_name     = "prod"
  subscription_id      = var.prod_subscription_id
  location            = var.location
  address_space       = ["10.2.0.0/16"]
  
  subnets = {
    public = {
      name             = "public-subnet"
      address_prefixes = ["10.2.1.0/24"]
      tier            = "public"
    }
    private = {
      name             = "private-subnet"
      address_prefixes = ["10.2.2.0/24"]
      tier            = "private"
    }
    database = {
      name             = "database-subnet"
      address_prefixes = ["10.2.3.0/24"]
      tier            = "database"
    }
  }
  
  tags = local.common_tags
}

# RBAC Assignments
module "rbac" {
  source = "./modules/rbac"
  
  dev_subscription_id  = var.dev_subscription_id
  prod_subscription_id = var.prod_subscription_id
  
  role_assignments = {
    devops_team = {
      group_object_id = data.azuread_group.devops_team.object_id
      dev_role       = "Contributor"
      prod_role      = "Reader"
    }
    security_team = {
      group_object_id = data.azuread_group.security_team.object_id
      dev_role       = "Security Reader"
      prod_role      = "Security Reader"
    }
  }
}

locals {
  common_tags = {
    Project     = "Azure-Landing-Zone"
    ManagedBy   = "Terraform"
    Environment = "Multi"
  }
}