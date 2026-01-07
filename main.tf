# ============================================================================
# AWS DMS Deployment - Local Test Configuration
# ============================================================================
#
# Este arquivo foi gerado automaticamente para testes locais
# Contém valores de exemplo para validação da estrutura
#
# ATENÇÃO: Não use em produção - valores são fictícios
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
# DMS MODULE DEPLOYMENT - LOCAL TEST
# ============================================================================

module "dms" {
  source = "./modules/dms"

  # ============================================================================
  # CORE PROJECT CONFIGURATION
  # ============================================================================

  project_name = "test-dms-local"
  environment  = "development"

  # ============================================================================
  # NETWORK CONFIGURATION
  # ============================================================================

  vpc_id = "vpc-0123456789abcdef0"
  subnet_ids = [
    "subnet-0123456789abcdef0",
    "subnet-0fedcba9876543210"
  ]

  # ============================================================================
  # SOURCE ENDPOINT CONFIGURATION
  # ============================================================================

  source_endpoint_config = {
    engine_name = "mysql"

    # Direct Credential Configuration (for testing)
    secrets_manager_arn             = ""
    secrets_manager_access_role_arn = ""

    server_name   = "test-source.example.com"
    port          = 3306
    username      = "test_user"
    password      = "test_password"
    database_name = "test_source_db"

    # Connection Security Settings
    ssl_mode                    = "none"
    extra_connection_attributes = ""
  }

  # ============================================================================
  # TARGET ENDPOINT CONFIGURATION
  # ============================================================================

  target_endpoint_config = {
    engine_name = "postgres"

    # Direct Credential Configuration (for testing)
    secrets_manager_arn             = ""
    secrets_manager_access_role_arn = ""

    server_name   = "test-target.example.com"
    port          = 5432
    username      = "test_user"
    password      = "test_password"
    database_name = "test_target_db"

    # Connection Security Settings
    ssl_mode                    = "none"
    extra_connection_attributes = ""
  }

  # ============================================================================
  # SECURITY CONFIGURATION
  # ============================================================================

  # Credential Management
  enable_secrets_manager = false

  # Security Groups
  source_security_group_id = "sg-0123456789abcdef0"
  target_security_group_id = "sg-0fedcba9876543210"

  # Encryption
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # ============================================================================
  # DMS INSTANCE CONFIGURATION
  # ============================================================================

  dms_instance_config = {
    instance_class    = "dms.t3.micro"
    allocated_storage = 20
    engine_version    = "3.5.2"
    multi_az          = false
  }

  # ============================================================================
  # MIGRATION CONFIGURATION
  # ============================================================================

  migration_type = "full-load-and-cdc"

  table_mappings = {
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = "%"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  }

  replication_task_settings = {
    TargetMetadata = {
      TargetSchema                 = "public"
      SupportLobs                  = true
      FullLobMode                  = false
      LobChunkSize                 = 0
      LimitedSizeLobMode           = true
      LobMaxSize                   = 32
      InlineLobMaxSize             = 0
      LoadMaxFileSize              = 0
      ParallelLoadThreads          = 0
      ParallelLoadBufferSize       = 0
      BatchApplyEnabled            = false
      TaskRecoveryTableEnabled     = false
      ParallelApplyThreads         = 0
      ParallelApplyBufferSize      = 0
      ParallelApplyQueuesPerThread = 0
    }

    FullLoadSettings = {
      TargetTablePrepMode             = "DROP_AND_CREATE"
      CreatePkAfterFullLoad           = false
      StopTaskCachedChangesApplied    = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks             = 4
      TransactionConsistencyTimeout   = 600
      CommitRate                      = 10000
    }

    Logging = {
      EnableLogging = true
      LogComponents = [
        {
          Id       = "TRANSFORMATION"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "SOURCE_UNLOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        },
        {
          Id       = "TARGET_LOAD"
          Severity = "LOGGER_SEVERITY_DEFAULT"
        }
      ]
    }

    ControlTablesSettings = {
      historyTimeslotInMinutes    = 5
      ControlSchema               = ""
      HistoryTimeslotInMinutes    = 5
      HistoryTableEnabled         = false
      SuspendedTablesTableEnabled = false
      StatusTableEnabled          = false
    }

    StreamBufferSettings = {
      StreamBufferCount        = 3
      StreamBufferSizeInMB     = 4
      CtrlStreamBufferSizeInMB = 5
    }

    ChangeProcessingDdlHandlingPolicy = {
      HandleSourceTableDropped   = true
      HandleSourceTableTruncated = true
      HandleSourceTableAltered   = true
    }

    ErrorBehavior = {
      DataErrorPolicy                             = "LOG_ERROR"
      DataTruncationErrorPolicy                   = "LOG_ERROR"
      DataErrorEscalationPolicy                   = "SUSPEND_TABLE"
      DataErrorEscalationCount                    = 0
      TableErrorPolicy                            = "SUSPEND_TABLE"
      TableErrorEscalationPolicy                  = "STOP_TASK"
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
      BatchApplyMemoryLimit         = 500
      BatchSplitSize                = 0
      MinTransactionSize            = 1000
      CommitTimeout                 = 1
      MemoryLimitTotal              = 1024
      MemoryKeepTime                = 60
      StatementCacheSize            = 50
    }
  }

  # ============================================================================
  # SECURITY AND COMPLIANCE CONFIGURATION
  # ============================================================================

  security_config = {
    enforce_ssl                 = false
    restrict_public_access      = true
    enable_detailed_monitoring  = false
    enable_performance_insights = false
    network_isolation_level     = "standard"
    require_kms_encryption      = false
    enable_deletion_protection  = false
  }

  # ============================================================================
  # MULTI-AZ AND OPERATIONAL CONFIGURATION
  # ============================================================================

  multi_az_config = {
    enable_multi_az              = false
    force_multi_az_production    = false
    backup_retention_days        = 1
    preferred_maintenance_window = "sun:03:00-sun:04:00"
    auto_minor_version_upgrade   = true
  }

  # ============================================================================
  # RESOURCE TAGGING
  # ============================================================================

  tags = {
    Project     = "test-dms-local"
    Environment = "development"
    Owner       = "test-team"
    CostCenter  = "testing"
    Terraform   = "true"
    CreatedBy   = "local-test"
    Purpose     = "validation"
  }
}
