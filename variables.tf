# variables.tf - Input variables
variable "dev_subscription_id" {
  description = "Development subscription ID"
  type        = string
}

variable "prod_subscription_id" {
  description = "Production subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    address_space = list(string)
    vm_size      = string
    backup_enabled = bool
  }))
  default = {
    dev = {
      address_space  = ["10.1.0.0/16"]
      vm_size       = "Standard_B2s"
      backup_enabled = false
    }
    prod = {
      address_space  = ["10.2.0.0/16"]
      vm_size       = "Standard_D4s_v4"
      backup_enabled = true
    }
  }
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed for management access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}