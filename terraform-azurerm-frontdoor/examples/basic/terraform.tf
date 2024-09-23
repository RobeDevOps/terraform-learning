terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.2.0"
    }
  }
  required_version = "~> 1.9.3"
}

# Configure the AWS Provider
provider "azurerm" {
  features {}
}
