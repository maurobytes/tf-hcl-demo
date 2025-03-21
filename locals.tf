# Local Variable Definitions
# This file contains computed values used throughout the configuration
# Locals help with code reusability and readability for complex expressions

locals {
  # Determines which Azure regions to deploy to based on the current environment (dev, test, prod)
  # References the var.locations map with the current environment as the key
  regions = var.locations[var.environment]

  # Defines consistent naming conventions for all resources
  # Creates standardized prefixes for different Azure resource types
  naming = {
    prefix    = "${var.application_name}-${var.environment}"  # General prefix for resources
    rg_prefix = "rg-${var.application_name}-${var.environment}" # Resource group prefix
    vnet      = "vnet-${var.application_name}" # Virtual network naming convention
    nsg       = "nsg-${var.application_name}"  # Network security group naming convention
  }

  # Standard tags applied to all resources for governance and cost tracking
  # These help with resource organization, filtering, and cost allocation
  common_tags = {
    Application = var.application_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  # Determines appropriate storage redundancy based on environment
  # Production uses Geo-Redundant Storage (GRS) for higher availability
  # Non-production uses Locally Redundant Storage (LRS) for cost efficiency
  storage_redundancy = var.environment == "prod" ? "GRS" : "LRS"

  # Creates subnet configurations for all regions and subnet types
  # This complex transformation:
  # 1. Takes each region and each subnet definition
  # 2. Creates a flattened list of all region-subnet combinations
  # 3. Customizes the address range based on the VNET's first octet
  # 4. Converts the flattened list into a map with region-subnet keys
  subnet_configurations = {
    for pair in flatten([
      for region in local.regions : [
        for subnet_key, subnet in var.subnets : {
          key           = "${region}-${subnet_key}"  # Creates unique key for each region-subnet pair
          vnet_key      = region                    # References which region/vnet this subnet belongs to
          name          = subnet.name               # Uses the subnet name from variables
          address_range = replace(subnet.address_range, "0", split(".", var.address_spaces[region])[0]) # Replaces first octet with region-specific value
          delegation    = subnet.delegation         # Optional subnet delegation
        }
      ]
      ]) : pair.key => {
      vnet_key      = pair.vnet_key
      name          = pair.name
      address_range = pair.address_range
      delegation    = pair.delegation
    }
  }

  # Filters NSG rules based on the current environment
  # Only rules that include the current environment in their 'environments' list will be applied
  # This allows for environment-specific security rules (e.g., no SSH in production)
  environment_nsg_rules = [
    for rule in var.nsg_rules : rule
    if contains(rule.environments, var.environment)
  ]
}
