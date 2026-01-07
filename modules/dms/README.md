# AWS DMS Terraform Module

## Overview

This Terraform module provides a complete **AWS Database Migration Service (DMS)** solution following AWS Well-Architected Framework principles and HashiCorp best practices. The module implements enterprise-grade database migration capabilities with intelligent environment-based configuration, comprehensive security controls, cost optimization features, and **CI/CD-ready deployment patterns**.

> **🚀 CI/CD Ready**: This module supports both traditional Terraform workflows and modern CI/CD pipeline integration with inline variable substitution patterns approved by tech leadership.

## Features

- **🚀 CI/CD Integration**: Ready-to-use deployment patterns with inline variable substitution for modern pipelines
- **📦 Dual Usage Patterns**: Support for both traditional Terraform modules and CI/CD template-based deployments
- **🔧 Tech Leader Approved**: Follows established patterns for enterprise CI/CD workflows
- **🌍 Multi-Environment Support**: Automatic configuration optimization for `dev`, `staging`, `prod`, `test`, `ti`, and `trg` environments
- **🏗️ AWS Well-Architected Compliance**: Full implementation of all 5 pillars (Security, Reliability, Performance, Cost, Operational Excellence)
- **🔒 Intelligent Security**: Environment-based security posture with automatic SSL, KMS, and Multi-AZ configuration
- **💰 Cost Optimization**: Automatic feature enablement/disablement based on environment to optimize costs
- **🔑 Flexible Credential Management**: Support for both AWS Secrets Manager and direct credentials
- **📊 Comprehensive Monitoring**: CloudWatch integration with optional Performance Insights
- **🛡️ Network Security**: Configurable isolation levels (strict, standard, basic)
- **⚙️ Centralized Configuration**: Single source of truth for all computed values and tags
- **🖥️ CLI Operations**: Complete AWS CLI scripts for DMS operations without console access

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS VPC (Private Subnets)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   AZ-A (Private) │    │   AZ-B (Private) │    │   AZ-C (Private) │ │
│  │                 │    │                 │    │                 │ │
│  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │ │
│  │  │  Source   │  │    │  │    DMS    │  │    │  │  Target   │  │ │
│  │  │ Database  │◄─┼────┼─►│ Instance  │◄─┼────┼─►│ Database  │  │ │
│  │  │  (MySQL)  │  │    │  │           │  │    │  │(Aurora PG)│  │ │
│  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│                                                                   │
│  🔒 Security Groups: Least privilege network access              │
│  🔐 KMS Encryption: Customer-managed keys for data at rest       │
│  🔑 Secrets Manager: Secure credential management with rotation  │
│  📊 CloudWatch: Comprehensive monitoring and Performance Insights│
└─────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 🚀 CI/CD Pipeline Usage (Recommended)

For modern CI/CD pipelines, use the parent directory's deployment scripts that implement the tech leader approved pattern:

```bash
# Set environment variables in your CI/CD pipeline
export PROJECT_NAME="my-migration"
export ENVIRONMENT="production"
export VPC_ID="vpc-12345678"
export SUBNET_ID_1="subnet-12345678"
export SUBNET_ID_2="subnet-87654321"
# ... other variables

# Deploy using the CI/CD script
./scripts/deploy-cicd.sh production
```

The deployment script automatically:
- ✅ Substitutes variables into the main.tf template
- ✅ Validates Terraform configuration
- ✅ Applies infrastructure changes
- ✅ Provides structured outputs for integration

### 📦 Traditional Module Usage

For traditional Terraform workflows, use the module directly:

```hcl
module "dms" {
  source = "./modules/dms"
  
  # Required Configuration
  project_name = "my-migration"
  environment  = "dev"
  
  # Network Configuration
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]
  
  # Source Database (MySQL with Secrets Manager)
  source_endpoint_config = {
    engine_name                     = "mysql"
    secrets_manager_arn             = aws_secretsmanager_secret.mysql.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    ssl_mode                        = "none"
    extra_connection_attributes     = "initstmt=SET FOREIGN_KEY_CHECKS=0"
  }
  
  # Target Database (Aurora PostgreSQL with Secrets Manager)
  target_endpoint_config = {
    engine_name                     = "aurora-postgresql"
    secrets_manager_arn             = aws_secretsmanager_secret.aurora.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    database_name                   = "targetdb"
    ssl_mode                        = "require"
  }
  
  # Security Configuration
  source_security_group_id = aws_security_group.mysql.id
  target_security_group_id = aws_security_group.aurora.id
  kms_key_arn              = aws_kms_key.dms.arn
}
```

