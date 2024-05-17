variable "app_environment" {
  type        = string
  description = "The subscription environment to deploy"
  default     = "dev"

  validation {
    condition = contains(
      ["dev", "pre", "prd", "sandbox"],
      var.app_environment
    )
    error_message = "Error: app_environment must be one of: dev, pre, prd, sandbox."
  }
}

variable "billing_scope" {
  type        = string
  description = "The billing scope for the subscription"
  default     = "/providers/Microsoft.Billing/billingAccounts/xxxx/billingProfiles/xxxx/invoiceSections/xxxx"
}

variable "hub_network_resource_id" {
  type        = string
  description = "The Virtual Network Hub Resource ID to associate the virtual networks with"
  default     = null
}

variable "hub_peering_name_tohub" {
  type        = string
  description = "The name of the peering from the spoke to the hub"
  default     = null
}

variable "hub_peering_name_fromhub" {
  type        = string
  description = "The name of the peering from the hub to the spoke"
  default     = null
}

variable "hub_peering_use_remote_gateways" {
  type        = bool
  description = "Whether to use remote gateways for the peering"
  default     = true
}

variable "github_org" {
  type        = string
  description = "The GitHub organization"
  default     = null
}

variable "github_repository" {
  type        = string
  description = "The GitHub repository to add deployment variables to"
  default     = null
}

variable "devops_project_name" {
  type        = string
  description = "Sets the name of the Azure DevOps project to create the service connection in"
  default     = null
}

variable "directory_roles" {
  type        = set(string)
  description = "Set of AzureAD directory role names to be assigned to the service principal."
  default     = []
}

variable "management_group" {
  type        = string
  description = "Sets the name of the management group to associate the subscription with"

  validation {
    condition = contains(
      ["internal", "external", "sandboxes"],
      var.management_group
    )
    error_message = "Error: management_group must be one of: internal, external, sandboxes."
  }
}


variable "networking_model" {
  type        = string
  description = "Sets the networking model to use for the deployment"
  default     = "virtualwan"
  validation {
    condition     = can(regex("^(virtualwan|basic)$", var.networking_model))
    error_message = "networking_model must be either \"virtualwan\" or \"basic\""
  }
}

variable "platform_environment" {
  type        = string
  description = "The platform environment (tenant)"
  default     = "Test"

  validation {
    condition = contains(
      ["Test", "Prod"],
      var.platform_environment
    )
    error_message = "Error: platform_environment must be one of: Test, Prod."
  }
}

variable "primary_location" {
  type        = string
  description = "The primary location for the subscription"
  default     = "uksouth"

  validation {
    condition = contains(
      ["ukwest", "uksouth"],
      var.primary_location
    )
    error_message = "Error: primary_location must be one of: ukwest, uksouth."
  }
}

variable "private_dns_zones" {
  type = map(object({
    id   = string
    name = string
  }))
  description = "Sets the private DNS zones to be linked to vnets"
  default     = {}
}

variable "rbac" {
  type = object({
    template_name = optional(string, "standard")
    create_groups = optional(bool, true)
  })
  description = "A map of objects containing the details of the role assignments to create. Required when creating service RBAC."
  default = {
    template_name = "standard"
    create_groups = true
  }
}

variable "rbac_type" {
  type        = string
  description = "The type of RBAC to apply."
  default     = "service"

  validation {
    condition = contains(
      ["service", "sandbox"],
      var.rbac_type
    )
    error_message = "Error: rbac_type must be one of: service, sandbox."
  }
}

variable "role_assignments" {
  type = map(object({
    principal_id   = string,
    definition     = string,
    relative_scope = string,
  }))
  description = "Supply a map of objects containing the details of the role assignments to create"
  default     = {}
}

variable "root_id" {
  description = "The Tenant Root ID where resources are to be provisioned under"
  type        = string
  default     = "alz"
}

variable "spn_groups" {
  type        = list(string)
  default     = []
  description = "AzureAD groups to add the service principal to"
}

variable "subscription_name" {
  type        = string
  description = "Sets the name of the subscription, which will have the environment automatically appended to it"

  validation {
    condition     = can(regex("^[a-z]+[a-z-]+[^_-]$", var.subscription_name))
    error_message = "Error: The subscription_name can only contain lowercase letters, hyphens, and must start and end with a letter."
  }

  validation {
    error_message = "Error: subscription_name must not be more than 24 characters in length."
    condition     = length(var.subscription_name) <= 24
  }
}

variable "subscription_ids" {
  type        = map(string)
  description = "Sets additional Subscription IDs to be available in the ADO Variable Group"
  default     = {}
}

variable "subscription_tags" {
  type        = map(string)
  description = "Sets tags to be applied to the subscription"
}

variable "virtual_networks" {
  type = map(object({
    location                               = optional(string, "uksouth")
    azurerm_virtual_hub_id                 = optional(string, null)
    address_space                          = map(list(string))
    vwan_associated_routetable_resource_id = optional(map(string), {})
    dns_servers                            = optional(list(string), [])
  }))
  description = "Sets the virtual networks to be created in the subscription"
  default     = {}
  validation {
    error_message = "Error: virtual network keys must not be more than 10 characters in length."
    condition = alltrue(
      [for k, v in var.virtual_networks : length(k) <= 10]
    )
  }
}

variable "state_uses_private_endpoint" {
  type        = bool
  description = "Sets whether the state storage account uses a private endpoint"
  default     = true
}
