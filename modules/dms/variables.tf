# ============================================================================
# Variables for AWS DMS Module - Comprehensive Configuration
# ============================================================================
#
# This file defines all variables necessary to configure a complete
# data migration solution using AWS DMS.
#
# Variable Categories:
# 1. Project Identification and Environment
# 2. Network Configuration (VPC, subnets)
# 3. Endpoint Configuration (source/target databases)
# 4. Security Configuration (security groups, KMS, Secrets Manager)
# 5. DMS Instance Configuration (class, storage, engine)
# 6. Migration Configuration (type, table mappings, task settings)
# 7. Tags and Metadata
#
# All variables include:
# ✅ Detailed descriptions in English
# ✅ Specific types with validation
# ✅ Sensible defaults where applicable
# ✅ Comprehensive validation rules
# ✅ Usage examples
# ============================================================================

# ============================================================================
# PROJECT IDENTIFICATION AND ENVIRONMENT
# ============================================================================

variable "project_name" {
  description = <<-EOT
    Project name used as prefix for all resources.
    
    Used for:
    - Consistent resource naming
    - Billing and cost tracking identification
    - Organization of related resources
    - Tagging and governance
    
    Example: "client-dms-migration", "prod-migration", "analytics-platform"
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
    Environment name for deployment (dev, staging, production).
    
    Used for:
    - Environment-specific configurations
    - Resource naming and identification
    - Conditional logic (Multi-AZ, backup settings)
    - Cost allocation and governance
    
    Example: "dev", "staging", "production"
  EOT
  type        = string

  validation {
    condition = contains([
      "dev", "development",
      "staging", "stage", "test",
      "prod", "production",
      "ti", "trg"
    ], var.environment)
    error_message = "Environment must be one of: dev, development, staging, stage, test, prod, production, ti, trg."
  }
}

variable "naming_suffix" {
  description = <<-EOT
    Optional suffix for resource names.
    
    Used for:
    - Distinguishing between multiple deployments
    - Version identification
    - Regional deployment differentiation
    
    Example: "-v2", "-east", "-backup"
  EOT
  type        = string
  default     = null
}

variable "owner" {
  description = <<-EOT
    Owner or team responsible for the resources.
    
    Used for:
    - Resource ownership identification
    - Contact information for support
    - Governance and compliance
    
    Example: "data-team", "infrastructure-team", "analytics-group"
  EOT
  type        = string
  default     = null
}

variable "cost_center" {
  description = <<-EOT
    Cost center for billing allocation.
    
    Used for:
    - Cost tracking and allocation
    - Budget management
    - Financial reporting
    
    Example: "engineering", "data-analytics", "infrastructure"
  EOT
  type        = string
  default     = null
}

# ============================================================================
# NETWORK CONFIGURATION
# ============================================================================