### Multi-Environment Examples

#### 🚀 CI/CD Pipeline Deployment

```bash
# Development Environment
export PROJECT_NAME="app-migration"
export ENVIRONMENT="development"
export VPC_ID="vpc-dev123"
export SUBNET_ID_1="subnet-dev1"
export SUBNET_ID_2="subnet-dev2"
export SOURCE_ENGINE="mysql"
export SOURCE_DB_HOST="dev-mysql.example.com"
export TARGET_ENGINE="postgres"
export TARGET_DB_HOST="dev-postgres.example.com"
export USE_SECRETS_MANAGER="false"
# ... other dev variables

./scripts/deploy-cicd.sh development

# Production Environment
export PROJECT_NAME="app-migration"
export ENVIRONMENT="production"
export VPC_ID="vpc-prod123"
export SUBNET_ID_1="subnet-prod1"
export SUBNET_ID_2="subnet-prod2"
export SOURCE_ENGINE="mysql"
export TARGET_ENGINE="aurora-postgresql"
export USE_SECRETS_MANAGER="true"
export SOURCE_SECRETS_ARN="arn:aws:secretsmanager:..."
export TARGET_SECRETS_ARN="arn:aws:secretsmanager:..."
# ... other prod variables

./scripts/deploy-cicd.sh production
```

#### 📦 Traditional Module Usage

#### Development Environment
```hcl
module "dms_dev" {
  source = "./modules/dms"
  
  project_name = "app-migration"
  environment  = "dev"  # Automatic cost optimization
  
  # Cost-optimized configuration (automatic)
  # - dms.t3.micro instance
  # - Single-AZ deployment
  # - Basic monitoring
  # - Optional KMS encryption
  # - No Performance Insights
  
  # Direct credentials (no Secrets Manager for dev)
  enable_secrets_manager = false
  
  source_endpoint_config = {
    engine_name = "mysql"
    server_name = "dev-mysql.example.com"
    port        = 3306
    username    = "dev_user"
    password    = "dev_password"
    ssl_mode    = "none"
  }
  
  target_endpoint_config = {
    engine_name   = "aurora-postgresql"
    server_name   = "dev-aurora.cluster-xyz.us-east-1.rds.amazonaws.com"
    port          = 5432
    username      = "dev_user"
    password      = "dev_password"
    database_name = "dev_db"
    ssl_mode      = "none"
  }
  
  # Other required parameters...
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  source_security_group_id = aws_security_group.mysql.id
  target_security_group_id = aws_security_group.aurora.id
  kms_key_arn              = aws_kms_key.dms.arn
}
```

#### Production Environment
```hcl
module "dms_prod" {
  source = "./modules/dms"
  
  project_name = "app-migration"
  environment  = "production"  # Automatic enterprise configuration
  
  # Production-grade configuration (automatic)
  # - Multi-AZ deployment (forced)
  # - Enhanced monitoring enabled
  # - Performance Insights enabled
  # - KMS encryption required
  # - SSL enforcement
  # - Deletion protection enabled
  
  # Production DMS instance configuration
  dms_instance_config = {
    instance_class    = "dms.r5.xlarge"
    allocated_storage = 200
    engine_version    = "3.5.3"
    multi_az         = true
  }
  
  # Enhanced security (automatic for production)
  security_config = {
    enforce_ssl                 = true
    enable_detailed_monitoring  = true
    enable_performance_insights = true
    network_isolation_level     = "strict"
    require_kms_encryption      = true
    enable_deletion_protection  = true
  }
  
  # Secrets Manager (recommended for production)
  enable_secrets_manager = true
  
  source_endpoint_config = {
    engine_name                     = "mysql"
    secrets_manager_arn             = aws_secretsmanager_secret.mysql.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    ssl_mode                        = "require"
  }
  
  target_endpoint_config = {
    engine_name                     = "aurora-postgresql"
    secrets_manager_arn             = aws_secretsmanager_secret.aurora.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    database_name                   = "production_db"
    ssl_mode                        = "require"
  }
  
  # Other required parameters...
  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  source_security_group_id = aws_security_group.mysql.id
  target_security_group_id = aws_security_group.aurora.id
  kms_key_arn              = aws_kms_key.dms.arn
}
```

