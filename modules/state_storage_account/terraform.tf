terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.19.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.23"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.0.0"
    }
  }
}
