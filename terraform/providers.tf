# ==============================================================================
# Terraform and Provider Configuration - Multi-Subscription
# ==============================================================================
# storage_use_azuread = true ist ERFORDERLICH weil Azure Policy Key-Auth blockiert.
# Der ausführende Benutzer benötigt "Storage Blob Data Contributor" auf den
# Storage Accounts für Terraform Data Plane Checks.
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# ==============================================================================
# Provider Aliases for Multi-Subscription Deployment
# ==============================================================================

# Central subscription - hosts the shared Log Analytics Workspace
provider "azurerm" {
  alias               = "central"
  subscription_id     = var.central_subscription_id
  storage_use_azuread = true
  features {}
}

# User1's subscription - hosts User1's storage account
provider "azurerm" {
  alias               = "user1"
  subscription_id     = var.user1_subscription_id
  storage_use_azuread = true
  features {}
}

# User2's subscription - hosts User2's storage account
provider "azurerm" {
  alias               = "user2"
  subscription_id     = var.user2_subscription_id
  storage_use_azuread = true
  features {}
}

# Default provider (used for data sources)
provider "azurerm" {
  storage_use_azuread = true
  features {}
}

# Azure AD provider for service principal lookups
provider "azuread" {}