## 🚀 CI/CD Integration

### Deployment Scripts

The module includes production-ready deployment scripts:

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/deploy-cicd.sh` | Main deployment script for CI/CD pipelines | `./scripts/deploy-cicd.sh <environment>` |
| `scripts/local-test.sh` | Local testing without AWS resources | `./scripts/local-test.sh --validate-only` |
| `scripts/quick-test.sh` | Quick syntax validation | `./scripts/quick-test.sh` |

### DMS Operations Scripts

Complete AWS CLI integration for console-free operations:

| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/dms-operations.sh` | Main operations script | `./scripts/dms-operations.sh status` |
| `scripts/start-dms.sh` | Start DMS replication task | `./scripts/start-dms.sh --wait` |
| `scripts/stop-dms.sh` | Stop DMS replication task | `./scripts/stop-dms.sh --wait` |
| `scripts/monitor-dms.sh` | Monitor DMS task progress | `./scripts/monitor-dms.sh --watch` |

### CI/CD Environment Variables

Required environment variables for CI/CD deployment:

```bash
# Core Configuration
export PROJECT_NAME="your-project"
export ENVIRONMENT="development|staging|production"
export VPC_ID="vpc-xxxxxxxxx"
export SUBNET_ID_1="subnet-xxxxxxxxx"
export SUBNET_ID_2="subnet-yyyyyyyyy"

# Security Configuration
export SOURCE_SECURITY_GROUP_ID="sg-xxxxxxxxx"
export TARGET_SECURITY_GROUP_ID="sg-yyyyyyyyy"
export KMS_KEY_ARN="arn:aws:kms:region:account:key/key-id"

# Database Configuration
export SOURCE_ENGINE="mysql|postgres|oracle|..."
export SOURCE_DB_HOST="source.example.com"
export SOURCE_DB_PORT="3306"
export SOURCE_DB_NAME="source_db"
export TARGET_ENGINE="postgres|aurora-postgresql|..."
export TARGET_DB_HOST="target.example.com"
export TARGET_DB_PORT="5432"
export TARGET_DB_NAME="target_db"

# Credential Management
export USE_SECRETS_MANAGER="true|false"
# If USE_SECRETS_MANAGER=true:
export SOURCE_SECRETS_ARN="arn:aws:secretsmanager:..."
export SOURCE_SECRETS_ROLE_ARN="arn:aws:iam:..."
export TARGET_SECRETS_ARN="arn:aws:secretsmanager:..."
export TARGET_SECRETS_ROLE_ARN="arn:aws:iam:..."
# If USE_SECRETS_MANAGER=false:
export SOURCE_DB_USERNAME="username"
export SOURCE_DB_PASSWORD="password"
export TARGET_DB_USERNAME="username"
export TARGET_DB_PASSWORD="password"

# Migration Configuration
export MIGRATION_TYPE="full-load|cdc|full-load-and-cdc"
export SOURCE_SCHEMA_NAME="%"
export SOURCE_TABLE_PATTERN="%"
export TARGET_SCHEMA_NAME="public"

# Optional Configuration
export DMS_ENGINE_VERSION="3.5.3"
export MAINTENANCE_WINDOW="sun:03:00-sun:04:00"
export OWNER="team-name"
export COST_CENTER="cost-center"
```

### Pipeline Integration Examples

#### GitLab CI/CD
```yaml
deploy_dms:
  stage: deploy
  script:
    - export PROJECT_NAME="$CI_PROJECT_NAME"
    - export ENVIRONMENT="$CI_ENVIRONMENT_NAME"
    - export VPC_ID="$VPC_ID"
    # ... set other variables from CI/CD variables
    - ./scripts/deploy-cicd.sh $ENVIRONMENT
  only:
    - main
    - develop
```

#### GitHub Actions
```yaml
- name: Deploy DMS
  env:
    PROJECT_NAME: ${{ github.event.repository.name }}
    ENVIRONMENT: ${{ github.ref_name }}
    VPC_ID: ${{ secrets.VPC_ID }}
    # ... other secrets
  run: |
    ./scripts/deploy-cicd.sh $ENVIRONMENT
```

#### Azure DevOps
```yaml
- script: |
    export PROJECT_NAME="$(Build.Repository.Name)"
    export ENVIRONMENT="$(Build.SourceBranchName)"
    export VPC_ID="$(VPC_ID)"
    # ... other variables
    ./scripts/deploy-cicd.sh $ENVIRONMENT
  displayName: 'Deploy DMS Infrastructure'
```

