# Azure Advanced configuration

This Terraform configuration deploys a scalable, environment-aware Azure infrastructure for applications with proper networking, security, and storage configuration.

## Architecture

This configuration creates:

- **Resource Groups** in each target region
- **Virtual Networks** with region-specific address spaces
- **Subnets** for web, application, and database tiers
- **Network Security Groups** with environment-specific rules
- **Storage Account** with environment-specific redundancy and security settings

## Key Features

- **Environment-based deployment** (dev/test/prod) with appropriate settings for each
- **Multi-region support** that scales based on environment (1 region for dev, 3 for prod)
- **Consistent naming** and tagging for all resources
- **Network segmentation** with separate subnets for different application tiers
- **Environment-specific security rules** (e.g., SSH only in dev/test)

## Prerequisites

- Terraform v1.0.0+
- Azure CLI installed and authenticated
- Appropriate Azure permissions to create resources

## Usage

1. Clone this repository
2. Initialize Terraform:
   ```
   terraform init
   ```
3. Review the planned changes:
   ```
   terraform plan -var environment=dev
   ```
4. Apply the configuration:
   ```
   terraform apply -var environment=dev
   ```

## Environment Configuration

The infrastructure adapts based on the `environment` variable:

| Environment | Regions | Storage Redundancy | Security Features |
|-------------|---------|-------------------|-------------------|
| dev         | eastus  | LRS               | Basic (TLS 1.0, SSH allowed) |
| test        | eastus, westus2 | LRS      | Moderate (TLS 1.0, SSH allowed) |
| prod        | eastus, westus2, northeurope | GRS | Enhanced (TLS 1.2, SSH blocked) |

## Customization

Key variables for customization:

- `application_name`: Sets the base name for all resources
- `environment`: Changes deployment characteristics (dev/test/prod)
- `locations`: Modify which regions are used for each environment
- `address_spaces`: Adjust the network CIDR blocks
- `subnets`: Modify subnet configurations
- `nsg_rules`: Add or modify security rules

## Example: Production Deployment

```bash
terraform apply -var environment=prod -var application_name=myapp
```

## Outputs

After deployment, Terraform will output:

- Resource group names in each region
- Virtual network address spaces
- Environment-specific settings that were applied

## Notes

- Storage accounts use a random suffix to ensure global uniqueness
- NSG rules are filtered based on the current environment
- The infrastructure is designed for a typical three-tier application architecture
