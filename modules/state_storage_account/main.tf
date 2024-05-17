resource "azurecaf_name" "rg" {
  name          = "${var.name}-state"
  resource_type = "azurerm_resource_group"
  suffixes      = [lower(var.environment)]
  random_length = 4
}

resource "azapi_resource" "rg" {
  parent_id = var.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = azurecaf_name.rg.result
  location  = var.location
  tags      = var.tags
}

resource "azurecaf_name" "storage" {
  name          = "${var.name}state"
  resource_type = "azurerm_storage_account"
  suffixes      = [lower(var.environment)]
  random_length = 4
}

resource "azapi_resource" "storage" {
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Storage/storageAccounts@2022-09-01"
  name      = azurecaf_name.storage.result
  location  = var.location
  tags      = var.tags
  body = jsonencode({
    kind = "StorageV2"
    sku = {
      name = "Standard_GRS"
    }
    properties = {
      allowBlobPublicAccess    = false
      minimumTlsVersion        = "TLS1_2"
      supportsHttpsTrafficOnly = true
      publicNetworkAccess      = var.private_endpoint_subnet_id == null ? "Enabled" : "Disabled"
      networkAcls = {
        defaultAction = var.private_endpoint_subnet_id == null ? "Allow" : "Deny"
      }
    }
  })
}

resource "azapi_resource" "state_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01"
  name      = var.container_name
  parent_id = "${azapi_resource.storage.id}/blobServices/default"
  body = jsonencode({
    properties = {
      publicAccess = "None"
    }
  })
}

resource "azurerm_role_assignment" "state" {
  scope                = azapi_resource.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.principal_id
}

resource "azurerm_role_assignment" "state_readers" {
  for_each             = var.reader_principal_ids
  scope                = azapi_resource.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = each.value
}

resource "azapi_resource" "state_private_endpoint" {
  count = var.use_private_endpoint == true ? 1 : 0

  type      = "Microsoft.Network/privateEndpoints@2021-05-01"
  name      = "pend-${azurecaf_name.storage.result}"
  parent_id = azapi_resource.rg.id
  location  = var.location
  tags      = var.tags
  body = jsonencode({
    properties = {
      privateLinkServiceConnections = [
        {
          name = azurecaf_name.storage.result
          properties = {
            privateLinkServiceId = azapi_resource.storage.id
            groupIds             = ["blob"]
          }
        }
      ]
      subnet = {
        id = var.private_endpoint_subnet_id
      }
    }
  })
}