## Environment-Based Configuration

The module automatically optimizes configuration based on the environment:

| Environment | Multi-AZ | Performance Insights | Detailed Monitoring | KMS Encryption | Deletion Protection | SSL Enforcement |
|-------------|----------|---------------------|-------------------|----------------|-------------------|-----------------|
| `dev`, `development` | ❌ Disabled | ❌ Disabled | ❌ Disabled | ⚠️ Optional | ❌ Disabled | ⚠️ Optional |
| `test` | ❌ Disabled | ❌ Disabled | ✅ Enabled | ✅ Required | ❌ Disabled | ⚠️ Optional |
| `stage`, `staging` | ⚠️ Optional | ⚠️ Optional | ✅ Enabled | ✅ Required | ⚠️ Optional | ✅ Recommended |
| `ti` | ❌ Disabled | ❌ Disabled | ✅ Enabled | ✅ Required | ❌ Disabled | ✅ Recommended |
| `trg` | ❌ Disabled | ❌ Disabled | ⚠️ Optional | ⚠️ Optional | ❌ Disabled | ⚠️ Optional |
| `prod`, `production` | ✅ **Forced** | ✅ **Enabled** | ✅ **Enabled** | ✅ **Required** | ✅ **Enabled** | ✅ **Required** |

## 🧪 Testing and Validation

### Testing Levels

The module includes comprehensive testing capabilities:

| Level | Description | Cost | Command |
|-------|-------------|------|---------|
| **1. Syntax Validation** | Terraform syntax and formatting | Free | `./scripts/local-test.sh --validate-only` |
| **2. Template Validation** | Variable substitution testing | Free | `./scripts/quick-test.sh` |
| **3. Plan Validation** | Terraform plan generation | Free | `terraform plan` |
| **4. Minimal Testing** | Basic AWS resource validation | Low | With real AWS resources |
| **5. Full Testing** | Complete deployment testing | Medium | Full production-like setup |

### Local Testing

```bash
# Quick syntax validation (no AWS resources needed)
./scripts/local-test.sh --validate-only

# Test with fictional AWS resources
./scripts/local-test.sh

# Test CI/CD variable substitution
./scripts/quick-test.sh
```

### Production Readiness Checklist

- [ ] All environment variables configured
- [ ] AWS credentials and permissions validated
- [ ] VPC and subnet IDs verified
- [ ] Security groups configured with proper rules
- [ ] KMS key created and accessible
- [ ] Secrets Manager secrets created (if using)
- [ ] Database endpoints accessible from DMS subnets
- [ ] Syntax validation passed
- [ ] Terraform plan reviewed
- [ ] Cost estimation completed

## 🖥️ Console-Free Operations

### DMS Operations Without AWS Console

Complete AWS CLI integration for environments where console access is restricted:

```bash
# Check DMS task status
./scripts/dms-operations.sh status

# Start migration with monitoring
./scripts/dms-operations.sh start --wait --timeout=600

# Monitor progress continuously
./scripts/dms-operations.sh monitor --watch --interval=30

# Stop migration gracefully
./scripts/dms-operations.sh stop --wait

# Get detailed status in JSON format
./scripts/dms-operations.sh status --json

# View recent logs
./scripts/dms-operations.sh logs

# Restart failed task
./scripts/dms-operations.sh restart --wait
```

### Emergency Operations

```bash
# Emergency stop (immediate)
./scripts/stop-dms.sh --wait --timeout=60

# Check error logs
./scripts/dms-operations.sh logs --error

# Get detailed diagnostics
./scripts/monitor-dms.sh --json --detailed

# Restart with extended timeout
./scripts/dms-operations.sh restart --wait --timeout=900
```

### CI/CD Integration Commands

