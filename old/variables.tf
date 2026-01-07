# ============================================================================
# Client-Facing Variables for AWS DMS Deployment
# ============================================================================
#
# This file defines client-configurable variables for deploying AWS DMS
# resources following the tech leader pattern of inline variable assignment.
#
# Variable Categories:
# 1. Core Project Configuration
# 2. Network Infrastructure
# 3. Database Endpoint Configuration
# 4. Security and Encryption
# 5. DMS Instance Configuration
# 6. Migration Settings
# 7. Environment and Operational Settings
# 8. Resource Tagging
#
# All variables include:
# ✅ Client-friendly descriptions
# ✅ Clear usage examples
# ✅ Appropriate defaults where applicable
# ✅ Comprehensive validation rules
# ✅ Environment-specific guidance
# ============================================================================

# ============================================================================
# CORE PROJECT CONFIGURATION
# ============================================================================

variable "project_name" {
  description = <<-EOT
    Project name used as prefix for all DMS resources.
    
    This name will be used for:
    - Resource naming and identification
    - Cost allocation and tracking
    - Organizational governance
    - Tagging consistency
    
    Example: "client-migration", "data-sync", "analytics-etl"
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 30
    error_message = "Project name must be between 3 and 30 characters."
  }
}

variable "environment" {
  description = <<-EOT
    Deployment environment name.
    
    Used for:
    - Environment-specific resource configuration
    - Cost optimization based on environment type
    - Security settings (production gets enhanced security)
    - Resource naming and organization
    
    Supported environments: dev, development, staging, stage, test, prod, production
  EOT
  type        = string

  validation {
    condition = contains([
      "dev", "development",
      "staging", "stage", "test",
      "prod", "production"
    ], var.environment)
    error_message = "Environment must be one of: dev, development, staging, stage, test, prod, production."
  }
}

# ============================================================================
# NETWORK INFRASTRUCTURE
# ============================================================================

variable "vpc_id" {
  description = <<-EOT
    VPC ID where DMS resources will be deployed.
    
    Requirements:
    - VPC must have DNS resolution enabled
    - VPC must have DNS hostnames enabled
    - Must contain private subnets in multiple AZs
    - Should have NAT Gateway for AWS API access
    
    Example: "vpc-0123456789abcdef0"
  EOT
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must follow the format 'vpc-xxxxxxxxx'."
  }
}

variable "subnet_ids" {
  description = <<-EOT
    List of subnet IDs for DMS subnet group.
    
    Requirements:
    - Minimum 2 subnets in different AZs (required for Multi-AZ)
    - Preferably private subnets for security
    - Subnets must have connectivity to source/target databases
    - Subnets must have internet access via NAT Gateway
    
    Example: ["subnet-0123456789abcdef0", "subnet-0987654321fedcba0"]
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Minimum 2 subnets are required for DMS (Multi-AZ requirement)."
  }

  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids : can(regex("^subnet-[a-z0-9]+$", subnet_id))
    ])
    error_message = "All subnet IDs must follow the format 'subnet-xxxxxxxxx'."
  }
}

# ============================================================================
# DATABASE ENDPOINT CONFIGURATION
# ============================================================================

variable "enable_secrets_manager" {
  description = <<-EOT
    Enable AWS Secrets Manager for database credential management.
    
    When enabled (recommended for production):
    - Credentials stored securely in AWS Secrets Manager
    - Support for automatic credential rotation
    - No sensitive data in Terraform state
    
    When disabled (acceptable for development):
    - Direct credential configuration via variables
    - Simpler setup for testing environments
    
    Default: true (recommended)
  EOT
  type        = bool
  default     = true
}

# Source Database Configuration
variable "source_database_engine" {
  description = <<-EOT
    Source database engine type.
    
    Supported engines:
    - mysql, postgres, oracle, sqlserver
    - aurora, aurora-mysql, aurora-postgresql
    - mariadb, mongodb, redis, s3
    
    Example: "mysql", "postgres", "aurora-postgresql"
  EOT
  type        = string

  validation {
    condition = contains([
      "mysql", "postgres", "oracle", "sqlserver",
      "aurora", "aurora-mysql", "aurora-postgresql",
      "mariadb", "mongodb", "redis", "s3"
    ], var.source_database_engine)
    error_message = "Source engine must be a supported DMS engine type."
  }
}

