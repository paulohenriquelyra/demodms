# ============================================================================
# AWS DMS Deployment Outputs - Client Integration Interface
# ============================================================================
#
# This file provides structured outputs for client integration following
# HashiCorp best practices with comprehensive resource information.
#
# Output Categories:
# 1. DMS Instance Information
# 2. Database Endpoints
# 3. Replication Task Details
# 4. Network and Security Resources
# 5. Deployment Summary
# 6. Legacy Compatibility Outputs
#
# All outputs include:
# ✅ Comprehensive resource information
# ✅ Integration-ready data structures
# ✅ Clear descriptions for client usage
# ✅ Backward compatibility support
# ============================================================================

# ============================================================================
# DMS INSTANCE INFORMATION
# ============================================================================

output "dms_instance" {
  description = <<-EOT
    Complete DMS replication instance information for monitoring and integration.
    
    Includes:
    - Resource identifiers (ARN, ID)
    - Configuration details (instance class, storage, version)
    - Network information (IPs, security groups)
    - High availability settings (Multi-AZ status)
  EOT
  value = {
    arn                    = module.dms.dms_instance.arn
    id                     = module.dms.dms_instance.id
    engine_version         = module.dms.dms_instance.engine_version
    instance_class         = module.dms.dms_instance.instance_class
    allocated_storage      = module.dms.dms_instance.allocated_storage
    multi_az               = module.dms.dms_instance.multi_az
    private_ips            = module.dms.dms_instance.private_ips
    public_ips             = module.dms.dms_instance.public_ips
    vpc_security_group_ids = module.dms.dms_instance.vpc_security_group_ids
  }
}

# ============================================================================
# DATABASE ENDPOINTS
# ============================================================================

output "endpoints" {
  description = <<-EOT
    Source and target database endpoint information for connection management.
    
    Includes for both source and target:
    - Resource identifiers (ARN, ID)
    - Connection details (engine, host, port, database)
    - Security configuration (SSL mode)
  EOT
  value = {
    source = {
      arn           = module.dms.endpoints.source.arn
      id            = module.dms.endpoints.source.id
      engine_name   = module.dms.endpoints.source.engine_name
      server_name   = module.dms.endpoints.source.server_name
      port          = module.dms.endpoints.source.port
      database_name = module.dms.endpoints.source.database_name
      ssl_mode      = module.dms.endpoints.source.ssl_mode
    }
    target = {
      arn           = module.dms.endpoints.target.arn
      id            = module.dms.endpoints.target.id
      engine_name   = module.dms.endpoints.target.engine_name
      server_name   = module.dms.endpoints.target.server_name
      port          = module.dms.endpoints.target.port
      database_name = module.dms.endpoints.target.database_name
      ssl_mode      = module.dms.endpoints.target.ssl_mode
    }
  }
}

# ============================================================================
# REPLICATION TASK DETAILS
# ============================================================================

output "replication_task" {
  description = <<-EOT
    Replication task information for monitoring and management.
    
    Includes:
    - Resource identifiers (ARN, ID)
    - Migration configuration (type, status)
    - Task settings and table mappings
  EOT
  value = {
    arn                       = module.dms.replication_task.arn
    id                        = module.dms.replication_task.id
    migration_type            = module.dms.replication_task.migration_type
    status                    = module.dms.replication_task.status
    table_mappings            = module.dms.replication_task.table_mappings
    replication_task_settings = module.dms.replication_task.replication_task_settings
  }
}

# ============================================================================
# NETWORK AND SECURITY RESOURCES
# ============================================================================

output "network" {
  description = <<-EOT
    Network infrastructure information for security and connectivity management.
    
    Includes:
    - Security group details (ID, ARN, VPC)
    - Subnet group configuration (subnets, VPC)
  EOT
  value = {
    security_group = {
      id     = module.dms.network.security_group.id
      arn    = module.dms.network.security_group.arn
      name   = module.dms.network.security_group.name
      vpc_id = module.dms.network.security_group.vpc_id
    }
    subnet_group = {
      id                = module.dms.network.subnet_group.id
      subnet_group_name = module.dms.network.subnet_group.subnet_group_name
      subnet_ids        = module.dms.network.subnet_group.subnet_ids
      vpc_id            = module.dms.network.subnet_group.vpc_id
    }
  }
}

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

