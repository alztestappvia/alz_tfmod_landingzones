resource "azuread_application_federated_identity_credential" "github" {
  count          = var.github_repository == null ? 0 : 1
  application_id = "/applications/${module.service_principal.azuread_application.object_id}"
  display_name   = "github-${var.github_org}-${var.github_repository}-${var.app_environment}"
  description    = "Deployments for ${var.github_org}/${var.github_repository} in ${var.app_environment} environment (${var.platform_environment} Tenant)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${var.github_repository}:environment:${var.app_environment}"
}

resource "github_actions_environment_variable" "client_id" {
  count         = var.github_repository == null ? 0 : 1
  repository    = var.github_repository
  environment   = var.app_environment
  variable_name = "AZURE_CLIENT_ID"
  value         = module.service_principal.azuread_application.client_id
}

resource "github_actions_environment_variable" "tenant_id" {
  count         = var.github_repository == null ? 0 : 1
  repository    = var.github_repository
  environment   = var.app_environment
  variable_name = "AZURE_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_environment_variable" "output_variables" {
  for_each      = var.github_repository == null ? {} : local.output_variable_set
  repository    = var.github_repository
  environment   = var.app_environment
  variable_name = replace(each.key, "-", "_")
  value         = each.value
}