```bash
# Pre-deployment health check
./scripts/dms-operations.sh status || exit 1

# Start after deployment
./scripts/start-dms.sh --wait --timeout=600

# Post-deployment validation
./scripts/monitor-dms.sh --summary

# Pre-destroy cleanup
./scripts/stop-dms.sh --wait
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.26 |

### Additional Requirements for CI/CD

| Tool | Purpose | Installation |
|------|---------|-------------|
| **AWS CLI** | DMS operations and monitoring | `pip install awscli` or package manager |
| **jq** | JSON processing in scripts | `apt-get install jq` or `brew install jq` |
| **bash** | Script execution | Available on Linux/macOS, WSL on Windows |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.26 |

## Resources

| Name | Type |
|------|------|
| [aws_dms_replication_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_instance) | resource |
| [aws_dms_replication_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_subnet_group) | resource |
| [aws_dms_endpoint.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_endpoint.target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_replication_task.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_task) | resource |
| [aws_security_group.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.mysql_allow_dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.aurora_allow_dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.dms_to_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.dms_to_aurora](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_iam_role.dms_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.dms_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

### 🚀 CI/CD Variables (Primary Usage)

For CI/CD deployments, set these environment variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `PROJECT_NAME` | Project identifier (3-30 chars, lowercase, hyphens) | `"my-dms-migration"` |
| `ENVIRONMENT` | Environment name | `"development"`, `"production"` |
| `VPC_ID` | VPC where DMS will be deployed | `"vpc-0123456789abcdef0"` |
| `SUBNET_ID_1` | First subnet ID (different AZ) | `"subnet-0123456789abcdef0"` |
| `SUBNET_ID_2` | Second subnet ID (different AZ) | `"subnet-0fedcba9876543210"` |
| `SOURCE_SECURITY_GROUP_ID` | Source database security group | `"sg-0123456789abcdef0"` |
| `TARGET_SECURITY_GROUP_ID` | Target database security group | `"sg-0fedcba9876543210"` |
| `KMS_KEY_ARN` | KMS key for encryption | `"arn:aws:kms:us-east-1:123456789012:key/..."` |
| `SOURCE_ENGINE` | Source database engine | `"mysql"`, `"postgres"`, `"oracle"` |
| `SOURCE_DB_HOST` | Source database hostname | `"source.example.com"` |
| `SOURCE_DB_PORT` | Source database port | `"3306"`, `"5432"` |
| `SOURCE_DB_NAME` | Source database name | `"source_db"` |
| `TARGET_ENGINE` | Target database engine | `"postgres"`, `"aurora-postgresql"` |
| `TARGET_DB_HOST` | Target database hostname | `"target.example.com"` |
| `TARGET_DB_PORT` | Target database port | `"5432"` |
| `TARGET_DB_NAME` | Target database name | `"target_db"` |
| `USE_SECRETS_MANAGER` | Use AWS Secrets Manager | `"true"`, `"false"` |
| `MIGRATION_TYPE` | Migration type | `"full-load-and-cdc"` |

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| project_name | Project name used as prefix for all resources (3-30 chars, lowercase, numbers, hyphens only) | `string` |
| environment | Environment name: dev, development, staging, stage, test, prod, production, ti, trg | `string` |
| vpc_id | VPC ID where DMS resources will be created (must have DNS resolution enabled) | `string` |
| subnet_ids | List of subnet IDs for DMS subnet group (minimum 2 subnets in different AZs) | `list(string)` |
| source_endpoint_config | Source database endpoint configuration | `object({...})` |
| target_endpoint_config | Target database endpoint configuration | `object({...})` |
| source_security_group_id | Security group ID of the source database | `string` |
| target_security_group_id | Security group ID of the target database | `string` |
| kms_key_arn | ARN of the KMS key for encryption at rest | `string` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| naming_suffix | Optional suffix for resource names | `string` | `null` |
| owner | Owner or team responsible for the resources | `string` | `"infrastructure-team"` |
| cost_center | Cost center for billing allocation | `string` | `"infrastructure"` |
| enable_secrets_manager | Enable AWS Secrets Manager for credential management | `bool` | `true` |
| dms_instance_config | DMS replication instance configuration | `object({...})` | `{instance_class = "dms.t3.micro", allocated_storage = 20, engine_version = "3.5.2", multi_az = false}` |
| multi_az_config | Multi-AZ configuration for high availability | `object({...})` | `{enable_multi_az = false, force_multi_az_production = true, ...}` |
| security_config | Advanced security configuration | `object({...})` | `{enforce_ssl = true, restrict_public_access = true, ...}` |
| migration_type | Type of migration: full-load, cdc, or full-load-and-cdc | `string` | `"full-load-and-cdc"` |
| table_mappings | Table mappings configuration for selective migration | `any` | Include all tables |
| replication_task_settings | Replication task settings for performance and reliability | `any` | Optimized defaults |
| environment_config | Environment-specific configuration overrides | `object({...})` | Environment-based defaults |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` |

