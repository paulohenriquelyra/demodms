# ============================================================================
# Integration Test Variables
# ============================================================================

variable "aws_region" {
  description = "AWS region for testing"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for DMS resources"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DMS subnet group"
  type        = list(string)
}

variable "dms_instance_config" {
  description = "DMS instance configuration"
  type = object({
    instance_class         = string
    allocated_storage      = number
    engine_version         = string
    multi_az              = bool
    publicly_accessible   = bool
    auto_minor_version_upgrade = bool
  })
}

variable "source_endpoint_config" {
  description = "Source database endpoint configuration"
  type = object({
    engine_name                     = string
    server_name                     = optional(string)
    port                           = number
    database_name                  = string
    username                       = string
    password                       = optional(string)
    secrets_manager_arn            = optional(string)
    secrets_manager_access_role_arn = optional(string)
    ssl_mode                       = string
  })
}

variable "target_endpoint_config" {
  description = "Target database endpoint configuration"
  type = object({
    engine_name                     = string
    server_name                     = optional(string)
    port                           = number
    database_name                  = string
    username                       = string
    password                       = optional(string)
    secrets_manager_arn            = optional(string)
    secrets_manager_access_role_arn = optional(string)
    ssl_mode                       = string
  })
}

variable "source_security_group_id" {
  description = "Security group ID of the source database"
  type        = string
  default     = "sg-xxxxxxxxxxxxxxxxx"  # Replace with actual security group ID
}

variable "target_security_group_id" {
  description = "Security group ID of the target database"
  type        = string
  default     = "sg-yyyyyyyyyyyyyyyyy"  # Replace with actual security group ID
}

variable "enable_secrets_manager" {
  description = "Enable Secrets Manager for credential management"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

variable "migration_type" {
  description = "Type of migration (full-load, cdc, full-load-and-cdc)"
  type        = string
  default     = "full-load-and-cdc"
}

variable "table_mappings" {
  description = "JSON string defining table mappings for replication"
  type        = string
}

variable "task_settings" {
  description = "JSON string defining task settings for replication"
  type        = string
  default     = null
}

variable "environment_config" {
  description = "Environment-specific configuration"
  type = object({
    backup_retention_period = number
    monitoring_interval    = number
    performance_insights   = bool
    deletion_protection    = bool
  })
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}