variable "source_database_host" {
  description = <<-EOT
    Source database hostname or endpoint.
    
    Required when Secrets Manager is disabled.
    Can be empty when using Secrets Manager.
    
    Example: "source-db.company.internal", "mysql.cluster-xyz.region.rds.amazonaws.com"
  EOT
  type        = string
  default     = ""
}

variable "source_database_port" {
  description = <<-EOT
    Source database port number.
    
    Common ports:
    - MySQL/MariaDB: 3306
    - PostgreSQL/Aurora PostgreSQL: 5432
    - Oracle: 1521
    - SQL Server: 1433
    
    Default: 3306 (MySQL)
  EOT
  type        = number
  default     = 3306

  validation {
    condition     = var.source_database_port >= 1 && var.source_database_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "source_database_name" {
  description = <<-EOT
    Source database name.
    
    The specific database/schema name to migrate from.
    Required for most database engines.
    
    Example: "production_db", "ecommerce", "analytics"
  EOT
  type        = string
  default     = ""
}

variable "source_database_username" {
  description = <<-EOT
    Source database username.
    
    Required when Secrets Manager is disabled.
    Should have appropriate permissions for DMS operations.
    
    Example: "dms_user", "migration_user"
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "source_database_password" {
  description = <<-EOT
    Source database password.
    
    Required when Secrets Manager is disabled.
    Will be stored in Terraform state - use Secrets Manager for production.
    
    Note: Sensitive value, handle with care
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "source_secrets_manager_arn" {
  description = <<-EOT
    ARN of AWS Secrets Manager secret containing source database credentials.
    
    Required when Secrets Manager is enabled.
    Secret should contain: username, password, engine, host, port, dbname
    
    Example: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/mysql-credentials-AbCdEf"
  EOT
  type        = string
  default     = ""

  validation {
    condition = var.source_secrets_manager_arn == "" || can(regex("^arn:aws:secretsmanager:", var.source_secrets_manager_arn))
    error_message = "Secrets Manager ARN must be a valid AWS Secrets Manager ARN or empty."
  }
}

variable "source_secrets_access_role_arn" {
  description = <<-EOT
    ARN of IAM role for accessing source database secrets.
    
    Required when Secrets Manager is enabled.
    Role must have permissions to read the specified secret.
    
    Example: "arn:aws:iam::123456789012:role/dms-secrets-access-role"
  EOT
  type        = string
  default     = ""

  validation {
    condition = var.source_secrets_access_role_arn == "" || can(regex("^arn:aws:iam:", var.source_secrets_access_role_arn))
    error_message = "IAM role ARN must be a valid AWS IAM role ARN or empty."
  }
}

variable "source_ssl_mode" {
  description = <<-EOT
    SSL mode for source database connection.
    
    Options:
    - none: No SSL encryption
    - require: Require SSL but don't verify certificates
    - verify-ca: Require SSL and verify certificate authority
    - verify-full: Require SSL and verify full certificate chain
    
    Default: "require" (recommended for security)
  EOT
  type        = string
  default     = "require"

  validation {
    condition = contains(["none", "require", "verify-ca", "verify-full"], var.source_ssl_mode)
    error_message = "SSL mode must be one of: none, require, verify-ca, verify-full."
  }
}

variable "source_extra_attributes" {
  description = <<-EOT
    Additional connection attributes for source database.
    
    Engine-specific connection parameters as a semicolon-separated string.
    Consult AWS DMS documentation for engine-specific options.
    
    Example: "initstmt=SET FOREIGN_KEY_CHECKS=0;charset=utf8"
  EOT
  type        = string
  default     = ""
}

# Target Database Configuration
variable "target_database_engine" {
  description = <<-EOT
    Target database engine type.
    
    Supported engines:
    - mysql, postgres, oracle, sqlserver
    - aurora, aurora-mysql, aurora-postgresql
    - mariadb, mongodb, redis, s3, redshift
    
    Example: "aurora-postgresql", "postgres", "mysql"
  EOT
  type        = string

  validation {
    condition = contains([
      "mysql", "postgres", "oracle", "sqlserver",
      "aurora", "aurora-mysql", "aurora-postgresql",
      "mariadb", "mongodb", "redis", "s3", "redshift"
    ], var.target_database_engine)
    error_message = "Target engine must be a supported DMS engine type."
  }
}

variable "target_database_host" {
  description = <<-EOT
    Target database hostname or endpoint.
    
    Required when Secrets Manager is disabled.
    Can be empty when using Secrets Manager.
    
    Example: "target-db.company.internal", "aurora.cluster-xyz.region.rds.amazonaws.com"
  EOT
  type        = string
  default     = ""
}

variable "target_database_port" {
  description = <<-EOT
    Target database port number.
    
    Common ports:
    - MySQL/MariaDB: 3306
    - PostgreSQL/Aurora PostgreSQL: 5432
    - Oracle: 1521
    - SQL Server: 1433
    
    Default: 5432 (PostgreSQL)
  EOT
  type        = number
  default     = 5432

  validation {
    condition     = var.target_database_port >= 1 && var.target_database_port <= 65535
    error_message = "Port must be between 1 and 65535."
  }
}

variable "target_database_name" {
  description = <<-EOT
    Target database name.
    
    The specific database/schema name to migrate to.
    Required for PostgreSQL and Aurora PostgreSQL engines.
    
    Example: "production_db", "ecommerce", "analytics"
  EOT
  type        = string
  default     = ""
}

variable "target_database_username" {
  description = <<-EOT
    Target database username.
    
    Required when Secrets Manager is disabled.
    Should have appropriate permissions for DMS operations.
    
    Example: "dms_user", "migration_user"
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "target_database_password" {
  description = <<-EOT
    Target database password.
    
    Required when Secrets Manager is disabled.
    Will be stored in Terraform state - use Secrets Manager for production.
    
    Note: Sensitive value, handle with care
  EOT
  type        = string
  default     = ""
  sensitive   = true
}

variable "target_secrets_manager_arn" {
  description = <<-EOT
    ARN of AWS Secrets Manager secret containing target database credentials.
    
    Required when Secrets Manager is enabled.
    Secret should contain: username, password, engine, host, port, dbname
    
    Example: "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/postgres-credentials-GhIjKl"
  EOT
  type        = string
  default     = ""

  validation {
    condition = var.target_secrets_manager_arn == "" || can(regex("^arn:aws:secretsmanager:", var.target_secrets_manager_arn))
    error_message = "Secrets Manager ARN must be a valid AWS Secrets Manager ARN or empty."
  }
}

variable "target_secrets_access_role_arn" {
  description = <<-EOT
    ARN of IAM role for accessing target database secrets.
    
    Required when Secrets Manager is enabled.
    Role must have permissions to read the specified secret.
    
    Example: "arn:aws:iam::123456789012:role/dms-secrets-access-role"
  EOT
  type        = string
  default     = ""

  validation {
    condition = var.target_secrets_access_role_arn == "" || can(regex("^arn:aws:iam:", var.target_secrets_access_role_arn))
    error_message = "IAM role ARN must be a valid AWS IAM role ARN or empty."
  }
}

variable "target_ssl_mode" {
  description = <<-EOT
    SSL mode for target database connection.
    
    Options:
    - none: No SSL encryption
    - require: Require SSL but don't verify certificates
    - verify-ca: Require SSL and verify certificate authority
    - verify-full: Require SSL and verify full certificate chain
    
    Default: "require" (recommended for security)
  EOT
  type        = string
  default     = "require"

  validation {
    condition = contains(["none", "require", "verify-ca", "verify-full"], var.target_ssl_mode)
    error_message = "SSL mode must be one of: none, require, verify-ca, verify-full."
  }
}

variable "target_extra_attributes" {
  description = <<-EOT
    Additional connection attributes for target database.
    
    Engine-specific connection parameters as a semicolon-separated string.
    Consult AWS DMS documentation for engine-specific options.
    
    Example: "heartbeatEnable=true;heartbeatFrequency=30"
  EOT
  type        = string
  default     = ""
}

# ============================================================================
# SECURITY AND ENCRYPTION
# ============================================================================

variable "source_security_group_id" {
  description = <<-EOT
    Security group ID of the source database.
    
    DMS will create ingress rules in this security group to allow access
    from the DMS replication instance to the source database.
    
    Example: "sg-0123456789abcdef0"
  EOT
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.source_security_group_id))
    error_message = "Source security group ID must follow the format 'sg-xxxxxxxxx'."
  }
}

variable "target_security_group_id" {
  description = <<-EOT
    Security group ID of the target database.
    
    DMS will create ingress rules in this security group to allow access
    from the DMS replication instance to the target database.
    
    Example: "sg-0987654321fedcba0"
  EOT
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.target_security_group_id))
    error_message = "Target security group ID must follow the format 'sg-xxxxxxxxx'."
  }
}