### Endpoint Configuration

#### 🚀 CI/CD Configuration (Environment Variables)
```bash
# Secrets Manager (Production)
export USE_SECRETS_MANAGER="true"
export SOURCE_SECRETS_ARN="arn:aws:secretsmanager:us-east-1:123456789012:secret:source-db"
export SOURCE_SECRETS_ROLE_ARN="arn:aws:iam::123456789012:role/dms-secrets-role"
export TARGET_SECRETS_ARN="arn:aws:secretsmanager:us-east-1:123456789012:secret:target-db"
export TARGET_SECRETS_ROLE_ARN="arn:aws:iam::123456789012:role/dms-secrets-role"

# Direct Credentials (Development)
export USE_SECRETS_MANAGER="false"
export SOURCE_DB_USERNAME="db_user"
export SOURCE_DB_PASSWORD="db_password"
export TARGET_DB_USERNAME="db_user"
export TARGET_DB_PASSWORD="db_password"
```

#### 📦 Terraform Module Configuration

##### Secrets Manager Configuration (Recommended)
```hcl
source_endpoint_config = {
  engine_name                     = "mysql"
  secrets_manager_arn             = "arn:aws:secretsmanager:..."
  secrets_manager_access_role_arn = "arn:aws:iam:..."
  ssl_mode                        = "require"
  extra_connection_attributes     = ""
}
```

##### Direct Credentials Configuration
```hcl
source_endpoint_config = {
  engine_name   = "mysql"
  server_name   = "mysql.example.com"
  port          = 3306
  username      = "db_user"
  password      = "db_password"
  database_name = "source_db"
  ssl_mode      = "require"
}
```

### Supported Database Engines

**Source Engines**: mysql, postgres, oracle, sqlserver, aurora, aurora-mysql, aurora-postgresql, mariadb, mongodb, redis, s3

**Target Engines**: mysql, postgres, oracle, sqlserver, aurora, aurora-mysql, aurora-postgresql, mariadb, mongodb, redis, s3, redshift

### Instance Classes

| Family | Instance Types | Use Case | Cost Level |
|--------|---------------|----------|------------|
| **T3 (Burstable)** | dms.t3.micro, dms.t3.small, dms.t3.medium, dms.t3.large | Development, testing, low-traffic | Low |
| **R5 (Memory Optimized)** | dms.r5.large, dms.r5.xlarge, dms.r5.2xlarge, dms.r5.4xlarge | Production, large datasets | Medium-High |
| **C5 (Compute Optimized)** | dms.c5.large, dms.c5.xlarge, dms.c5.2xlarge, dms.c5.4xlarge | CPU-intensive migrations | Medium-High |

## Outputs

### 🚀 CI/CD Integration Outputs

The deployment automatically provides structured outputs for CI/CD integration:

| Output | Description | Usage |
|--------|-------------|-------|
| `cli_commands` | Ready-to-use AWS CLI commands | Copy-paste for operations |
| `operational_guide` | Step-by-step operational procedures | Emergency and routine operations |
| `connection_info` | Database and DMS connection details | Monitoring and integration |
| `deployment_summary` | High-level deployment information | Reporting and documentation |

### Structured Outputs (Recommended)

| Name | Description |
|------|-------------|
| dms_instance | Complete DMS replication instance information (ARN, ID, configuration) |
| replication_task | Complete replication task information (ARN, ID, status, settings) |
| endpoints | Complete source and target endpoint information (ARNs, IDs, connection details) |
| network | Network infrastructure information (security groups, subnet groups, VPC details) |

### Legacy Outputs (Deprecated)

| Name | New Output | Description |
|------|------------|-------------|
| replication_instance_arn | dms_instance.arn | ARN of the DMS replication instance |
| replication_instance_id | dms_instance.id | ID of the DMS replication instance |
| replication_task_arn | replication_task.arn | ARN of the replication task |
| source_endpoint_arn | endpoints.source.arn | ARN of the source endpoint |
| target_endpoint_arn | endpoints.target.arn | ARN of the target endpoint |
| dms_security_group_id | network.security_group.id | ID of the DMS security group |

### Output Usage Examples

