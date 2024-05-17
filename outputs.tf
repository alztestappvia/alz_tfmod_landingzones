output "subscription_id" {
  value       = module.subscription.subscription_id
  description = "The Azure subscription id."
}

output "subscription_name" {
  value       = local.name
  description = "The Azure subscription name."
}

output "subscription_resource_id" {
  value       = module.subscription.subscription_resource_id
  description = "The Azure subscription resource id."
}

output "virtual_network_resource_ids" {
  value       = module.subscription.virtual_network_resource_ids
  description = "A map of virtual network resource ids, keyed by the var.virtual_networks input map."
}
