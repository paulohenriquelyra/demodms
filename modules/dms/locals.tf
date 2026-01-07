# ============================================================================
# Locals Configuration for AWS DMS Module - Centralized Management
# ============================================================================
#
# This file centralizes all computed values, tags, and common configurations
# following HashiCorp and AWS best practices for module development.
#
# Configuration Categories:
# 1. Naming and Environment Configuration
# 2. Comprehensive Tagging Strategy  
# 3. Resource-Specific Tags
# 4. Computed Resource Names
# 5. Conditional Configurations (Secrets Manager, Lifecycle)
#
# Benefits:
# ✅ Single source of truth for all computed values
# ✅ Consistent naming patterns across all resources
# ✅ Centralized tag management for governance
# ✅ Conditional logic for different deployment scenarios
# ✅ Easy maintenance and updates
# ============================================================================

locals {
  # ============================================================================
  # NAMING AND ENVIRONMENT CONFIGURATION
  # ============================================================================
  
  # Centralized naming configuration for consistent resource identification
  naming = {
    prefix = "${var.project_name}-${var.environment}"
    suffix = var.naming_suffix != null ? var.naming_suffix : ""
  }
  
  # ============================================================================
  # COMPREHENSIVE TAGGING STRATEGY
  # ============================================================================
  
  # Common tags applied to all resources for governance and cost management
  # Following AWS tagging best practices and organizational standards
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Module      = "dms"
    ManagedBy   = "terraform"
    CreatedBy   = "dms-module"
    Owner       = var.owner != null ? var.owner : "infrastructure-team"
    CostCenter  = var.cost_center != null ? var.cost_center : "infrastructure"
    Backup      = var.environment == "production" ? "required" : "optional"
    Compliance  = "aws-well-architected"
  })
  
  # ============================================================================
  # RESOURCE-SPECIFIC TAGS
  # ============================================================================
  
  # Specialized tags for each resource type to enhance identification and management
  resource_tags = {
    # DMS Replication Instance Tags
    dms_instance = merge(local.common_tags, {
      Component   = "DMS-Compute"
      Description = "DMS replication instance for database migration"
      Critical    = "true"
      Service     = "database-migration"
      Monitoring  = "enabled"
    })
    
    # DMS Subnet Group Tags
    subnet_group = merge(local.common_tags, {
      Component   = "DMS-Network"
      Description = "Subnet group for DMS replication instance isolation"
      NetworkTier = "private"
      Security    = "isolated"
    })
    
    # Security Group Tags
    security_group = merge(local.common_tags, {
      Component   = "DMS-Security"
      Purpose     = "DMS replication instance network isolation"
      Description = "Restrictive security group following least privilege principle"
      SecurityLevel = "high"
    })
    
    # Source Endpoint Tags
    source_endpoint = merge(local.common_tags, {
      Component   = "DMS-Source"
      Engine      = var.source_endpoint_config.engine_name
      Description = "Source database endpoint for migration"
      DataFlow    = "Source"
      Direction   = "inbound"
    })
    
    # Target Endpoint Tags
    target_endpoint = merge(local.common_tags, {
      Component   = "DMS-Target"
      Engine      = var.target_endpoint_config.engine_name
      Description = "Target database endpoint for migration"
      DataFlow    = "Target"
      Direction   = "outbound"
    })
    
    # Replication Task Tags
    replication_task = merge(local.common_tags, {
      Component     = "DMS-Task"
      MigrationType = var.migration_type
      Description   = "Database migration task with CDC"
      Critical      = "true"
      Operation     = "data-migration"
    })
  }
  
  # ============================================================================
  # COMPUTED RESOURCE NAMES
  # ============================================================================
  
  # Centralized resource naming following consistent patterns
  # Format: {project_name}-{environment}-{component}-{resource_type}
  resource_names = {
    dms_instance      = "${local.naming.prefix}-dms-instance${local.naming.suffix}"
    subnet_group      = "${local.naming.prefix}-dms-subnet-group${local.naming.suffix}"
    security_group    = "${local.naming.prefix}-dms-sg${local.naming.suffix}"
    source_endpoint   = "${local.naming.prefix}-source-${var.source_endpoint_config.engine_name}${local.naming.suffix}"
    target_endpoint   = "${local.naming.prefix}-target-${var.target_endpoint_config.engine_name}${local.naming.suffix}"
    replication_task  = "${local.naming.prefix}-replication-task${local.naming.suffix}"
  }
  
  # ============================================================================
  # CONDITIONAL CONFIGURATIONS
  # ============================================================================
  
  # Secrets Manager Configuration (Optional)
  # Enables flexible credential management based on security requirements
  secrets_manager_config = var.enable_secrets_manager ? {
    source = {
      secrets_manager_arn             = var.source_endpoint_config.secrets_manager_arn
      secrets_manager_access_role_arn = var.source_endpoint_config.secrets_manager_access_role_arn
    }
    target = {
      secrets_manager_arn             = var.target_endpoint_config.secrets_manager_arn
      secrets_manager_access_role_arn = var.target_endpoint_config.secrets_manager_access_role_arn
    }
  } : null
  
  # Direct Credential Configuration (When Secrets Manager is disabled)
  # Provides alternative credential management for environments that don't use Secrets Manager
  direct_credentials_config = var.enable_secrets_manager ? null : {
    source = {
      server_name = var.source_endpoint_config.server_name
      port        = var.source_endpoint_config.port
      username    = var.source_endpoint_config.username
      password    = var.source_endpoint_config.password
      database_name = var.source_endpoint_config.database_name
    }
    target = {
      server_name = var.target_endpoint_config.server_name
      port        = var.target_endpoint_config.port
      username    = var.target_endpoint_config.username
      password    = var.target_endpoint_config.password
      database_name = var.target_endpoint_config.database_name
    }
  }
  
  # Environment-specific configurations
  # Allows different settings based on deployment environment
  environment_config = {
    is_production = contains(["prod", "production"], var.environment)
    multi_az_default = contains(["prod", "production"], var.environment) ? true : false
    backup_retention = contains(["prod", "production"], var.environment) ? 30 : 7
    monitoring_level = contains(["prod", "production"], var.environment) ? "detailed" : "basic"
    deletion_protection = contains(["prod", "production"], var.environment) ? true : false
    performance_insights = contains(["prod", "production"], var.environment) ? true : false
  }
  
  # ============================================================================
  # SECURITY CONFIGURATIONS
  # ============================================================================
  
  # AWS Well-Architected Framework Security Configuration
  # Enforces security best practices based on environment and security config
  # Implements cost optimization through environment-based feature enablement
  security_settings = {
    # Multi-AZ configuration with production enforcement
    multi_az_enabled = var.multi_az_config.force_multi_az_production && local.environment_config.is_production ? true : var.multi_az_config.enable_multi_az
    
    # SSL/TLS enforcement for all connections
    ssl_mode_source = var.security_config.enforce_ssl ? "require" : var.source_endpoint_config.ssl_mode
    ssl_mode_target = var.security_config.enforce_ssl ? "require" : var.target_endpoint_config.ssl_mode
    
    # Public access restriction (always false for security)
    publicly_accessible = var.security_config.restrict_public_access ? false : false
    
    # KMS encryption with environment-based auto-detection
    kms_encryption_required = var.security_config.require_kms_encryption != null ? var.security_config.require_kms_encryption : local.environment_config.is_production
    
    # Deletion protection based on environment and configuration
    deletion_protection = var.security_config.enable_deletion_protection != null ? var.security_config.enable_deletion_protection : local.environment_config.is_production
    
    # Performance Insights with cost optimization for non-production environments
    # Auto-enabled only for production, optional for staging, disabled for development
    performance_insights_enabled = var.security_config.enable_performance_insights != null ? var.security_config.enable_performance_insights : (
      local.environment_config.is_production ? true : false
    )
    
    # Detailed monitoring with environment-based cost optimization
    # Enabled for production and staging, optional for development
    monitoring_enabled = var.security_config.enable_detailed_monitoring != null ? var.security_config.enable_detailed_monitoring : (
      contains(["prod", "production", "staging", "stage"], var.environment) ? true : false
    )
  }
  
  # Network Security Configuration
  # Implements network isolation based on security level
  network_security = {
    # Security group rules based on isolation level
    allow_all_egress = var.security_config.network_isolation_level == "basic" ? true : false
    
    # Restricted egress for strict isolation
    restricted_egress_rules = var.security_config.network_isolation_level == "strict" ? [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS outbound for AWS APIs (DMS, CloudWatch, Secrets Manager)"
      }
      #       {
      #         from_port   = 3306
      #         to_port     = 3306
      #         protocol    = "tcp"
      #         cidr_blocks = []
      #         description = "MySQL source database access"
      #       },
      #       {
      #         from_port   = 5432
      #         to_port     = 5432
      #         protocol    = "tcp"
      #         cidr_blocks = []
      #         description = "PostgreSQL target database access"
      #       }
    ] : [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = []
        description = "No restricted rules"
      }
    ]
    
    # Standard egress for standard isolation
    standard_egress_rules = var.security_config.network_isolation_level == "standard" ? [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS outbound for AWS APIs"
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP outbound for package updates"
      }
      #       {
      #         from_port   = 3306
      #         to_port     = 3306
      #         protocol    = "tcp"
      #         cidr_blocks = []
      #         description = "MySQL source database access"
      #       },
      #       {
      #         from_port   = 5432
      #         to_port     = 5432
      #         protocol    = "tcp"
      #         cidr_blocks = []
      #         description = "PostgreSQL target database access"
      #       }
    ] : [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = []
        description = "No standard rules"
      }
    ]
  }
}