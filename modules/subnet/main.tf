locals {
  resource_group_id = regex("(.*)/providers/.*", var.vnet_id)[0]
}

resource "azurecaf_name" "subnet" {
  name          = var.name
  resource_type = "azurerm_subnet"
  suffixes      = [lower(var.environment)]
  random_length = 4
}

resource "azapi_resource" "nsg" {
  type      = "Microsoft.Network/networkSecurityGroups@2022-07-01"
  name      = "nsg-${azurecaf_name.subnet.result}"
  parent_id = local.resource_group_id
  location  = var.location
  tags      = var.tags
  body = jsonencode({
    properties = {
      securityRules = var.security_rules
    }
  })
}

resource "azapi_resource" "subnet" {
  parent_id = var.vnet_id
  type      = "Microsoft.Network/virtualNetworks/subnets@2022-07-01"
  name      = azurecaf_name.subnet.result
  body = jsonencode({
    name = azurecaf_name.subnet.result
    properties = {
      addressPrefix = var.subnet_cidr
      networkSecurityGroup = {
        id = azapi_resource.nsg.id
      }
      privateEndpointNetworkPolicies = "Enabled"
    }
  })
}