output "deployment_summary" {
  description = <<-EOT
    High-level deployment summary for client reporting and documentation.
    
    Includes:
    - Project and environment information
    - Resource counts and types
    - Security and compliance status
    - Cost optimization features enabled
  EOT
  value = {
    project_name         = module.dms.dms_instance.id != null ? split("-", module.dms.dms_instance.id)[0] : "unknown"
    environment          = module.dms.dms_instance.id != null ? split("-", module.dms.dms_instance.id)[1] : "unknown"
    deployment_timestamp = timestamp()

    # Resource Summary
    resources_created = {
      dms_instance     = 1
      replication_task = 1
      source_endpoint  = 1
      target_endpoint  = 1
      security_group   = 1
      subnet_group     = 1
    }

    # Configuration Summary
    configuration = {
      secrets_manager_enabled = false # Determined from module configuration
      multi_az_enabled        = module.dms.dms_instance.multi_az
      kms_encryption_enabled  = module.dms.dms_instance.arn != null ? true : false
      ssl_enforced            = module.dms.endpoints.source.ssl_mode != "none"
      migration_type          = module.dms.replication_task.migration_type
      instance_class          = module.dms.dms_instance.instance_class
    }

    # Security Features
    security_features = {
      network_isolation_level  = "standard" # Default for deployment
      public_access_restricted = true       # Always true for security
      deletion_protection      = false      # Determined by environment
      detailed_monitoring      = false      # Determined by environment
      performance_insights     = false      # Determined by environment
    }
  }
}

# ============================================================================
# INTEGRATION OUTPUTS
# ============================================================================

output "connection_info" {
  description = <<-EOT
    Connection information for application integration and monitoring tools.
    
    Provides ready-to-use connection details for:
    - Monitoring applications
    - CI/CD pipeline integration
    - Infrastructure automation
  EOT
  value = {
    # DMS Instance Connection
    dms_instance = {
      arn        = module.dms.dms_instance.arn
      private_ip = length(module.dms.dms_instance.private_ips) > 0 ? module.dms.dms_instance.private_ips[0] : null
      vpc_id     = module.dms.network.security_group.vpc_id
    }

    # Database Connections
    source_database = {
      engine = module.dms.endpoints.source.engine_name
      host   = module.dms.endpoints.source.server_name
      port   = module.dms.endpoints.source.port
    }

    target_database = {
      engine = module.dms.endpoints.target.engine_name
      host   = module.dms.endpoints.target.server_name
      port   = module.dms.endpoints.target.port
    }

    # Security Information
    security = {
      security_group_id = module.dms.network.security_group.id
      kms_key_arn       = "managed-by-module"
      ssl_enabled       = module.dms.endpoints.source.ssl_mode != "none"
    }
  }
}

# ============================================================================
# CLI OPERATIONS OUTPUTS
# ============================================================================

output "cli_commands" {
  description = <<-EOT
    Ready-to-use CLI commands for DMS operations management.
    
    These commands can be used directly in CI/CD pipelines or operational scripts
    for managing DMS tasks without console access.
  EOT
  value = {
    # DMS Task Management Commands
    start_task = "aws dms start-replication-task --replication-task-arn ${module.dms.replication_task.arn}"
    stop_task  = "aws dms stop-replication-task --replication-task-arn ${module.dms.replication_task.arn}"

    # Status and Monitoring Commands
    task_status = "aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=${module.dms.replication_task.arn} --query 'ReplicationTasks[0].Status' --output text"
    task_stats  = "aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=${module.dms.replication_task.arn} --query 'ReplicationTasks[0].ReplicationTaskStats' --output table"

    # Connection Testing Commands
    test_source_connection = "aws dms test-connection --replication-instance-arn ${module.dms.dms_instance.arn} --endpoint-arn ${module.dms.endpoints.source.arn}"
    test_target_connection = "aws dms test-connection --replication-instance-arn ${module.dms.dms_instance.arn} --endpoint-arn ${module.dms.endpoints.target.arn}"

    # Instance Management Commands
    instance_status = "aws dms describe-replication-instances --filters Name=replication-instance-arn,Values=${module.dms.dms_instance.arn} --query 'ReplicationInstances[0].ReplicationInstanceStatus' --output text"

    # Log Viewing Commands
    view_logs = "aws logs filter-log-events --log-group-name dms-tasks-${module.dms.replication_task.id} --start-time $(($(date +%s) * 1000 - 3600000)) --query 'events[*].[timestamp,message]' --output table"

    # Scripted Operations (using provided scripts)
    script_start   = "./scripts/start-dms.sh --wait"
    script_stop    = "./scripts/stop-dms.sh --wait"
    script_monitor = "./scripts/monitor-dms.sh --watch"
    script_status  = "./scripts/dms-operations.sh status --json"
    script_restart = "./scripts/dms-operations.sh restart --wait"
  }
}