#### 🚀 CI/CD Pipeline Integration
```bash
# Get ready-to-use CLI commands from Terraform output
terraform output -json cli_commands | jq -r '.start_task'
# Output: aws dms start-replication-task --replication-task-arn arn:aws:dms:...

# Use in CI/CD pipeline
TASK_ARN=$(terraform output -json replication_task | jq -r '.arn')
aws dms start-replication-task --replication-task-arn $TASK_ARN
```

#### 📦 Traditional Terraform Integration

```hcl
# Reference DMS instance in CloudWatch alarms
resource "aws_cloudwatch_alarm" "dms_cpu" {
  alarm_name = "dms-high-cpu"
  # ... other configuration
  dimensions = {
    ReplicationInstanceIdentifier = module.dms.dms_instance.id
  }
}

# Use endpoint information for monitoring
output "migration_status" {
  value = {
    source_endpoint = module.dms.endpoints.source.arn
    target_endpoint = module.dms.endpoints.target.arn
    task_arn       = module.dms.replication_task.arn
    instance_id    = module.dms.dms_instance.id
  }
}
```

## Security Configuration

### Network Isolation Levels

| Level | Description | Egress Rules |
|-------|-------------|--------------|
| **strict** | Maximum security | HTTPS only for AWS APIs, specific database ports |
| **standard** | Balanced security | HTTPS/HTTP for updates, specific database ports |
| **basic** | Legacy compatibility | All egress allowed (not recommended for production) |

### AWS Well-Architected Framework Compliance

#### Security Pillar ✅
- **Encryption at Rest**: KMS encryption for all DMS resources
- **Encryption in Transit**: SSL/TLS for all database connections
- **Identity and Access Management**: IAM roles with least privilege
- **Network Security**: Private subnets, restrictive security groups
- **Secrets Management**: AWS Secrets Manager integration

#### Reliability Pillar ✅
- **Multi-AZ Deployment**: Automatic failover capability (production)
- **Automated Backups**: Configurable retention periods
- **Error Handling**: Comprehensive error recovery mechanisms
- **Monitoring**: CloudWatch integration for health monitoring

#### Performance Efficiency Pillar ✅
- **Right Sizing**: Environment-appropriate instance classes
- **Performance Monitoring**: CloudWatch metrics and Performance Insights
- **Optimization**: Configurable task settings for performance tuning

#### Cost Optimization Pillar ✅
- **Environment-Based Sizing**: Automatic cost optimization per environment
- **Feature Management**: Expensive features disabled in non-production
- **Resource Tagging**: Comprehensive cost allocation tags
- **Right-Sizing Recommendations**: Instance class guidance

#### Operational Excellence Pillar ✅
- **Infrastructure as Code**: Complete Terraform automation
- **Monitoring and Logging**: CloudWatch integration
- **Automated Operations**: Self-configuring based on environment
- **Documentation**: Comprehensive usage guides and examples
- **🚀 CI/CD Integration**: Ready-to-use deployment patterns and operational scripts

## Cost Optimization

### Environment-Based Cost Features

| Environment | Estimated Monthly Cost* | Key Cost Optimizations |
|-------------|------------------------|------------------------|
| **Development** | $15-30 | t3.micro, Single-AZ, Basic monitoring |
| **Test/TI** | $30-60 | t3.small/medium, Enhanced monitoring |
| **Staging** | $60-120 | Balanced configuration, Optional Performance Insights |
| **Production** | $200-500+ | Multi-AZ, Performance Insights, Enhanced monitoring |

*Costs are estimates for US East (N. Virginia) region and may vary based on usage

### Cost Optimization Features

- **Automatic Instance Sizing**: Environment-appropriate instance classes
- **Feature Management**: Expensive features auto-disabled in non-production
- **Storage Optimization**: Right-sized storage allocation
- **Monitoring Costs**: Performance Insights only where needed
- **Multi-AZ Management**: High availability only for production

## Monitoring and Observability

### CloudWatch Integration

- **Instance Metrics**: CPU, memory, network throughput
- **Task Metrics**: CDC latency, throughput, table statistics
- **Custom Dashboards**: Pre-configured monitoring dashboards
- **Automated Alarms**: Proactive monitoring and alerting

### Performance Insights (Production)

- **Database Performance Monitoring**: Real-time performance metrics
- **Wait Event Analysis**: Performance bottleneck identification
- **SQL Statement Analysis**: Query performance optimization
- **Historical Data**: Performance trend analysis

### Logging

- **CloudWatch Logs**: Comprehensive DMS task logging
- **Log Components**: Source unload, target load, CDC capture
- **Error Tracking**: Detailed error logging and analysis
- **Retention Management**: Configurable log retention periods

