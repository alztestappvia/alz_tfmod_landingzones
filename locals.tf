locals {

  name    = format("%s-%s", var.subscription_name, var.app_environment)
  id_name = format("id-%s", local.name)

  vnet_private_dns_zones = { for k, v in flatten([
    for vnet_key, vnet_properties in var.virtual_networks : [
      for zone_key, zone in var.private_dns_zones : {
        key                 = "${substr(zone.name, 0, 40)}_${local.name}_${vnet_key}"
        private_dns_zone_id = zone.id
        vnet_id             = module.subscription.virtual_network_resource_ids[vnet_key]
      }
    ]
  ]) : v.key => v }

  output_variable_set = merge(
    {
      "subscription-${local.name}" = module.subscription.subscription_id
      (local.id_name)              = module.state_storage.storage_account_name
    },
    { for key, value in var.subscription_ids : "subscription-${key}" => value }
  )
}
