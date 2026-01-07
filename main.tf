# ============================================================================
# AWS DMS Deployment - Production Ready Configuration
# ============================================================================
#
# Tech Leader Approved Pattern: Template substitution with environment variables
# This template is processed by deploy-cicd.sh to generate main.tf
#
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

provider "aws" {
  region = "{{AWS_REGION}}"

  default_tags {
    tags = {
      Environment = "{{ENVIRONMENT}}"
      Project     = "{{PROJECT_NAME}}"
      Owner       = "{{OWNER}}"
      CostCenter  = "{{COST_CENTER}}"
      ManagedBy   = "terraform"
      Terraform   = "true"
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

  project_name = "{{PROJECT_NAME}}"
  environment  = "{{ENVIRONMENT}}"
  owner        = "{{OWNER}}"
  cost_center  = "{{COST_CENTER}}"

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  vpc_id = "{{VPC_ID}}"
  subnet_ids = [
    "{{SUBNET_ID_1}}",
    "{{SUBNET_ID_2}}"
  ]

  # ============================================================================
  # ENDPOINT CONFIGURATION
  # ============================================================================

  enable_secrets_manager = "{{USE_SECRETS_MANAGER}}" == "true" ? true : false

  source_endpoint_config = {
    engine_name = "{{SOURCE_ENGINE}}"

    # Secrets Manager Configuration (produção)
    secrets_manager_arn             = "{{USE_SECRETS_MANAGER}}" == "true" ? "{{SOURCE_SECRETS_ARN}}" : ""
    secrets_manager_access_role_arn = "{{USE_SECRETS_MANAGER}}" == "true" ? "{{SOURCE_SECRETS_ROLE_ARN}}" : ""

    # Direct Credentials (desenvolvimento)
    server_name   = "{{SOURCE_DB_HOST}}"
    port          = {{SOURCE_DB_PORT}}
    username      = "{{USE_SECRETS_MANAGER}}" == "true" ? "" : "{{SOURCE_DB_USERNAME}}"
    password      = "{{USE_SECRETS_MANAGER}}" == "true" ? "" : "{{SOURCE_DB_PASSWORD}}"
    database_name = "{{SOURCE_DB_NAME}}"

    # Connection Security Settings
    ssl_mode                    = "{{ENVIRONMENT}}" == "production" ? "require" : "none"
    extra_connection_attributes = ""
  }

  target_endpoint_config = {
    engine_name = "{{TARGET_ENGINE}}"

    # Secrets Manager Configuration (produção)
    secrets_manager_arn             = "{{USE_SECRETS_MANAGER}}" == "true" ? "{{TARGET_SECRETS_ARN}}" : ""
    secrets_manager_access_role_arn = "{{USE_SECRETS_MANAGER}}" == "true" ? "{{TARGET_SECRETS_ROLE_ARN}}" : ""

    # Direct Credentials (desenvolvimento)
    server_name   = "{{TARGET_DB_HOST}}"
    port          = {{TARGET_DB_PORT}}
    username      = "{{USE_SECRETS_MANAGER}}" == "true" ? "" : "{{TARGET_DB_USERNAME}}"
    password      = "{{USE_SECRETS_MANAGER}}" == "true" ? "" : "{{TARGET_DB_PASSWORD}}"
    database_name = "{{TARGET_DB_NAME}}"

    # Connection Security Settings
    ssl_mode                    = "{{ENVIRONMENT}}" == "production" ? "require" : "none"
    extra_connection_attributes = ""
  }

  # ============================================================================
  # SECURITY CONFIGURATION
  # ============================================================================

  source_security_group_id = "{{SOURCE_SECURITY_GROUP_ID}}"
  target_security_group_id = "{{TARGET_SECURITY_GROUP_ID}}"
  kms_key_arn              = "{{KMS_KEY_ARN}}"

  security_config = {
    enforce_ssl                 = "{{ENVIRONMENT}}" == "production" ? true : false
    restrict_public_access      = true
    enable_detailed_monitoring  = "{{ENVIRONMENT}}" == "production" ? true : false
    enable_performance_insights = "{{ENVIRONMENT}}" == "production" ? true : false
    network_isolation_level     = "{{ENVIRONMENT}}" == "production" ? "strict" : "standard"
    require_kms_encryption      = "{{ENVIRONMENT}}" == "production" ? true : false
    enable_deletion_protection  = "{{ENVIRONMENT}}" == "production" ? true : false
  }

  multi_az_config = {
    enable_multi_az              = "{{ENVIRONMENT}}" == "production" ? true : false
    force_multi_az_production    = "{{ENVIRONMENT}}" == "production" ? true : false
    backup_retention_days        = "{{ENVIRONMENT}}" == "production" ? 30 : "{{ENVIRONMENT}}" == "staging" ? 7 : 1
    preferred_maintenance_window = "{{MAINTENANCE_WINDOW}}"
    auto_minor_version_upgrade   = true
  }

  # ============================================================================
  # DMS INSTANCE CONFIGURATION
  # ============================================================================

  dms_instance_config = {
    instance_class    = "{{ENVIRONMENT}}" == "production" ? "dms.r5.xlarge" : "{{ENVIRONMENT}}" == "staging" ? "dms.t3.large" : "dms.t3.micro"
    allocated_storage = "{{ENVIRONMENT}}" == "production" ? 500 : "{{ENVIRONMENT}}" == "staging" ? 100 : 20
    engine_version    = "{{DMS_ENGINE_VERSION}}"
    multi_az          = "{{ENVIRONMENT}}" == "production" ? true : false
  }

  # ============================================================================
  # MIGRATION CONFIGURATION
  # ============================================================================

  migration_type = "{{MIGRATION_TYPE}}"

  table_mappings = {
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = "{{SOURCE_SCHEMA_NAME}}"
          table-name  = "{{SOURCE_TABLE_PATTERN}}"
        }
        rule-action = "include"
      }
    ]
  }

  replication_task_settings = {
    TargetMetadata = {
      TargetSchema                 = "{{TARGET_SCHEMA_NAME}}"
      SupportLobs                  = true
      FullLobMode                  = false
      LobChunkSize                 = 0
      LimitedSizeLobMode           = true
      LobMaxSize                   = 32
      InlineLobMaxSize             = 0
      LoadMaxFileSize              = 0
      ParallelLoadThreads          = "{{ENVIRONMENT}}" == "production" ? 8 : 0
      ParallelLoadBufferSize       = "{{ENVIRONMENT}}" == "production" ? 1000 : 0
      BatchApplyEnabled            = "{{ENVIRONMENT}}" == "production" ? true : false
      TaskRecoveryTableEnabled     = "{{ENVIRONMENT}}" == "production" ? true : false
      ParallelApplyThreads         = "{{ENVIRONMENT}}" == "production" ? 4 : 0
      ParallelApplyBufferSize      = "{{ENVIRONMENT}}" == "production" ? 1000 : 0
      ParallelApplyQueuesPerThread = "{{ENVIRONMENT}}" == "production" ? 4 : 0
    }

    FullLoadSettings = {
      TargetTablePrepMode             = "DROP_AND_CREATE"
      CreatePkAfterFullLoad           = false
      StopTaskCachedChangesApplied    = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks             = "{{ENVIRONMENT}}" == "production" ? 8 : 4
      TransactionConsistencyTimeout   = 600
      CommitRate                      = "{{ENVIRONMENT}}" == "production" ? 50000 : 10000
    }

    Logging = {
      EnableLogging = true
      LogComponents = [
        {
          Id       = "TRANSFORMATION"
          Severity = "{{ENVIRONMENT}}" == "production" ? "LOGGER_SEVERITY_ERROR" : "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "SOURCE_UNLOAD"
          Severity = "{{ENVIRONMENT}}" == "production" ? "LOGGER_SEVERITY_ERROR" : "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "TARGET_LOAD"
          Severity = "{{ENVIRONMENT}}" == "production" ? "LOGGER_SEVERITY_ERROR" : "LOGGER_SEVERITY_DEFAULT"
        }
      ]
    }

    ControlTablesSettings = {
      historyTimeslotInMinutes    = 5
      ControlSchema               = ""
      HistoryTimeslotInMinutes    = 5
      HistoryTableEnabled         = "{{ENVIRONMENT}}" == "production" ? true : false
      SuspendedTablesTableEnabled = "{{ENVIRONMENT}}" == "production" ? true : false
      StatusTableEnabled          = "{{ENVIRONMENT}}" == "production" ? true : false
    }

    StreamBufferSettings = {
      StreamBufferCount        = "{{ENVIRONMENT}}" == "production" ? 6 : 3
      StreamBufferSizeInMB     = "{{ENVIRONMENT}}" == "production" ? 8 : 4
      CtrlStreamBufferSizeInMB = "{{ENVIRONMENT}}" == "production" ? 10 : 5
    }

    ChangeProcessingDdlHandlingPolicy = {
      HandleSourceTableDropped   = true
      HandleSourceTableTruncated = true
      HandleSourceTableAltered   = true
    }

    ErrorBehavior = {
      DataErrorPolicy                             = "LOG_ERROR"
      DataTruncationErrorPolicy                   = "LOG_ERROR"
      DataErrorEscalationPolicy                   = "{{ENVIRONMENT}}" == "production" ? "SUSPEND_TABLE" : "LOG_ERROR"
      DataErrorEscalationCount                    = 0
      TableErrorPolicy                            = "SUSPEND_TABLE"
      TableErrorEscalationPolicy                  = "{{ENVIRONMENT}}" == "production" ? "STOP_TASK" : "SUSPEND_TABLE"
      TableErrorEscalationCount                   = 0
      RecoverableErrorCount                       = -1
      RecoverableErrorInterval                    = 5
      RecoverableErrorThrottling                  = true
      RecoverableErrorThrottlingMax               = 1800
      RecoverableErrorStopRetryAfterThrottlingMax = true
      ApplyErrorDeletePolicy                      = "IGNORE_RECORD"
      ApplyErrorInsertPolicy                      = "LOG_ERROR"
      ApplyErrorUpdatePolicy                      = "LOG_ERROR"
      ApplyErrorEscalationPolicy                  = "LOG_ERROR"
      ApplyErrorEscalationCount                   = 0
      ApplyErrorFailOnTruncationDdl               = false
      FullLoadIgnoreConflicts                     = true
    }

    ChangeProcessingTuning = {
      BatchApplyPreserveTransaction = true
      BatchApplyTimeoutMin          = 1
      BatchApplyTimeoutMax          = 30
      BatchApplyMemoryLimit         = "{{ENVIRONMENT}}" == "production" ? 1000 : 500
      BatchSplitSize                = 0
      MinTransactionSize            = "{{ENVIRONMENT}}" == "production" ? 5000 : 1000
      CommitTimeout                 = 1
      MemoryLimitTotal              = "{{ENVIRONMENT}}" == "production" ? 2048 : 1024
      MemoryKeepTime                = 60
      StatementCacheSize            = "{{ENVIRONMENT}}" == "production" ? 100 : 50
    }
  }

  # ============================================================================
  # ENVIRONMENT CONFIGURATION
  # ============================================================================

  environment_config = {
    backup_retention_days = "{{ENVIRONMENT}}" == "production" ? 30 : "{{ENVIRONMENT}}" == "staging" ? 7 : 1
    monitoring_level     = "{{ENVIRONMENT}}" == "production" ? "enhanced" : "{{ENVIRONMENT}}" == "staging" ? "detailed" : "basic"
    performance_insights = "{{ENVIRONMENT}}" == "production" ? true : false
    deletion_protection  = "{{ENVIRONMENT}}" == "production" ? true : false
  }

  # ============================================================================
  # RESOURCE TAGGING
  # ============================================================================

  tags = {
    Project     = "{{PROJECT_NAME}}"
    Environment = "{{ENVIRONMENT}}"
    Owner       = "{{OWNER}}"
    CostCenter  = "{{COST_CENTER}}"
    Version     = "1.0.0"
    Backup      = "required"
    Monitoring  = "enabled"
  }
}