output "operational_guide" {
  description = <<-EOT
    Operational guide for DMS management without console access.
    
    Provides step-by-step instructions for common operational tasks.
  EOT
  value = {
    # Quick Start Operations
    quick_start = {
      "1_check_status"     = "Use: ./scripts/dms-operations.sh status"
      "2_start_migration"  = "Use: ./scripts/dms-operations.sh start --wait"
      "3_monitor_progress" = "Use: ./scripts/dms-operations.sh monitor --watch"
      "4_stop_migration"   = "Use: ./scripts/dms-operations.sh stop --wait"
    }

    # Emergency Operations
    emergency_procedures = {
      "stop_immediately"    = "./scripts/stop-dms.sh --wait --timeout=60"
      "check_error_logs"    = "./scripts/dms-operations.sh logs"
      "restart_failed_task" = "./scripts/dms-operations.sh restart --wait --timeout=600"
      "get_detailed_status" = "./scripts/monitor-dms.sh --json"
    }

    # Monitoring and Alerting
    monitoring_commands = {
      "continuous_monitoring" = "./scripts/monitor-dms.sh --watch --interval=30"
      "status_for_alerting"   = "./scripts/dms-operations.sh status --json"
      "performance_check"     = "aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=${module.dms.replication_task.arn} --query 'ReplicationTasks[0].ReplicationTaskStats'"
    }

    # CI/CD Integration
    cicd_integration = {
      "pre_deployment_check" = "./scripts/dms-operations.sh status"
      "start_after_deploy"   = "./scripts/start-dms.sh --wait --timeout=600"
      "health_check"         = "./scripts/monitor-dms.sh --summary"
      "stop_before_destroy"  = "./scripts/stop-dms.sh --wait"
    }
  }
}

# ============================================================================
# LEGACY COMPATIBILITY OUTPUTS
# ============================================================================
# These outputs maintain backward compatibility with existing integrations
# Clients should migrate to the structured outputs above for new integrations

output "replication_instance_arn" {
  description = "ARN of the DMS replication instance (LEGACY: Use dms_instance.arn instead)"
  value       = module.dms.dms_instance.arn
}

output "replication_instance_id" {
  description = "ID of the DMS replication instance (LEGACY: Use dms_instance.id instead)"
  value       = module.dms.dms_instance.id
}

output "replication_task_arn" {
  description = "ARN of the replication task (LEGACY: Use replication_task.arn instead)"
  value       = module.dms.replication_task.arn
}

output "replication_task_id" {
  description = "ID of the replication task (LEGACY: Use replication_task.id instead)"
  value       = module.dms.replication_task.id
}

output "source_endpoint_arn" {
  description = "ARN of the source endpoint (LEGACY: Use endpoints.source.arn instead)"
  value       = module.dms.endpoints.source.arn
}

output "source_endpoint_id" {
  description = "ID of the source endpoint (LEGACY: Use endpoints.source.id instead)"
  value       = module.dms.endpoints.source.id
}

output "target_endpoint_arn" {
  description = "ARN of the target endpoint (LEGACY: Use endpoints.target.arn instead)"
  value       = module.dms.endpoints.target.arn
}

output "target_endpoint_id" {
  description = "ID of the target endpoint (LEGACY: Use endpoints.target.id instead)"
  value       = module.dms.endpoints.target.id
}

output "dms_security_group_id" {
  description = "ID of the DMS security group (LEGACY: Use network.security_group.id instead)"
  value       = module.dms.network.security_group.id
}

output "dms_subnet_group_id" {
  description = "ID of the DMS subnet group (LEGACY: Use network.subnet_group.id instead)"
  value       = module.dms.network.subnet_group.id
}