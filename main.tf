# Azure Infrastructure Deployment
# This file contains the main resources for the application infrastructure
# It deploys resource groups, networking components, security groups, and storage

# Create resource groups in each target region
resource "azurerm_resource_group" "rg" {
  count    = length(local.regions)
  name     = "${local.naming.rg_prefix}-${local.regions[count.index]}"
  location = local.regions[count.index]
  tags     = local.common_tags
}

# Generate a random suffix for globally unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create virtual networks in each target region
resource "azurerm_virtual_network" "vnet" {
  for_each            = toset(local.regions)
  name                = "${local.naming.vnet}-${each.key}"
  location            = each.key
  resource_group_name = azurerm_resource_group.rg[index(local.regions, each.key)].name
  address_space       = [var.address_spaces[each.key]]
  tags                = local.common_tags
}

# Create subnets within each virtual network based on the subnet configuration
resource "azurerm_subnet" "subnet" {
  for_each             = local.subnet_configurations
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg[index(local.regions, each.value.vnet_key)].name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = [each.value.address_range]
}

# Create network security groups with environment-specific rules
resource "azurerm_network_security_group" "nsg" {
  for_each            = toset(local.regions)
  name                = "${local.naming.nsg}-${each.key}"
  location            = each.key
  resource_group_name = azurerm_resource_group.rg[index(local.regions, each.key)].name
  tags                = local.common_tags

  # Dynamic block for security rules - applies environment-specific NSG rules
  dynamic "security_rule" {
    for_each = local.environment_nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

# Create a storage account with environment-specific settings
resource "azurerm_storage_account" "storage" {
  name                     = "st${var.application_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg[0].name
  location                 = azurerm_resource_group.rg[0].location
  account_tier             = "Standard"
  account_replication_type = local.storage_redundancy  # LRS for non-prod, GRS for prod

  # Security settings conditional on environment
  min_tls_version = var.environment == "prod" ? "TLS1_2" : "TLS1_0"  # Stronger TLS for prod

  tags = local.common_tags

  # Prevent Terraform from modifying these tags after creation
  lifecycle {
    ignore_changes = [
      tags["LastModified"]
    ]
  }
}