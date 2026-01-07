# ============================================================================
# DMS Module Integration Test Configuration
# ============================================================================
# This file tests the DMS module with different environment configurations
# Usage: terraform plan -var-file="<environment>.tfvars"

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  # Use default tags for all resources
  default_tags {
    tags = merge(var.tags, {
      ManagedBy = "terraform"
      Module    = "dms-integration-test"
      TestType  = "integration"
    })
  }
}

# ============================================================================
# DMS Module Under Test
# ============================================================================

module "dms" {
  source = "../.."  # Reference to the DMS module

  # Core Configuration
  project_name = var.project_name
  environment  = var.environment

  # Network Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # DMS Instance Configuration
  dms_instance_config = var.dms_instance_config

  # Database Endpoints Configuration
  source_endpoint_config = var.source_endpoint_config
  target_endpoint_config = var.target_endpoint_config

  # Security Group Configuration
  source_security_group_id = var.source_security_group_id
  target_security_group_id = var.target_security_group_id

  # Security Configuration
  enable_secrets_manager = var.enable_secrets_manager
  kms_key_arn           = var.kms_key_arn

  # Migration Configuration
  migration_type = var.migration_type
  table_mappings = var.table_mappings

  # Environment-specific Configuration
  environment_config = var.environment_config

  # Tags
  tags = var.tags
}

# ============================================================================
# Test Outputs for Validation
# ============================================================================

output "test_results" {
  description = "Integration test results and validation data"
  value = {
    # Module Outputs
    dms_instance      = module.dms.dms_instance
    replication_task  = module.dms.replication_task
    endpoints         = module.dms.endpoints
    network           = module.dms.network

    # Test Configuration Summary
    test_environment = {
      project_name           = var.project_name
      environment           = var.environment
      secrets_manager_enabled = var.enable_secrets_manager
      multi_az_enabled      = var.dms_instance_config.multi_az
      instance_class        = var.dms_instance_config.instance_class
      kms_encryption        = var.kms_key_arn != null
    }

    # Validation Checks
    validation = {
      # Check that resource names follow naming convention
      naming_convention_valid = can(regex("^${var.project_name}-${var.environment}-", module.dms.dms_instance.id))
      
      # Check that endpoints are configured correctly
      source_endpoint_configured = module.dms.endpoints.source.id != null
      target_endpoint_configured = module.dms.endpoints.target.id != null
      
      # Check that replication task is configured
      replication_task_configured = module.dms.replication_task.id != null
      
      # Check security configuration
      security_configured = var.enable_secrets_manager ? (
        can(regex("arn:aws:secretsmanager:", var.source_endpoint_config.secrets_manager_arn))
      ) : (
        var.source_endpoint_config.server_name != null
      )
    }
  }
}

# Legacy outputs for backward compatibility testing
output "replication_instance_arn" {
  description = "Legacy output - DMS replication instance ARN"
  value       = module.dms.replication_instance_arn
}

output "replication_instance_id" {
  description = "Legacy output - DMS replication instance ID"
  value       = module.dms.replication_instance_id
}

output "replication_task_arn" {
  description = "Legacy output - DMS replication task ARN"
  value       = module.dms.replication_task_arn
}

output "source_endpoint_arn" {
  description = "Legacy output - Source endpoint ARN"
  value       = module.dms.source_endpoint_arn
}

output "target_endpoint_arn" {
  description = "Legacy output - Target endpoint ARN"
  value       = module.dms.target_endpoint_arn
}