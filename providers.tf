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
  features {}
}