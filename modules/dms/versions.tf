# ============================================================================
# Module Version Information
# ============================================================================
#
# This file defines version constraints and metadata for the DMS module.
# It ensures compatibility and provides version tracking for governance.
#
# Version: 1.0.0
# Release Date: 2026-01-05
# Compatibility: Terraform >= 1.0, AWS Provider ~> 6.26
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

# Module metadata for documentation and governance
locals {
  module_metadata = {
    name         = "aws-dms-module"
    version      = "1.0.0"
    release_date = "2026-01-05"
    description  = "AWS DMS module for database migration with security best practices"
    author       = "Infrastructure Team"
    license      = "MIT"

    # Compatibility matrix
    terraform_version = ">= 1.0"
    aws_provider      = "~> 6.26"

    # Feature flags for this version
    features = {
      secrets_manager_integration = true
      kms_encryption              = true
      enhanced_monitoring         = true
      multi_environment_support   = true
      security_groups_managed     = true
      flexible_networking         = true
    }

    # Breaking changes from previous versions
    breaking_changes = [
      "v1.0.0: Initial release - no breaking changes"
    ]

    # Deprecation notices
    deprecated_features = []
  }
}

# Output module metadata for external consumption
output "module_metadata" {
  description = "Module version and compatibility information"
  value       = local.module_metadata
}