variable "vpc_id" {
  description = <<-EOT
    ID of the VPC where DMS resources will be created.
    
    Requirements:
    - VPC must have DNS resolution enabled
    - VPC must have DNS hostnames enabled
    - Must contain private subnets in multiple AZs
    - Should have NAT Gateway for internet access to AWS APIs
    
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
    List of subnet IDs for the DMS subnet group.
    
    Requirements:
    - Minimum 2 subnets in different AZs (for Multi-AZ support)
    - Preferably private subnets for security
    - Subnets must have connectivity to source/target databases
    - Subnets must have internet access via NAT Gateway (for AWS APIs)
    
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
# ENDPOINT CONFIGURATION
# ============================================================================

variable "enable_secrets_manager" {
  description = <<-EOT
    Enable Secrets Manager for credential management.
    
    When enabled:
    - Credentials are managed through AWS Secrets Manager
    - Enhanced security with automatic rotation support
    - No hardcoded credentials in Terraform state
    
    When disabled:
    - Direct credential configuration required
    - Credentials managed through variables
    - Suitable for environments without Secrets Manager
    
    Default: true (recommended for production)
  EOT
  type        = bool
  default     = true
}

variable "source_endpoint_config" {
  description = <<-EOT
    Source endpoint configuration for database migration.
    
    When Secrets Manager is enabled, provide:
    - secrets_manager_arn: ARN of the secret containing credentials
    - secrets_manager_access_role_arn: IAM role for accessing the secret
    
    When Secrets Manager is disabled, provide:
    - server_name: Database server hostname or IP
    - port: Database port number
    - username: Database username
    - password: Database password
    - database_name: Database name (optional for some engines)
    
    Environment-specific considerations:
    - Production: Secrets Manager strongly recommended
    - Development: Direct credentials acceptable for testing
  EOT
  type = object({
    engine_name = string
    # Secrets Manager configuration (when enabled)
    secrets_manager_arn             = optional(string, "")
    secrets_manager_access_role_arn = optional(string, "")
    # Direct credential configuration (when Secrets Manager disabled)
    server_name   = optional(string, "")
    port          = optional(number, 3306)
    username      = optional(string, "")
    password      = optional(string, "")
    database_name = optional(string, "")
    # Connection settings
    ssl_mode                    = optional(string, "none")
    extra_connection_attributes = optional(string, "")
  })

  validation {
    condition = contains([
      "mysql", "postgres", "oracle", "sqlserver",
      "aurora", "aurora-mysql", "aurora-postgresql",
      "mariadb", "mongodb", "redis", "s3"
    ], var.source_endpoint_config.engine_name)
    error_message = "Source engine must be a supported DMS engine type."
  }

  validation {
    condition     = var.source_endpoint_config.port >= 1 && var.source_endpoint_config.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }

  validation {
    condition     = contains(["none", "require", "verify-ca", "verify-full"], var.source_endpoint_config.ssl_mode)
    error_message = "SSL mode must be one of: none, require, verify-ca, verify-full."
  }

  validation {
    condition     = var.source_endpoint_config.secrets_manager_arn == "" || can(regex("^arn:aws:secretsmanager:", var.source_endpoint_config.secrets_manager_arn))
    error_message = "Secrets Manager ARN must be a valid AWS Secrets Manager ARN or empty."
  }

  validation {
    condition     = var.source_endpoint_config.secrets_manager_access_role_arn == "" || can(regex("^arn:aws:iam:", var.source_endpoint_config.secrets_manager_access_role_arn))
    error_message = "Secrets Manager access role ARN must be a valid AWS IAM role ARN or empty."
  }
}

variable "target_endpoint_config" {
  description = <<-EOT
    Target endpoint configuration for database migration.
    
    When Secrets Manager is enabled, provide:
    - secrets_manager_arn: ARN of the secret containing credentials
    - secrets_manager_access_role_arn: IAM role for accessing the secret
    
    When Secrets Manager is disabled, provide:
    - server_name: Database server hostname or IP
    - port: Database port number
    - username: Database username
    - password: Database password
    - database_name: Database name (required for PostgreSQL)
    
    Environment-specific considerations:
    - Production: SSL required, Secrets Manager strongly recommended
    - Development: SSL recommended, direct credentials acceptable
  EOT
  type = object({
    engine_name = string
    # Secrets Manager configuration (when enabled)
    secrets_manager_arn             = optional(string, "")
    secrets_manager_access_role_arn = optional(string, "")
    # Direct credential configuration (when Secrets Manager disabled)
    server_name   = optional(string, "")
    port          = optional(number, 5432)
    username      = optional(string, "")
    password      = optional(string, "")
    database_name = optional(string, "")
    # Connection settings
    ssl_mode                    = optional(string, "require")
    extra_connection_attributes = optional(string, "")
  })

  validation {
    condition = contains([
      "mysql", "postgres", "oracle", "sqlserver",
      "aurora", "aurora-mysql", "aurora-postgresql",
      "mariadb", "mongodb", "redis", "s3", "redshift"
    ], var.target_endpoint_config.engine_name)
    error_message = "Target engine must be a supported DMS engine type."
  }

  validation {
    condition     = var.target_endpoint_config.port >= 1 && var.target_endpoint_config.port <= 65535
    error_message = "Port must be between 1 and 65535."
  }

  validation {
    condition     = contains(["none", "require", "verify-ca", "verify-full"], var.target_endpoint_config.ssl_mode)
    error_message = "SSL mode must be one of: none, require, verify-ca, verify-full."
  }

  validation {
    condition     = var.target_endpoint_config.secrets_manager_arn == "" || can(regex("^arn:aws:secretsmanager:", var.target_endpoint_config.secrets_manager_arn))
    error_message = "Secrets Manager ARN must be a valid AWS Secrets Manager ARN or empty."
  }

  validation {
    condition     = var.target_endpoint_config.secrets_manager_access_role_arn == "" || can(regex("^arn:aws:iam:", var.target_endpoint_config.secrets_manager_access_role_arn))
    error_message = "Secrets Manager access role ARN must be a valid AWS IAM role ARN or empty."
  }

  validation {
    condition     = !(contains(["postgres", "aurora-postgresql"], var.target_endpoint_config.engine_name) && var.target_endpoint_config.database_name == "")
    error_message = "Database name is required for PostgreSQL and Aurora PostgreSQL engines."
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "source_security_group_id" {
  description = <<-EOT
    Security group ID of the source database.
    
    Used for:
    - Creating ingress rules to allow DMS access
    - Establishing secure connectivity between DMS and source database
    
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
    
    Used for:
    - Creating ingress rules to allow DMS access
    - Establishing secure connectivity between DMS and target database
    
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
    ARN of the KMS key for encryption at rest.
    
    Used for:
    - DMS replication instance encryption
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

variable "security_config" {
  description = <<-EOT
    Advanced security configuration for AWS Well-Architected compliance.
    
    Security features:
    - enforce_ssl: Enforce SSL/TLS for all database connections
    - restrict_public_access: Ensure no resources are publicly accessible
    - enable_detailed_monitoring: Enable detailed CloudWatch monitoring (cost impact in non-prod)
    - enable_performance_insights: Enable Performance Insights for monitoring (cost impact - recommended only for production)
    - network_isolation_level: Level of network isolation (strict, standard, basic)
    - require_kms_encryption: Enforce KMS encryption (can be disabled for dev/test environments)
    - enable_deletion_protection: Prevent accidental resource deletion
    
    Environment-based recommendations:
    - Production: All features enabled for maximum security and observability
    - Staging: Detailed monitoring enabled, Performance Insights optional
    - Development: Basic monitoring, Performance Insights disabled for cost optimization
    
    AWS Well-Architected Framework compliance:
    - Security Pillar: Encryption in transit and at rest
    - Reliability Pillar: Multi-AZ deployment support
    - Performance Efficiency: Performance monitoring and insights
    - Cost Optimization: Environment-based feature enablement
    - Operational Excellence: Comprehensive monitoring and logging
  EOT
  type = object({
    enforce_ssl                 = optional(bool, true)
    restrict_public_access      = optional(bool, true)
    enable_detailed_monitoring  = optional(bool, null) # null = auto-detect based on environment
    enable_performance_insights = optional(bool, null) # null = auto-detect based on environment
    network_isolation_level     = optional(string, "strict")
    require_kms_encryption      = optional(bool, null) # null = auto-detect based on environment
    enable_deletion_protection  = optional(bool, null) # null = auto-detect based on environment
  })

  default = {
    enforce_ssl                 = true
    restrict_public_access      = true
    enable_detailed_monitoring  = null # Auto-detect: true for prod, false for dev
    enable_performance_insights = null # Auto-detect: true for prod, false for dev/staging
    network_isolation_level     = "strict"
    require_kms_encryption      = null # Auto-detect: true for prod, optional for dev
    enable_deletion_protection  = null # Auto-detect: true for prod, false for dev
  }

  validation {
    condition     = contains(["strict", "standard", "basic"], var.security_config.network_isolation_level)
    error_message = "Network isolation level must be one of: strict, standard, basic."
  }

  validation {
    condition     = var.security_config.require_kms_encryption != false || !contains(["prod", "production"], var.environment)
    error_message = "KMS encryption cannot be disabled in production environments for security compliance."
  }

  validation {
    condition     = var.security_config.enable_performance_insights != true || var.security_config.enable_detailed_monitoring != false
    error_message = "Performance Insights requires detailed monitoring to be enabled."
  }
}

variable "multi_az_config" {
  description = <<-EOT
    Multi-AZ configuration for high availability and disaster recovery.
    
    Configuration options:
    - enable_multi_az: Enable Multi-AZ deployment for DMS instance
    - force_multi_az_production: Force Multi-AZ in production environments
    - backup_retention_days: Number of days to retain automated backups
    - preferred_maintenance_window: Preferred maintenance window
    - auto_minor_version_upgrade: Enable automatic minor version upgrades
    
    AWS Well-Architected Framework - Reliability Pillar:
    - Multi-AZ deployment provides automatic failover capability
    - Automated backups ensure data durability
    - Maintenance windows minimize operational impact
  EOT
  type = object({
    enable_multi_az              = optional(bool, false)
    force_multi_az_production    = optional(bool, true)
    backup_retention_days        = optional(number, 7)
    preferred_maintenance_window = optional(string, "sun:03:00-sun:04:00")
    auto_minor_version_upgrade   = optional(bool, true)
  })

  default = {
    enable_multi_az              = false
    force_multi_az_production    = true
    backup_retention_days        = 7
    preferred_maintenance_window = "sun:03:00-sun:04:00"
    auto_minor_version_upgrade   = true
  }

  validation {
    condition     = var.multi_az_config.backup_retention_days >= 1 && var.multi_az_config.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.multi_az_config.preferred_maintenance_window))
    error_message = "Maintenance window must be in format 'day:hh:mm-day:hh:mm' (e.g., 'sun:03:00-sun:04:00')."
  }
}

# ============================================================================
# DMS INSTANCE CONFIGURATION
# ============================================================================

variable "dms_instance_config" {
  description = <<-EOT
    DMS replication instance configuration.
    
    Configuration options:
    - instance_class: Instance type (e.g., dms.t3.micro, dms.r5.large)
    - allocated_storage: Storage in GB (minimum 20GB, maximum 6144GB)
    - engine_version: DMS engine version (e.g., "3.5.3", "3.5.2")
    - multi_az: Enable Multi-AZ deployment for high availability
    
    Environment-specific defaults:
    - Production: Multi-AZ enabled, larger instance classes recommended
    - Development: Single-AZ acceptable, smaller instance classes for cost optimization
  EOT
  type = object({
    instance_class    = string
    allocated_storage = number
    engine_version    = string
    multi_az          = bool
  })

  default = {
    instance_class    = "dms.t3.micro"
    allocated_storage = 20
    engine_version    = "3.5.3"
    multi_az          = false
  }

  validation {
    condition     = var.dms_instance_config.allocated_storage >= 20 && var.dms_instance_config.allocated_storage <= 6144
    error_message = "DMS instance storage must be between 20GB and 6144GB."
  }

  validation {
    condition     = can(regex("^dms\\.", var.dms_instance_config.instance_class))
    error_message = "Instance class must be a valid DMS instance type (e.g., dms.t3.micro, dms.r5.large)."
  }

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.dms_instance_config.engine_version))
    error_message = "Engine version must follow semantic versioning format (e.g., '3.5.3')."
  }

  validation {
    condition = contains([
      "dms.t3.micro", "dms.t3.small", "dms.t3.medium", "dms.t3.large",
      "dms.r5.large", "dms.r5.xlarge", "dms.r5.2xlarge", "dms.r5.4xlarge",
      "dms.c5.large", "dms.c5.xlarge", "dms.c5.2xlarge", "dms.c5.4xlarge"
    ], var.dms_instance_config.instance_class)
    error_message = "Instance class must be a supported DMS instance type."
  }
}

