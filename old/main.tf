# ============================================================================
# AWS DMS Deployment - Client-Ready Configuration
# ============================================================================
#
# This file implements the tech leader pattern for AWS DMS deployment,
# providing a client-ready structure with inline variable assignments
# for maximum portability and ease of use.
#
# Architecture:
# - Calls the validated DMS module with all configurations inline
# - Supports both Secrets Manager and direct credential management
# - Implements environment-specific optimizations
# - Provides comprehensive security and monitoring configurations
#
# Usage:
# 1. Configure variables in terraform.tfvars
# 2. Run: terraform init
# 3. Run: terraform plan
# 4. Run: terraform apply
#
# Features:
# ✅ Tech leader approved inline variable pattern
# ✅ Flexible credential management (Secrets Manager or direct)
# ✅ Environment-specific cost and security optimization
# ✅ Comprehensive validation and error handling
# ✅ Production-ready security configurations
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26"
    }
  }
}

# ============================================================================
# DMS MODULE DEPLOYMENT
# ============================================================================

module "dms" {
  source = "./modules/dms"

  # ============================================================================
  # CORE PROJECT CONFIGURATION
  # ============================================================================

  project_name = var.project_name
  environment  = var.environment

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # ============================================================================
  # SOURCE ENDPOINT CONFIGURATION
  # ============================================================================

  source_endpoint_config = {
    engine_name = var.source_database_engine

    # Secrets Manager Configuration (when enabled)
    secrets_manager_arn             = var.enable_secrets_manager ? var.source_secrets_manager_arn : ""
    secrets_manager_access_role_arn = var.enable_secrets_manager ? var.source_secrets_access_role_arn : ""

    # Direct Credential Configuration (when Secrets Manager disabled)
    server_name   = var.enable_secrets_manager ? "" : var.source_database_host
    port          = var.source_database_port
    username      = var.enable_secrets_manager ? "" : var.source_database_username
    password      = var.enable_secrets_manager ? "" : var.source_database_password
    database_name = var.source_database_name

    # Connection Security Settings
    ssl_mode                    = var.source_ssl_mode
    extra_connection_attributes = var.source_extra_attributes
  }

  # ============================================================================
  # TARGET ENDPOINT CONFIGURATION
  # ============================================================================

  target_endpoint_config = {
    engine_name = var.target_database_engine

    # Secrets Manager Configuration (when enabled)
    secrets_manager_arn             = var.enable_secrets_manager ? var.target_secrets_manager_arn : ""
    secrets_manager_access_role_arn = var.enable_secrets_manager ? var.target_secrets_access_role_arn : ""

    # Direct Credential Configuration (when Secrets Manager disabled)
    server_name   = var.enable_secrets_manager ? "" : var.target_database_host
    port          = var.target_database_port
    username      = var.enable_secrets_manager ? "" : var.target_database_username
    password      = var.enable_secrets_manager ? "" : var.target_database_password
    database_name = var.target_database_name

    # Connection Security Settings
    ssl_mode                    = var.target_ssl_mode
    extra_connection_attributes = var.target_extra_attributes
  }

  # ============================================================================
  # SECURITY CONFIGURATION
  # ============================================================================

  # Credential Management
  enable_secrets_manager = var.enable_secrets_manager

  # Security Groups
  source_security_group_id = var.source_security_group_id
  target_security_group_id = var.target_security_group_id

  # Encryption
  kms_key_arn = var.kms_key_arn

  # ============================================================================
  # DMS INSTANCE CONFIGURATION
  # ============================================================================

  dms_instance_config = {
    instance_class    = var.dms_instance_class
    allocated_storage = var.dms_allocated_storage
    engine_version    = var.dms_engine_version
    multi_az          = var.dms_multi_az
  }

  # ============================================================================
  # MIGRATION CONFIGURATION
  # ============================================================================

  migration_type            = var.migration_type
  table_mappings            = var.table_mappings
  replication_task_settings = var.replication_task_settings

  # ============================================================================
  # SECURITY AND COMPLIANCE CONFIGURATION
  # ============================================================================

  security_config = {
    enforce_ssl                 = var.enforce_ssl
    restrict_public_access      = var.restrict_public_access
    enable_detailed_monitoring  = var.enable_detailed_monitoring
    enable_performance_insights = var.enable_performance_insights
    network_isolation_level     = var.network_isolation_level
    require_kms_encryption      = var.require_kms_encryption
    enable_deletion_protection  = var.enable_deletion_protection
  }

  # ============================================================================
  # MULTI-AZ AND OPERATIONAL CONFIGURATION
  # ============================================================================

  multi_az_config = {
    enable_multi_az              = var.enable_multi_az
    force_multi_az_production    = var.force_multi_az_production
    backup_retention_days        = var.backup_retention_days
    preferred_maintenance_window = var.preferred_maintenance_window
    auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  }

  # ============================================================================
  # RESOURCE TAGGING
  # ============================================================================

  tags = var.tags
}