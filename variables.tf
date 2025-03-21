# Variable Definitions
# This file defines all input parameters that can be configured when deploying the infrastructure

# Primary application identifier used in resource naming
variable "application_name" {
  description = "the name of the application"
  type        = string
  default     = "demoapp"
}

# Deployment environment (dev/test/prod) - controls environment-specific settings
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  # Ensures only valid environments can be specified
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod"
  }
}

# Defines which Azure regions to deploy to based on environment
# More regions are used in higher environments for redundancy
variable "locations" {
  description = "Azure regions to deploy to based on environment"
  type        = map(list(string))
  default = {
    "dev"  = ["eastus"]
    "test" = ["eastus", "westus2"]
    "prod" = ["eastus", "westus2", "northeurope"]
  }
}

# IP addressing scheme for virtual networks in each region
# Each region gets its own address space to prevent overlaps
variable "address_spaces" {
  description = "Address spaces for each virtual network"
  type        = map(string)
  default = {
    eastus      = "10.1.0.0/16"
    westus2     = "10.2.0.0/16"
    northeurope = "10.3.0.0/16"
  }
}

# Subnet definitions to be created in each virtual network
# The "0" prefix in address_range is replaced with the first octet from the VNET address space
variable "subnets" {
  description = "Subnet configurations for virtual networks"
  type = map(object({
    name          = string
    address_range = string
    delegation    = optional(string, null)
  }))

  default = {
    web = {
      name          = "web-subnet"
      address_range = "0.0.0/24"  # Becomes 10.x.0.0/24 based on region
    }
    app = {
      name          = "app-subnet"
      address_range = "0.1.0/24"  # Becomes 10.x.1.0/24 based on region
    }
    db = {
      name          = "db-subnet"
      address_range = "0.2.0/24"  # Becomes 10.x.2.0/24 based on region
    }
  }
}

# Network security rules with environment-specific applicability
# Each rule includes which environments it should be applied to
variable "nsg_rules" {
  description = "Security rules configuration"
  type = list(object({
    name                   = string
    priority               = number
    direction              = string
    access                 = string
    protocol               = string
    destination_port_range = string
    environments           = list(string) # Which environments this rule applies to
  }))

  default = [
    {
      name                   = "allow-http"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "80"
      environments           = ["dev", "test", "prod"]
    },
    {
      name                   = "allow-https"
      priority               = 110
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
      environments           = ["dev", "test", "prod"]
    },
    {
      name                   = "allow-ssh"
      priority               = 120
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "22"
      environments           = ["dev", "test"] # SSH not allowed in production for security
    }
  ]
}