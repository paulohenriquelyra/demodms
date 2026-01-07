# ============================================================================
# DMS Module Outputs - HashiCorp Standards Compliant
# ============================================================================
# This file provides structured outputs for the DMS module following HashiCorp
# best practices with logical grouping and comprehensive descriptions in English.
# Maintains backward compatibility with legacy output names.

####################################################
################# DMS INSTANCE ####################
####################################################

# Primary DMS instance information structured for module integration
output "dms_instance" {
  description = "Complete DMS replication instance information including ARN, ID, endpoint details, and configuration"
  value = {
    arn                = aws_dms_replication_instance.main.replication_instance_arn
    id                 = aws_dms_replication_instance.main.replication_instance_id
    engine_version     = aws_dms_replication_instance.main.engine_version
    instance_class     = aws_dms_replication_instance.main.replication_instance_class
    allocated_storage  = aws_dms_replication_instance.main.allocated_storage
    multi_az          = aws_dms_replication_instance.main.multi_az
    private_ips       = aws_dms_replication_instance.main.replication_instance_private_ips
    public_ips        = aws_dms_replication_instance.main.replication_instance_public_ips
    vpc_security_group_ids = aws_dms_replication_instance.main.vpc_security_group_ids
  }
}

####################################################
################# REPLICATION TASK ################
####################################################

# Replication task information for monitoring and management
output "replication_task" {
  description = "Complete replication task information including ARN, ID, status, and configuration details"
  value = {
    arn                = aws_dms_replication_task.main.replication_task_arn
    id                 = aws_dms_replication_task.main.replication_task_id
    migration_type     = aws_dms_replication_task.main.migration_type
    status            = aws_dms_replication_task.main.status
    table_mappings    = aws_dms_replication_task.main.table_mappings
    replication_task_settings = aws_dms_replication_task.main.replication_task_settings
  }
}

####################################################
################# DATABASE ENDPOINTS ##############
####################################################

# Database endpoints information for connection and monitoring
output "endpoints" {
  description = "Complete source and target endpoint information including ARNs, IDs, and connection details"
  value = {
    source = {
      arn         = aws_dms_endpoint.source.endpoint_arn
      id          = aws_dms_endpoint.source.endpoint_id
      engine_name = aws_dms_endpoint.source.engine_name
      server_name = aws_dms_endpoint.source.server_name
      port        = aws_dms_endpoint.source.port
      database_name = aws_dms_endpoint.source.database_name
      ssl_mode    = aws_dms_endpoint.source.ssl_mode
    }
    target = {
      arn         = aws_dms_endpoint.target.endpoint_arn
      id          = aws_dms_endpoint.target.endpoint_id
      engine_name = aws_dms_endpoint.target.engine_name
      server_name = aws_dms_endpoint.target.server_name
      port        = aws_dms_endpoint.target.port
      database_name = aws_dms_endpoint.target.database_name
      ssl_mode    = aws_dms_endpoint.target.ssl_mode
    }
  }
}

####################################################
################# NETWORK RESOURCES ###############
####################################################

# Network and security resources for infrastructure integration
output "network" {
  description = "Network infrastructure information including security groups, subnet groups, and VPC details"
  value = {
    security_group = {
      id   = aws_security_group.dms.id
      arn  = aws_security_group.dms.arn
      name = aws_security_group.dms.name
      vpc_id = aws_security_group.dms.vpc_id
    }
    subnet_group = {
      id                = aws_dms_replication_subnet_group.main.id
      subnet_group_name = aws_dms_replication_subnet_group.main.replication_subnet_group_id
      subnet_ids        = aws_dms_replication_subnet_group.main.subnet_ids
      vpc_id           = aws_dms_replication_subnet_group.main.vpc_id
    }
  }
}

####################################################
################# LEGACY COMPATIBILITY ############
####################################################

# Legacy outputs maintained for backward compatibility with existing deployments
# These outputs are deprecated and will be removed in future versions
# Please migrate to the structured outputs above

output "replication_instance_arn" {
  description = "ARN of the DMS replication instance (DEPRECATED: Use dms_instance.arn instead)"
  value       = aws_dms_replication_instance.main.replication_instance_arn
}

output "replication_instance_id" {
  description = "ID of the DMS replication instance (DEPRECATED: Use dms_instance.id instead)"
  value       = aws_dms_replication_instance.main.replication_instance_id
}

output "engine_version" {
  description = "DMS engine version (DEPRECATED: Use dms_instance.engine_version instead)"
  value       = aws_dms_replication_instance.main.engine_version
}

output "replication_task_arn" {
  description = "ARN of the replication task (DEPRECATED: Use replication_task.arn instead)"
  value       = aws_dms_replication_task.main.replication_task_arn
}

output "replication_task_id" {
  description = "ID of the replication task (DEPRECATED: Use replication_task.id instead)"
  value       = aws_dms_replication_task.main.replication_task_id
}

output "source_endpoint_arn" {
  description = "ARN of the source endpoint (DEPRECATED: Use endpoints.source.arn instead)"
  value       = aws_dms_endpoint.source.endpoint_arn
}

output "source_endpoint_id" {
  description = "ID of the source endpoint (DEPRECATED: Use endpoints.source.id instead)"
  value       = aws_dms_endpoint.source.endpoint_id
}

output "target_endpoint_arn" {
  description = "ARN of the target endpoint (DEPRECATED: Use endpoints.target.arn instead)"
  value       = aws_dms_endpoint.target.endpoint_arn
}

output "target_endpoint_id" {
  description = "ID of the target endpoint (DEPRECATED: Use endpoints.target.id instead)"
  value       = aws_dms_endpoint.target.endpoint_id
}

output "dms_security_group_id" {
  description = "ID of the DMS security group (DEPRECATED: Use network.security_group.id instead)"
  value       = aws_security_group.dms.id
}

output "dms_subnet_group_id" {
  description = "ID of the DMS subnet group (DEPRECATED: Use network.subnet_group.id instead)"
  value       = aws_dms_replication_subnet_group.main.id
}

# Additional legacy outputs for complete backward compatibility
output "dms_instance_arn" {
  description = "ARN of the DMS instance (LEGACY: Use dms_instance.arn instead)"
  value       = aws_dms_replication_instance.main.replication_instance_arn
}

output "dms_instance_id" {
  description = "ID of the DMS instance (LEGACY: Use dms_instance.id instead)"
  value       = aws_dms_replication_instance.main.replication_instance_id
}

output "dms_task_arn" {
  description = "ARN of the replication task (LEGACY: Use replication_task.arn instead)"
  value       = aws_dms_replication_task.main.replication_task_arn
}

output "dms_task_id" {
  description = "ID of the replication task (LEGACY: Use replication_task.id instead)"
  value       = aws_dms_replication_task.main.replication_task_id
}