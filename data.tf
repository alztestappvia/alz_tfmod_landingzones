data "azurerm_client_config" "current" {}

data "azuread_group" "spn_groups" {
  for_each = toset(var.spn_groups)

  display_name     = each.value
  security_enabled = true
}