variable "kms_key_arn" {
  description = <<-EOT
    ARN of KMS key for encryption at rest.
    
    Used for:
    - DMS replication instance storage encryption
    - Endpoint encryption
    - Compliance with security requirements
    
    Example: "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
  EOT
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid AWS KMS key ARN."
  }
}

# ============================================================================
# DMS INSTANCE CONFIGURATION
# ============================================================================

variable "dms_instance_class" {
  description = <<-EOT
    DMS replication instance class.
    
    Instance types:
    - dms.t3.micro, dms.t3.small, dms.t3.medium, dms.t3.large (burstable)
    - dms.r5.large, dms.r5.xlarge, dms.r5.2xlarge, dms.r5.4xlarge (memory optimized)
    - dms.c5.large, dms.c5.xlarge, dms.c5.2xlarge, dms.c5.4xlarge (compute optimized)
    
    Recommendations:
    - Development: dms.t3.micro or dms.t3.small
    - Production: dms.r5.large or higher
    
    Default: "dms.t3.micro"
  EOT
  type        = string
  default     = "dms.t3.micro"

  validation {
    condition = contains([
      "dms.t3.micro", "dms.t3.small", "dms.t3.medium", "dms.t3.large",
      "dms.r5.large", "dms.r5.xlarge", "dms.r5.2xlarge", "dms.r5.4xlarge",
      "dms.c5.large", "dms.c5.xlarge", "dms.c5.2xlarge", "dms.c5.4xlarge"
    ], var.dms_instance_class)
    error_message = "Instance class must be a supported DMS instance type."
  }
}

