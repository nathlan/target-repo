---
applyTo: "terraform/**/*"
---

# Shared Standards for Cloud Infrastructure

This document contains organization-wide standards and best practices that must be followed when working with cloud infrastructure code. These standards apply across all cloud providers and projects.

## Repository Context

- All Terraform infrastructure code is located in the `terraform/` directory
- These standards apply to all Terraform configurations in this repository

## Core Security Principles

### 1. Private Networking (Network Isolation)

**Rule**: All deployments must use private networking if supported by the cloud provider.

**Requirements**:
- Resources should not be directly accessible from the public internet unless explicitly required
- Use private endpoints, private links, or VPC/VNet peering for inter-service communication
- Public access should be disabled by default
- When public access is necessary, implement proper access controls (IP restrictions, authentication, etc.)

**Examples**:

<details>
<summary>Azure - Storage Account with Private Endpoint</summary>

```hcl
# Terraform - Azure Storage Account with Private Endpoint
resource "azurerm_storage_account" "example" {
  name                     = "examplestorageacct"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Disable public network access
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "example" {
  name                = "storage-private-endpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = azurerm_subnet.example.id

  private_service_connection {
    name                           = "storage-privateconnection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}
```

</details>

<details>
<summary>AWS - RDS with Private Subnet</summary>

```hcl
# Terraform - AWS RDS in Private Subnet
resource "aws_db_subnet_group" "example" {
  name       = "example-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "Example DB subnet group"
  }
}

resource "aws_db_instance" "example" {
  identifier             = "example-db"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  
  # Ensure database is not publicly accessible
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.example.name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  username = var.db_username
  password = var.db_password
}
```

</details>

### 2. Encryption at Rest and in Transit

**Rule**: All data must be encrypted both at rest and in transit.

**Requirements**:
- Enable encryption at rest for all storage resources (databases, object storage, disks, etc.)
- Use TLS/SSL for all network communication
- Use strong encryption algorithms (AES-256 for at rest, TLS 1.2+ for in transit)
- Manage encryption keys securely (use cloud provider key management services)
- Never store unencrypted sensitive data

**Examples**:

<details>
<summary>Azure - Key Vault and Encrypted Disk</summary>

```hcl
# Terraform - Azure Managed Disk with Encryption
resource "azurerm_key_vault" "example" {
  name                       = "examplekeyvault"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  
  # Private networking
  public_network_access_enabled = false
}

resource "azurerm_disk_encryption_set" "example" {
  name                = "example-disk-encryption-set"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  key_vault_key_id    = azurerm_key_vault_key.example.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_managed_disk" "example" {
  name                 = "example-disk"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128
  
  # Enable encryption at rest using disk encryption set
  disk_encryption_set_id = azurerm_disk_encryption_set.example.id
}
```

</details>

<details>
<summary>AWS - S3 with Encryption and TLS</summary>

```hcl
# Terraform - AWS S3 Bucket with Encryption
resource "aws_kms_key" "example" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "example" {
  bucket = "example-encrypted-bucket"
}

# Enable encryption at rest using KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.example.arn
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce TLS for all connections
resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.example.arn,
          "${aws_s3_bucket.example.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

</details>

<details>
<summary>Azure - PostgreSQL with TLS Enforcement</summary>

```hcl
# Terraform - Azure PostgreSQL with TLS
resource "azurerm_postgresql_flexible_server" "example" {
  name                   = "example-postgresql-server"
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  
  sku_name   = "GP_Standard_D2s_v3"
  storage_mb = 32768
  version    = "15"
  
  # Private networking
  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.example.id
  
  # Disable public access
  public_network_access_enabled = false
}

# Enforce TLS/SSL
resource "azurerm_postgresql_flexible_server_configuration" "ssl" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.example.id
  value     = "on"
}

# Set minimum TLS version
resource "azurerm_postgresql_flexible_server_configuration" "tls_version" {
  name      = "ssl_min_protocol_version"
  server_id = azurerm_postgresql_flexible_server.example.id
  value     = "TLSv1.2"
}

# Note: Azure PostgreSQL Flexible Server uses platform-managed encryption by default.
# Customer-managed keys require additional Key Vault and managed identity setup.
```

</details>

<details>
<summary>AWS - Application Load Balancer with TLS</summary>

```hcl
# Terraform - AWS ALB with HTTPS Listener
resource "aws_lb" "example" {
  name               = "example-alb"
  internal           = true  # Private networking
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Enable deletion protection for production
  enable_deletion_protection = true
}

# HTTPS Listener with TLS 1.2 minimum
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.example.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

</details>

## Implementation Guidelines

When reviewing or generating code, ensure:

1. **Default to Secure**: Security features should be enabled by default, not as an afterthought
2. **Fail Securely**: If encryption or private networking cannot be enabled, the deployment should fail rather than proceed insecurely
3. **Document Exceptions**: Any exceptions to these rules must be explicitly documented with business justification
4. **Use Native Features**: Prefer cloud provider native encryption and networking features over third-party solutions
5. **Regular Reviews**: Security configurations should be reviewed regularly and updated to meet current best practices

## Additional Considerations

- **Compliance**: These standards help meet common compliance requirements (HIPAA, PCI-DSS, SOC 2, etc.)
- **Performance**: Private networking and encryption may have minimal performance impact but significantly improve security posture
- **Cost**: Some security features (like KMS, private endpoints) have associated costs that should be factored into project budgets
- **Monitoring**: Enable logging and monitoring for all security-critical resources to detect and respond to security incidents

---

*These standards are living documents and may be updated as cloud security best practices evolve.*
