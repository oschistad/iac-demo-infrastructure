terraform {
  required_providers {
    azurerm = {
      version = "=2.40.0"
    }
    tfe = {
      version = "~> 0.24.0"
    }
  }
}

provider "azurerm" {
  # We recommend pinning to the specific version of the Azure Provider you're using
  # since new versions are released frequently

  features {}

  # More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs

  subscription_id = var.subscription_id
  client_id = var.client_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
}