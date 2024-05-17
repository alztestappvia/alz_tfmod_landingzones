<!-- BEGIN_TF_DOCS -->
# Terraform.LandingZones

This Terraform Module deploys an Application Landing Zone and creates an AAD Application, Service Principal and Connection to a given Azure DevOps Project or GitHub repository for Owner access to the Subscription.

## Updating Docs

The `terraform-docs` utility is used to generate this README. Follow the below steps to update:
1. Make changes to the `.terraform-docs.yml` file
2. Fetch the `terraform-docs` binary (https://terraform-docs.io/user-guide/installation/)
3. Run `terraform-docs markdown table --output-file ${PWD}/README.md --output-mode inject .`

## Example Module Use

To create a new Subscription, view the example below.

```hcl
locals {
  ukwest_virtual_hub_id = data.terraform_remote_state.core.outputs.azurerm_virtual_hub_ids["ukwest"]
  uksouth_virtual_hub_id  = data.terraform_remote_state.core.outputs.azurerm_virtual_hub_ids["uksouth"]
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
    main = {  # This is the name of the virtual network (can be called anything)
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
  management_group    = "internal"                             # The name of the Management Group where the Subscription will be created (either "internal" or "external")
  subscription_name   = "service-name"                         # A unique name (across the Tenant) for the Subscription to be created
  subscription_tags = {
    WorkloadName        = "ALZ.Core"
    DataClassification  = "General"
    BusinessCriticality = "Mission-critical"
    BusinessUnit        = "Platform Operations"
    OperationsTeam      = "Platform Operations"
  }
}
```

## Important Notes

### Private Endpoint Subnet

In order to support Private Endpoints, a `/28` Subnet must be created within all Virtual Networks. As this Module supports a list of CIDRs for a vnet, the first CIDR in the list is taken and a `/28` block of it is used to create a single Subnet. For example:
```hcl
virtual_networks = {
  vnet1 = {
    address_space = {
      dev = ["10.30.1.0/24"]
    }
  }
  vnet2 = {
    address_space = {
      dev = ["10.30.2.128/25"]
    }
  }
  vnet3 = {
    address_space = {
      dev = ["10.30.3.0/28", "10.30.4.0/24"]
    }
  }
}
```

**vnet1:**
- The Virtual Network CIDR is `10.30.1.0/24`
- A subnet will be created from this as `10.30.1.0/28`
- The remaining addresses that can be allocated to new subnets range from `10.30.1.16 - 10.30.1.255`

**vnet2:**
- The Virtual Network CIDR is `10.30.2.128/25`
- A subnet will be created from this as `10.30.2.128/28`
- The remaining addresses that can be allocated to new subnets range from `10.30.2.144 - 10.30.2.255`

**vnet3:**
- The Virtual Network has two CIDRs allocated, `10.30.3.0/28` and `10.30.4.0/24`
- A subnet will be created from this as `10.30.3.0/28`
- The remaining addresses that can be allocated to new subnets range from `10.30.4.0 - 10.30.4.255`

This means that the first CIDR range in the list must be at least a `/28` in size, otherwise the subnet will fail to provision and Terraform will error.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_environment"></a> [app\_environment](#input\_app\_environment) | The subscription environment to deploy | `string` | `"dev"` | no |
| <a name="input_billing_scope"></a> [billing\_scope](#input\_billing\_scope) | The billing scope for the subscription | `string` | `"/providers/Microsoft.Billing/billingAccounts/xxxx/billingProfiles/xxxx/invoiceSections/xxxx"` | no |
| <a name="input_devops_project_name"></a> [devops\_project\_name](#input\_devops\_project\_name) | Sets the name of the Azure DevOps project to create the service connection in | `string` | n/a | yes |
| <a name="input_directory_roles"></a> [directory\_roles](#input\_directory\_roles) | Set of AzureAD directory role names to be assigned to the service principal. | `set(string)` | `[]` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | The GitHub organization | `string` | `null` | no |
| <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository) | The GitHub repository to add deployment variables to | `string` | `null` | no |
| <a name="input_hub_network_resource_id"></a> [hub\_network\_resource\_id](#input\_hub\_network\_resource\_id) | The Virtual Network Hub Resource ID to associate the virtual networks with | `string` | `null` | no |
| <a name="input_hub_peering_name_fromhub"></a> [hub\_peering\_name\_fromhub](#input\_hub\_peering\_name\_fromhub) | The name of the peering from the hub to the spoke | `string` | `null` | no |
| <a name="input_hub_peering_name_tohub"></a> [hub\_peering\_name\_tohub](#input\_hub\_peering\_name\_tohub) | The name of the peering from the spoke to the hub | `string` | `null` | no |
| <a name="input_hub_peering_use_remote_gateways"></a> [hub\_peering\_use\_remote\_gateways](#input\_hub\_peering\_use\_remote\_gateways) | Whether to use remote gateways for the peering | `bool` | `true` | no |
| <a name="input_management_group"></a> [management\_group](#input\_management\_group) | Sets the name of the management group to associate the subscription with | `string` | n/a | yes |
| <a name="input_networking_model"></a> [networking\_model](#input\_networking\_model) | Sets the networking model to use for the deployment | `string` | `"virtualwan"` | no |
| <a name="input_platform_environment"></a> [platform\_environment](#input\_platform\_environment) | The platform environment (tenant) | `string` | `"Test"` | no |
| <a name="input_primary_location"></a> [primary\_location](#input\_primary\_location) | The primary location for the subscription | `string` | `"uksouth"` | no |
| <a name="input_private_dns_zones"></a> [private\_dns\_zones](#input\_private\_dns\_zones) | Sets the private DNS zones to be linked to vnets | <pre>map(object({<br>    id   = string<br>    name = string<br>  }))</pre> | `{}` | no |
| <a name="input_rbac"></a> [rbac](#input\_rbac) | A map of objects containing the details of the role assignments to create. Required when creating service RBAC. | <pre>object({<br>    template_name = optional(string, "standard")<br>    create_groups = optional(bool, true)<br>  })</pre> | <pre>{<br>  "create_groups": true,<br>  "template_name": "standard"<br>}</pre> | no |
| <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments) | Supply a map of objects containing the details of the role assignments to create | <pre>map(object({<br>    principal_id   = string,<br>    definition     = string,<br>    relative_scope = string,<br>  }))</pre> | `{}` | no |
| <a name="input_root_id"></a> [root\_id](#input\_root\_id) | The Tenant Root ID where resources are to be provisioned under | `string` | `"alz"` | no |
| <a name="input_spn_groups"></a> [spn\_groups](#input\_spn\_groups) | AzureAD groups to add the service principal to | `list(string)` | `[]` | no |
| <a name="input_state_uses_private_endpoint"></a> [state\_uses\_private\_endpoint](#input\_state\_uses\_private\_endpoint) | Sets whether the state storage account uses a private endpoint | `bool` | `true` | no |
| <a name="input_subscription_ids"></a> [subscription\_ids](#input\_subscription\_ids) | Sets additional Subscription IDs to be available in the ADO Variable Group | `map(string)` | `{}` | no |
| <a name="input_subscription_name"></a> [subscription\_name](#input\_subscription\_name) | Sets the name of the subscription, which will have the environment automatically appended to it | `string` | n/a | yes |
| <a name="input_subscription_tags"></a> [subscription\_tags](#input\_subscription\_tags) | Sets tags to be applied to the subscription | `map(string)` | n/a | yes |
| <a name="input_virtual_networks"></a> [virtual\_networks](#input\_virtual\_networks) | Sets the virtual networks to be created in the subscription | <pre>map(object({<br>    location                               = optional(string, "uksouth")<br>    azurerm_virtual_hub_id                 = optional(string, null)<br>    address_space                          = map(list(string))<br>    vwan_associated_routetable_resource_id = optional(map(string), {})<br>    dns_servers                            = optional(list(string), [])<br>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | The Azure subscription id. |
| <a name="output_subscription_name"></a> [subscription\_name](#output\_subscription\_name) | The Azure subscription name. |
| <a name="output_subscription_resource_id"></a> [subscription\_resource\_id](#output\_subscription\_resource\_id) | The Azure subscription resource id. |
| <a name="output_virtual_network_resource_ids"></a> [virtual\_network\_resource\_ids](#output\_virtual\_network\_resource\_ids) | A map of virtual network resource ids, keyed by the var.virtual\_networks input map. |
<!-- END_TF_DOCS -->