# Provider Configuration
# This file defines the Terraform providers and their versions required for this configuration

terraform {
  # Define required providers with specific version constraints
  required_providers {
    # Azure Resource Manager provider for all Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Allows any 3.x version but not 4.0+
    }
    # Random provider for generating unique values
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"  # Allows any 3.x version but not 4.0+
    }
  }
}

# Configure the Azure provider with default settings
provider "azurerm" {
  features {}  # Required block even if empty
}

# Configure the random provider with default settings
provider "random" {}