variable "dms_allocated_storage" {
  description = <<-EOT
    Allocated storage for DMS replication instance in GB.
    
    Range: 20 GB to 6144 GB
    
    Recommendations:
    - Development: 20-50 GB
    - Production: 100+ GB based on data volume
    
    Default: 20 GB
  EOT
  type        = number
  default     = 20

  validation {
    condition     = var.dms_allocated_storage >= 20 && var.dms_allocated_storage <= 6144
    error_message = "DMS instance storage must be between 20GB and 6144GB."
  }
}

variable "dms_engine_version" {
  description = <<-EOT
    DMS engine version.
    
    Use latest stable version for new deployments.
    Check AWS documentation for available versions.
    
    Example: "3.5.3", "3.5.2"
    Default: "3.5.3"
  EOT
  type        = string
  default     = "3.5.3"

  validation {
    condition = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.dms_engine_version))
    error_message = "Engine version must follow semantic versioning format (e.g., '3.5.3')."
  }
}

variable "dms_multi_az" {
  description = <<-EOT
    Enable Multi-AZ deployment for DMS replication instance.
    
    Multi-AZ provides:
    - High availability with automatic failover
    - Enhanced durability
    - Increased cost
    
    Recommendations:
    - Production: true (automatic based on environment)
    - Development/Staging: false (cost optimization)
    
    Default: false
  EOT
  type        = bool
  default     = false
}