## Troubleshooting

### Common Issues

1. **Connectivity Issues**
   - Verify security group rules allow DMS access
   - Check VPC DNS resolution settings
   - Validate subnet routing tables

2. **Authentication Failures**
   - Verify Secrets Manager permissions
   - Check database user permissions
   - Validate SSL certificate configuration

3. **Performance Issues**
   - Monitor CloudWatch metrics
   - Consider instance class upgrades
   - Optimize replication task settings

### Diagnostic Commands

```bash
# Check DMS instance status
aws dms describe-replication-instances \
  --filters Name=replication-instance-id,Values=<instance-id>

# Test endpoint connectivity
aws dms test-connection \
  --replication-instance-arn <instance-arn> \
  --endpoint-arn <endpoint-arn>

# Monitor task progress
aws dms describe-table-statistics \
  --replication-task-arn <task-arn>
```

## Examples

### Complete Production Setup

```hcl
# KMS Key for DMS encryption
resource "aws_kms_key" "dms" {
  description             = "KMS key for DMS encryption"
  deletion_window_in_days = 7
  
  tags = {
    Name        = "dms-encryption-key"
    Environment = "production"
  }
}

# IAM Role for Secrets Manager access
resource "aws_iam_role" "dms_secrets" {
  name = "dms-secrets-manager-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dms.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "dms_secrets" {
  name = "dms-secrets-manager-policy"
  role = aws_iam_role.dms_secrets.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.mysql.arn,
          aws_secretsmanager_secret.aurora.arn
        ]
      }
    ]
  })
}

# DMS Module
module "dms_production" {
  source = "./modules/dms"
  
  # Core Configuration
  project_name = "enterprise-migration"
  environment  = "production"
  owner        = "data-engineering-team"
  cost_center  = "data-platform"
  
  # Network Configuration
  vpc_id     = data.aws_vpc.main.id
  subnet_ids = data.aws_subnets.private.ids
  
  # Production Instance Configuration
  dms_instance_config = {
    instance_class    = "dms.r5.xlarge"
    allocated_storage = 200
    engine_version    = "3.5.3"
    multi_az         = true
  }
  
  # Enhanced Security Configuration
  security_config = {
    enforce_ssl                 = true
    restrict_public_access      = true
    enable_detailed_monitoring  = true
    enable_performance_insights = true
    network_isolation_level     = "strict"
    require_kms_encryption      = true
    enable_deletion_protection  = true
  }
  
  # Source Database Configuration
  enable_secrets_manager = true
  source_endpoint_config = {
    engine_name                     = "mysql"
    secrets_manager_arn             = aws_secretsmanager_secret.mysql.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    ssl_mode                        = "require"
    extra_connection_attributes     = "initstmt=SET FOREIGN_KEY_CHECKS=0;executeTimeout=60"
  }
  
  # Target Database Configuration
  target_endpoint_config = {
    engine_name                     = "aurora-postgresql"
    secrets_manager_arn             = aws_secretsmanager_secret.aurora.arn
    secrets_manager_access_role_arn = aws_iam_role.dms_secrets.arn
    database_name                   = "production_db"
    ssl_mode                        = "require"
    extra_connection_attributes     = "executeTimeout=60;heartbeatEnable=true"
  }
  
  # Security Groups
  source_security_group_id = aws_security_group.mysql.id
  target_security_group_id = aws_security_group.aurora.id
  kms_key_arn              = aws_kms_key.dms.arn
  
  # Migration Configuration
  migration_type = "full-load-and-cdc"
  
  # Production Tags
  tags = {
    Environment    = "production"
    Department     = "Engineering"
    Application    = "DataMigration"
    Compliance     = "SOX"
    BusinessUnit   = "DataPlatform"
    Critical       = "true"
    BackupRequired = "true"
  }
}
```

## Contributing

1. Follow AWS and HashiCorp best practices
2. Update documentation for any changes
3. Add tests for new features
4. Ensure backward compatibility
5. Follow semantic versioning

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS DMS documentation
3. Create an issue in the repository
4. Contact the infrastructure team

---

**Module Version**: 2.1.0  
**AWS Provider**: >= 6.26  
**Terraform**: >= 1.0  
**Last Updated**: January 2025  
**🚀 CI/CD Ready**: Includes deployment scripts and operational tools