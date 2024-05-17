module "service_principal" {
  # tflint-ignore: terraform_module_pinned_source
  source          = "git::https://github.com/alztestappvia/alz_tfmod_appreg?ref=main"
  name            = local.id_name
  tenant_id       = data.azurerm_client_config.current.tenant_id
  directory_roles = var.directory_roles
}

module "subscription" {
  source  = "Azure/lz-vending/azurerm"
  version = "v3.4.1"

  location = var.primary_location

  subscription_alias_enabled = true
  subscription_billing_scope = var.billing_scope
  subscription_display_name  = local.name
  subscription_alias_name    = local.name
  subscription_workload      = "Production"

  network_watcher_resource_group_enabled = true

  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = "${var.root_id}-${var.management_group}"
  subscription_register_resource_providers_enabled  = true
  subscription_tags                                 = var.subscription_tags

  virtual_network_enabled = length(var.virtual_networks) > 0
  virtual_networks = {
    for k, v in var.virtual_networks : k => {
      name                                   = k
      location                               = v.location
      address_space                          = v.address_space[var.app_environment]
      dns_servers                            = v.dns_servers
      resource_group_name                    = "vnet-${k}"
      vwan_associated_routetable_resource_id = var.networking_model == "virtualwan" ? lookup(v.vwan_associated_routetable_resource_id, var.app_environment, "") : null
      vwan_security_configuration = {
        secure_internet_traffic = true
        secure_private_traffic  = true
      }
      vwan_connection_enabled = v.azurerm_virtual_hub_id != null
      vwan_hub_resource_id    = v.azurerm_virtual_hub_id

      hub_peering_enabled             = var.hub_network_resource_id != null
      hub_network_resource_id         = var.hub_network_resource_id
      hub_peering_name_tohub          = var.hub_peering_name_tohub
      hub_peering_name_fromhub        = var.hub_peering_name_fromhub
      hub_peering_use_remote_gateways = var.hub_peering_use_remote_gateways

      resource_group_tags = var.subscription_tags
      tags                = var.subscription_tags
    }
  }

  role_assignment_enabled = true
  role_assignments = merge({
    app_sub_owner = {
      principal_id   = module.service_principal.azuread_service_principal.object_id
      definition     = "Owner"
      relative_scope = ""
    }
  }, var.role_assignments)

  disable_telemetry = true
}

resource "azapi_resource" "state_priv_dns_link" {
  for_each  = local.vnet_private_dns_zones
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01"
  name      = each.key
  parent_id = each.value.private_dns_zone_id
  location  = "global"
  tags      = var.subscription_tags
  body = jsonencode({
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = each.value.vnet_id
      }
    }
  })
}

module "rbac" {
  # tflint-ignore: terraform_module_pinned_source
  source = "git::https://github.com/alztestappvia/alz_tfmod_rbac?ref=main"

  providers = {
    azurerm = azurerm
    azuread = azuread
    azapi   = azapi
    time    = time
  }

  rbac_type     = var.rbac_type
  service_name  = var.subscription_name
  template_name = var.rbac.template_name
  create_groups = var.rbac.create_groups
  scope_map = {
    (var.app_environment) = module.subscription.subscription_resource_id
  }

  # this is required to ensure subscription is asssigned to a management group before the role assignments are created
  depends_on = [
    module.subscription.management_group_subscription_association_id
  ]
}

module "private_endpoint_subnets" {
  for_each = var.virtual_networks
  source   = "./modules/subnet"

  environment = var.app_environment
  name        = "private-endpoints"
  location    = each.value.location
  subnet_cidr = replace(each.value.address_space[var.app_environment][0], "/\\/.*/", "/28")
  vnet_id     = module.subscription.virtual_network_resource_ids[each.key]

  security_rules = [
    {
      name = "deny-all-outbound"
      properties = {
        priority                 = 100
        description              = "Deny all outbound traffic"
        direction                = "Outbound"
        access                   = "Deny"
        protocol                 = "*"
        sourcePortRange          = "*"
        destinationPortRange     = "*"
        sourceAddressPrefix      = "*"
        destinationAddressPrefix = "*"
      }
    },
    {
      name = "allow-https-inbound"
      properties = {
        priority                 = 101
        description              = "Allow inbound HTTPS traffic"
        direction                = "Inbound"
        access                   = "Allow"
        protocol                 = "TCP"
        sourcePortRange          = "*"
        destinationPortRange     = "443"
        sourceAddressPrefix      = "*"
        destinationAddressPrefix = replace(var.virtual_networks[each.key].address_space[var.app_environment][0], "/\\/.*/", "/28")
      }
    }
  ]

  tags = var.subscription_tags
}

resource "azuread_group_member" "spn_groups" {
  for_each = toset(var.spn_groups)

  group_object_id  = data.azuread_group.spn_groups[each.value].id
  member_object_id = module.service_principal.azuread_service_principal.object_id
}
