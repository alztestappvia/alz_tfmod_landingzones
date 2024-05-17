module "state_storage" {
  source = "./modules/state_storage_account"

  name                     = "subtf"
  subscription_resource_id = module.subscription.subscription_resource_id
  location                 = var.primary_location
  principal_id             = module.service_principal.azuread_service_principal.object_id
  environment              = lower(var.app_environment)
  tags                     = var.subscription_tags
  reader_principal_ids = {
    (local.id_name) = module.service_principal.azuread_service_principal.object_id
  }
  use_private_endpoint       = var.state_uses_private_endpoint
  private_endpoint_subnet_id = var.state_uses_private_endpoint == true ? values(module.private_endpoint_subnets)[0].private_endpoint_subnet_id : null

  providers = {
    azurerm = azurerm
  }
}