# ============================================================================
# MIGRATION SETTINGS
# ============================================================================

variable "migration_type" {
  description = <<-EOT
    Type of database migration to perform.
    
    Options:
    - full-load: One-time complete data migration
    - cdc: Change Data Capture only (requires existing data)
    - full-load-and-cdc: Full migration + ongoing CDC (recommended)
    
    Default: "full-load-and-cdc"
  EOT
  type        = string
  default     = "full-load-and-cdc"

  validation {
    condition = contains([
      "full-load",
      "cdc",
      "full-load-and-cdc"
    ], var.migration_type)
    error_message = "Migration type must be: full-load, cdc, or full-load-and-cdc."
  }
}

variable "table_mappings" {
  description = <<-EOT
    Table mappings configuration for replication task.
    
    Defines which tables and schemas to migrate using selection rules.
    Must be a valid JSON object with DMS table mapping rules.
    
    Default: Migrate all tables from all schemas
  EOT
  type        = any
  default = {
    rules = [{
      rule-type = "selection"
      rule-id   = "1"
      rule-name = "include-all-tables"
      object-locator = {
        schema-name = "%"
        table-name  = "%"
      }
      rule-action = "include"
    }]
  }
}

variable "replication_task_settings" {
  description = <<-EOT
    Replication task settings for performance and reliability.
    
    Configures target metadata, full load settings, logging, and error handling.
    Must be a valid JSON object with DMS task settings.
    
    Default: Optimized settings for reliability and performance
  EOT
  type        = any
  default = {
    TargetMetadata = {
      TargetSchema       = ""
      SupportLobs        = true
      FullLobMode        = false
      LobChunkSize       = 32
      LimitedSizeLobMode = true
      LobMaxSize         = 16
    }
    FullLoadSettings = {
      TargetTablePrepMode           = "DROP_AND_CREATE"
      CreatePkAfterFullLoad         = true
      MaxFullLoadSubTasks           = 4
      TransactionConsistencyTimeout = 300
      CommitRate                    = 5000
    }
    Logging = {
      EnableLogging = true
      LogComponents = [
        {
          Id       = "SOURCE_UNLOAD"
          Severity = "LOGGER_SEVERITY_ERROR"
        },
        {
          Id       = "TARGET_LOAD"
          Severity = "LOGGER_SEVERITY_ERROR"
        }
      ]
    }
    ErrorBehavior = {
      DataErrorPolicy           = "LOG_ERROR"
      DataTruncationErrorPolicy = "LOG_ERROR"
      TableErrorPolicy          = "SUSPEND_TABLE"
      RecoverableErrorCount     = 5
      RecoverableErrorInterval  = 5
      FullLoadIgnoreConflicts   = true
    }
  }
}

# ============================================================================
# ENVIRONMENT AND OPERATIONAL SETTINGS
# ============================================================================

