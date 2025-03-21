# Output Definitions
# This file defines values that will be displayed after terraform apply completes
# These outputs are useful for reference or for use in other configurations

# List of all resource group names created by this configuration
output "resource_group_names" {
  description = "Names of created resource groups"
  value       = [for rg in azurerm_resource_group.rg : rg.name]
}

# Map of virtual network address spaces by region
# Provides a summary of network addressing scheme
output "vnet_addresses" {
  description = "Address spaces for virtual networks"
  value = {
    for key, vnet in azurerm_virtual_network.vnet : key => vnet.address_space
  }
}

# Detailed output of environment-specific settings that were applied
# Useful for verifying the correct configuration was used
output "environment_specific_settings" {
  description = "Environment-specific configuration"
  value = {
    environment = var.environment
    regions     = local.regions
    storage = {
      replication_type = local.storage_redundancy
      https_only       = var.environment != "dev"
      tls_version      = var.environment == "prod" ? "TLS1_2" : "TLS1_0"
    }
    applied_nsg_rules = [
      for rule in local.environment_nsg_rules : rule.name
    ]
  }
}