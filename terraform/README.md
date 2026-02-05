# Insecure Terraform Configuration

⚠️ **WARNING: This configuration is deliberately insecure and should ONLY be used for testing purposes.**

## Purpose

This Terraform configuration demonstrates how NOT to configure Azure resources. It consumes the private storage account module with all security features disabled or relaxed.

## Insecure Settings

### Storage Account
- **TLS Version**: TLS 1.0 (oldest and insecure)
- **HTTPS Only**: Disabled - allows unencrypted HTTP traffic
- **Public Network Access**: Enabled - accessible from internet
- **Network Rules**: None - no IP or VNET restrictions
- **Blob Versioning**: Disabled - no version history
- **Soft Delete**: Disabled - no recovery for deleted data
- **Container Access**: Public blob access enabled

### Resource Group
- Basic configuration with no additional security

## Module Source

This configuration consumes the following private module:
- **Storage Account**: `github.com/nathlan/terraform-azurerm-storage-account`

## Usage

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (DO NOT USE IN PRODUCTION)
terraform apply
```

## Variables

Key variables can be overridden:
- `storage_account_name` - Must be globally unique
- `resource_group_name` - Name for the resource group
- `location` - Azure region (default: australiaeast)

## DO NOT USE IN PRODUCTION

This configuration violates security best practices and should never be used in production environments. It is intentionally insecure for testing and demonstration purposes only.
