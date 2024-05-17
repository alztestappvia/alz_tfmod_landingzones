locals {
  ukwest_virtual_hub_id     = data.terraform_remote_state.core.outputs.azurerm_virtual_hub_ids["ukwest"]
  uksouth_virtual_hub_id = data.terraform_remote_state.core.outputs.azurerm_virtual_hub_ids["uksouth"]
  subscription_ids = {
    identity     = data.terraform_remote_state.core.outputs.subscription_identity
    connectivity = data.terraform_remote_state.core.outputs.subscription_connectivity
    management   = data.terraform_remote_state.core.outputs.subscription_management
  }
}

module "service-name" {
  source = "../"

  platform_environment = var.platform_environment # Passed via pipeline variable
  app_environment      = var.app_environment      # Passed via pipeline variable
  subscription_ids     = local.subscription_ids   # Read from core remote state, used to create the Variable Group

  # Multiple virtual networks can be defined here and built in the `dev`, `pre` and `prd` Landing Zones
  virtual_networks = {
    main = {                                                # This is the name of the virtual network (can be called anything)
      azurerm_virtual_hub_id = local.uksouth_virtual_hub_id # Read from core remote state
      address_space = {
        dev = ["10.30.1.0/24"] # The address space(s) for the `main` virtual network in the `dev` Landing Zone (Prod Tenant)
        pre = ["10.30.2.0/24"] # The address space(s) for the `main` virtual network in the `pre` Landing Zone (Prod Tenant)
        prd = ["10.30.3.0/24"] # The address space(s) for the `main` virtual network in the `prd` Landing Zone (Prod Tenant)
      }
    }
  }

  private_dns_zones = data.terraform_remote_state.core.outputs.azurerm_private_dns_zone # Read from core remote state, used to create the Private DNS Links

  state_uses_private_endpoint = var.bootstrap_mode != "true" # When initially deploying the stack, private endpoints are not available. This is controlled via a pipeline variable.

  directory_roles = [ # Directory Roles can optionally be assigned the Service Principal created for the Landing Zone, when it is required.
    "Application Administrator"
  ]

  rbac = {
    template_name = "standard"
    create_groups = true # Create custom ALZ RBAC groups for the Landing Zone
  }

  devops_project_name = "##DEVOPS_PROJECT_NAME##" # The name of the Azure DevOps project where the Service Connection and Variable Group will be created
  management_group    = "internal"                # The name of the Management Group where the Subscription will be created (either "internal" or "external")
  subscription_name   = "service-name"            # A unique name (across the Tenant) for the Subscription to be created
  subscription_tags = {
    WorkloadName        = "ALZ.Core"
    DataClassification  = "General"
    BusinessCriticality = "Mission-critical"
    BusinessUnit        = "Platform Operations"
    OperationsTeam      = "Platform Operations"
  }
}
