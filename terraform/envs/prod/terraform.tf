terraform {
  required_version = ">= 1.9.0"

  # Partial azurerm backend: the account, resource group, and container come
  # from terraform/backend.hcl; this root supplies its own state key at init
  # time (key=prod.tfstate). See terraform/README.md, "Initialising a root".
  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

# The subscription is an explicit input via var.subscription_id (no default),
# never hardcoded: this repository is public and Terraform must be
# subscription-portable. Setting it here rather than relying on the provider's
# fallback means a missing value fails loudly instead of silently targeting the
# Azure CLI's active subscription.
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