# ============================================================================
# MIGRATION CONFIGURATION
# ============================================================================

variable "migration_type" {
  description = <<-EOT
    Type of database migration to perform.
    
    Options:
    - full-load: One-time full data migration
    - cdc: Change Data Capture only (requires existing data)
    - full-load-and-cdc: Full migration followed by ongoing CDC
    
    Recommended: full-load-and-cdc for complete migration solution
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
    Table mappings configuration for the replication task.
    
    Defines which tables and schemas to migrate.
    Use selection rules to include/exclude specific tables.
    
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
    
    Configures:
    - Target metadata handling
    - Full load settings and performance
    - Logging configuration
    - Error handling behavior
    
    Settings are optimized for reliability and can be customized per environment.
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
# TAGS AND METADATA
# ============================================================================

variable "tags" {
  description = <<-EOT
    Additional tags to apply to all resources.
    
    These tags will be merged with the standard tags defined in locals.
    Use for organization-specific tagging requirements.
    
    Standard tags automatically applied:
    - Project, Environment, Module, ManagedBy, CreatedBy
    - Owner, CostCenter, Backup, Compliance
    
    Example:
    {
      Department = "Engineering"
      Application = "DataMigration"
      Compliance = "SOX"
      BusinessUnit = "Analytics"
    }
    
    Environment-specific considerations:
    - Production: Include compliance and business unit tags
    - Development: Minimal tagging acceptable for cost optimization
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
    condition     = length(var.tags) <= 50
    error_message = "Maximum 50 additional tags allowed (AWS limit is 50 total tags per resource)."
  }

  validation {
    condition     = !contains(keys(var.tags), "Name")
    error_message = "The 'Name' tag is automatically managed by the module and cannot be overridden."
  }
}

# ============================================================================
# ENVIRONMENT-SPECIFIC CONFIGURATION
# ============================================================================

variable "environment_config" {
  description = <<-EOT
    Environment-specific configuration overrides.
    
    Allows customization of behavior based on deployment environment:
    - backup_retention_days: How long to retain backups
    - monitoring_level: Level of monitoring detail
    - performance_insights: Enable Performance Insights
    - deletion_protection: Prevent accidental deletion
    
    Environment defaults:
    - Production: Enhanced monitoring, longer retention, deletion protection
    - Development: Basic monitoring, shorter retention, no deletion protection
  EOT
  type = object({
    backup_retention_days = optional(number, 7)
    monitoring_level      = optional(string, "basic")
    performance_insights  = optional(bool, false)
    deletion_protection   = optional(bool, false)
  })

  default = {
    backup_retention_days = 7
    monitoring_level      = "basic"
    performance_insights  = false
    deletion_protection   = false
  }

  validation {
    condition     = var.environment_config.backup_retention_days >= 1 && var.environment_config.backup_retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }

  validation {
    condition     = contains(["basic", "detailed", "enhanced"], var.environment_config.monitoring_level)
    error_message = "Monitoring level must be one of: basic, detailed, enhanced."
  }
}