variable "enforce_ssl" {
  description = <<-EOT
    Enforce SSL/TLS for all database connections.
    
    When enabled, overrides individual SSL mode settings to "require".
    Recommended for production environments.
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "restrict_public_access" {
  description = <<-EOT
    Restrict public access to DMS resources.
    
    When enabled, ensures DMS replication instance is not publicly accessible.
    Should always be true for security.
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = <<-EOT
    Enable detailed CloudWatch monitoring for DMS instance.
    
    Provides enhanced monitoring capabilities with additional cost.
    Auto-enabled for production environments.
    
    Default: null (auto-detect based on environment)
  EOT
  type        = bool
  default     = null
}

variable "enable_performance_insights" {
  description = <<-EOT
    Enable Performance Insights for DMS instance.
    
    Provides detailed performance monitoring with additional cost.
    Recommended only for production environments.
    
    Default: null (auto-detect based on environment)
  EOT
  type        = bool
  default     = null
}

variable "network_isolation_level" {
  description = <<-EOT
    Level of network isolation for DMS security group.
    
    Options:
    - strict: Only essential AWS API access (HTTPS)
    - standard: AWS APIs + package updates (HTTPS + HTTP)
    - basic: Allow all egress traffic (legacy compatibility)
    
    Default: "strict"
  EOT
  type        = string
  default     = "strict"

  validation {
    condition = contains(["strict", "standard", "basic"], var.network_isolation_level)
    error_message = "Network isolation level must be one of: strict, standard, basic."
  }
}

variable "require_kms_encryption" {
  description = <<-EOT
    Require KMS encryption for all DMS resources.
    
    When enabled, enforces encryption at rest using the provided KMS key.
    Auto-enabled for production environments.
    
    Default: null (auto-detect based on environment)
  EOT
  type        = bool
  default     = null
}

variable "enable_deletion_protection" {
  description = <<-EOT
    Enable deletion protection for DMS resources.
    
    Prevents accidental deletion of critical resources.
    Auto-enabled for production environments.
    
    Default: null (auto-detect based on environment)
  EOT
  type        = bool
  default     = null
}

variable "enable_multi_az" {
  description = <<-EOT
    Enable Multi-AZ deployment for high availability.
    
    Provides automatic failover capability with additional cost.
    Can be overridden by force_multi_az_production setting.
    
    Default: false
  EOT
  type        = bool
  default     = false
}

variable "force_multi_az_production" {
  description = <<-EOT
    Force Multi-AZ deployment in production environments.
    
    When enabled, automatically enables Multi-AZ for production regardless
    of the enable_multi_az setting.
    
    Default: true
  EOT
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = <<-EOT
    Number of days to retain automated backups.
    
    Range: 1 to 35 days
    
    Recommendations:
    - Development: 1-7 days
    - Production: 30 days
    
    Default: 7 days
  EOT
  type        = number
  default     = 7

  validation {
    condition = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}

variable "preferred_maintenance_window" {
  description = <<-EOT
    Preferred maintenance window for DMS instance.
    
    Format: "day:hh:mm-day:hh:mm" (UTC)
    
    Example: "sun:03:00-sun:04:00"
    Default: "sun:03:00-sun:04:00"
  EOT
  type        = string
  default     = "sun:03:00-sun:04:00"

  validation {
    condition = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.preferred_maintenance_window))
    error_message = "Maintenance window must be in format 'day:hh:mm-day:hh:mm' (e.g., 'sun:03:00-sun:04:00')."
  }
}

variable "auto_minor_version_upgrade" {
  description = <<-EOT
    Enable automatic minor version upgrades.
    
    Automatically applies minor engine upgrades during maintenance windows.
    Recommended for security updates.
    
    Default: true
  EOT
  type        = bool
  default     = true
}

# ============================================================================
# RESOURCE TAGGING
# ============================================================================

variable "tags" {
  description = <<-EOT
    Additional tags to apply to all DMS resources.
    
    These tags will be merged with standard tags (Project, Environment, etc.).
    Use for organization-specific tagging requirements.
    
    Example:
    {
      Department     = "Engineering"
      Application    = "DataMigration"
      CostCenter     = "Infrastructure"
      BusinessUnit   = "Analytics"
      Compliance     = "SOX"
      Owner          = "data-team"
    }
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags : can(regex("^[a-zA-Z0-9_.-]+$", key))
    ])
    error_message = "Tag keys must contain only alphanumeric characters, underscores, periods, and hyphens."
  }

  validation {
    condition = alltrue([
      for key, value in var.tags : length(key) <= 128
    ])
    error_message = "Tag keys must be 128 characters or less."
  }

  validation {
    condition = alltrue([
      for key, value in var.tags : length(value) <= 256
    ])
    error_message = "Tag values must be 256 characters or less."
  }

  validation {
    condition = length(var.tags) <= 50
    error_message = "Maximum 50 additional tags allowed (AWS limit is 50 total tags per resource)."
  }

  validation {
    condition = !contains(keys(var.tags), "Name")
    error_message = "The 'Name' tag is automatically managed and cannot be overridden."
  }
}