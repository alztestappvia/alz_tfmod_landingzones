terraform {
  required_version = ">= 1.3.1"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.43.0"
    }
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.33.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 1.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    github = {
      source  = "integrations/github"
      version = ">= 5.25"
    }
  }
}
