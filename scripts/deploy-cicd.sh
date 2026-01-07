#!/bin/bash
# ============================================================================
# AWS DMS CI/CD Deployment Script
# ============================================================================
#
# This script demonstrates how to deploy DMS infrastructure in a CI/CD pipeline
# using the inline variable pattern recommended by the tech leader.
#
# Usage:
#   ./deploy-cicd.sh <environment> [--dry-run]
#
# Features:
# ✅ Environment-specific variable substitution
# ✅ Template-based configuration management
# ✅ CI/CD pipeline integration ready
# ✅ Comprehensive validation and error handling
# ============================================================================
#
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$PROJECT_DIR/main-cicd.tf"
DEPLOY_FILE="$PROJECT_DIR/main.tf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}$1${NC}"
}

info() {
    echo -e "${BLUE}$1${NC}"
}

# Help function
show_help() {
    cat << EOF
AWS DMS CI/CD Deployment Script

USAGE:
    $0 <environment> [options]

ENVIRONMENTS:
    development     Deploy with development-optimized settings
    staging         Deploy with staging-optimized settings  
    production      Deploy with production-optimized settings

OPTIONS:
    -h, --help      Show this help message
    --dry-run       Show what would be deployed without executing
    --validate      Validate configuration without deploying

EXAMPLES:
    # Deploy to development
    $0 development

    # Deploy to production with dry-run
    $0 production --dry-run

    # Validate staging configuration
    $0 staging --validate

ENVIRONMENT VARIABLES:
    The following environment variables must be set in your CI/CD pipeline:

    CORE CONFIGURATION:
    - PROJECT_NAME              : Project name (e.g., "client-dms-migration")
    - OWNER                     : Team or owner name
    - COST_CENTER              : Cost center for billing

    NETWORK:
    - VPC_ID                   : VPC ID where DMS will be deployed
    - SUBNET_ID_1              : First private subnet ID
    - SUBNET_ID_2              : Second private subnet ID

    SECURITY:
    - SOURCE_SECURITY_GROUP_ID : Source database security group
    - TARGET_SECURITY_GROUP_ID : Target database security group
    - KMS_KEY_ARN              : KMS key for encryption

    DATABASE CONFIGURATION:
    - SOURCE_ENGINE            : Source database engine
    - SOURCE_DB_HOST           : Source database hostname
    - SOURCE_DB_PORT           : Source database port
    - SOURCE_DB_NAME           : Source database name
    - TARGET_ENGINE            : Target database engine
    - TARGET_DB_HOST           : Target database hostname
    - TARGET_DB_PORT           : Target database port
    - TARGET_DB_NAME           : Target database name

    CREDENTIALS (choose one approach):
    Option A - Secrets Manager (recommended for production):
    - USE_SECRETS_MANAGER=true
    - SOURCE_SECRETS_ARN       : Source database secret ARN
    - SOURCE_SECRETS_ROLE_ARN  : IAM role for source secrets
    - TARGET_SECRETS_ARN       : Target database secret ARN
    - TARGET_SECRETS_ROLE_ARN  : IAM role for target secrets

    Option B - Direct credentials (development/testing):
    - USE_SECRETS_MANAGER=false
    - SOURCE_DB_USERNAME       : Source database username
    - SOURCE_DB_PASSWORD       : Source database password
    - TARGET_DB_USERNAME       : Target database username
    - TARGET_DB_PASSWORD       : Target database password

    MIGRATION SETTINGS:
    - MIGRATION_TYPE           : Migration type (full-load-and-cdc, full-load, cdc)
    - SOURCE_SCHEMA_NAME       : Source schema pattern (%, public, etc.)
    - SOURCE_TABLE_PATTERN     : Source table pattern (%, specific table)
    - TARGET_SCHEMA_NAME       : Target schema name
    - DMS_ENGINE_VERSION       : DMS engine version
    - MAINTENANCE_WINDOW       : Maintenance window (e.g., "sun:03:00-sun:04:00")

EOF
}

# Validate required environment variables
validate_environment_variables() {
    local required_vars=(
        "PROJECT_NAME"
        "OWNER"
        "COST_CENTER"
        "VPC_ID"
        "SUBNET_ID_1"
        "SUBNET_ID_2"
        "SOURCE_SECURITY_GROUP_ID"
        "TARGET_SECURITY_GROUP_ID"
        "KMS_KEY_ARN"
        "SOURCE_ENGINE"
        "SOURCE_DB_HOST"
        "SOURCE_DB_PORT"
        "SOURCE_DB_NAME"
        "TARGET_ENGINE"
        "TARGET_DB_HOST"
        "TARGET_DB_PORT"
        "TARGET_DB_NAME"
        "MIGRATION_TYPE"
        "SOURCE_SCHEMA_NAME"
        "SOURCE_TABLE_PATTERN"
        "TARGET_SCHEMA_NAME"
        "DMS_ENGINE_VERSION"
        "MAINTENANCE_WINDOW"
        "USE_SECRETS_MANAGER"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # Check credentials based on USE_SECRETS_MANAGER
    if [ "${USE_SECRETS_MANAGER:-}" = "true" ]; then
        local secrets_vars=(
            "SOURCE_SECRETS_ARN"
            "SOURCE_SECRETS_ROLE_ARN"
            "TARGET_SECRETS_ARN"
            "TARGET_SECRETS_ROLE_ARN"
        )
        
        for var in "${secrets_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                missing_vars+=("$var")
            fi
        done
    else
        local direct_vars=(
            "SOURCE_DB_USERNAME"
            "SOURCE_DB_PASSWORD"
            "TARGET_DB_USERNAME"
            "TARGET_DB_PASSWORD"
        )
        
        for var in "${direct_vars[@]}"; do
            if [ -z "${!var:-}" ]; then
                missing_vars+=("$var")
            fi
        done
    fi
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        error_exit "Missing required environment variables: ${missing_vars[*]}"
    fi
    
    success "All required environment variables are set"
}

# Set environment-specific defaults
set_environment_defaults() {
    local environment=$1
    
    # Set defaults based on environment
    export CREATION_DATE="${CREATION_DATE:-$(date -Iseconds)}"
    export BUILD_VERSION="${BUILD_VERSION:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}"
    export SOURCE_SSL_MODE="${SOURCE_SSL_MODE:-prefer}"
    export TARGET_SSL_MODE="${TARGET_SSL_MODE:-prefer}"
    export SOURCE_EXTRA_ATTRIBUTES="${SOURCE_EXTRA_ATTRIBUTES:-}"
    export TARGET_EXTRA_ATTRIBUTES="${TARGET_EXTRA_ATTRIBUTES:-}"
    export ENFORCE_SSL="${ENFORCE_SSL:-true}"
    export REQUIRE_KMS="${REQUIRE_KMS:-true}"
    
    info "Environment: $environment"
    info "Build version: $BUILD_VERSION"
    info "Creation date: $CREATION_DATE"
}

# Substitute template variables
substitute_template_variables() {
    local template_file=$1
    local output_file=$2
    
    info "Substituting template variables..."
    
    # Copy template to output file
    cp "$template_file" "$output_file"
    
    # Core configuration
    sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$output_file"
    sed -i "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" "$output_file"
    sed -i "s/{{OWNER}}/$OWNER/g" "$output_file"
    sed -i "s/{{COST_CENTER}}/$COST_CENTER/g" "$output_file"
    sed -i "s/{{CREATION_DATE}}/$CREATION_DATE/g" "$output_file"
    sed -i "s/{{BUILD_VERSION}}/$BUILD_VERSION/g" "$output_file"
    
    # Network configuration
    sed -i "s/{{VPC_ID}}/$VPC_ID/g" "$output_file"
    sed -i "s/{{SUBNET_ID_1}}/$SUBNET_ID_1/g" "$output_file"
    sed -i "s/{{SUBNET_ID_2}}/$SUBNET_ID_2/g" "$output_file"
    
    # Security configuration
    sed -i "s/{{SOURCE_SECURITY_GROUP_ID}}/$SOURCE_SECURITY_GROUP_ID/g" "$output_file"
    sed -i "s/{{TARGET_SECURITY_GROUP_ID}}/$TARGET_SECURITY_GROUP_ID/g" "$output_file"
    sed -i "s|{{KMS_KEY_ARN}}|$KMS_KEY_ARN|g" "$output_file"
    
    # Database configuration
    sed -i "s/{{SOURCE_ENGINE}}/$SOURCE_ENGINE/g" "$output_file"
    sed -i "s/{{SOURCE_DB_HOST}}/$SOURCE_DB_HOST/g" "$output_file"
    sed -i "s/{{SOURCE_DB_PORT}}/$SOURCE_DB_PORT/g" "$output_file"
    sed -i "s/{{SOURCE_DB_NAME}}/$SOURCE_DB_NAME/g" "$output_file"
    sed -i "s/{{SOURCE_SSL_MODE}}/$SOURCE_SSL_MODE/g" "$output_file"
    sed -i "s/{{SOURCE_EXTRA_ATTRIBUTES}}/$SOURCE_EXTRA_ATTRIBUTES/g" "$output_file"
    
    sed -i "s/{{TARGET_ENGINE}}/$TARGET_ENGINE/g" "$output_file"
    sed -i "s/{{TARGET_DB_HOST}}/$TARGET_DB_HOST/g" "$output_file"
    sed -i "s/{{TARGET_DB_PORT}}/$TARGET_DB_PORT/g" "$output_file"
    sed -i "s/{{TARGET_DB_NAME}}/$TARGET_DB_NAME/g" "$output_file"
    sed -i "s/{{TARGET_SSL_MODE}}/$TARGET_SSL_MODE/g" "$output_file"
    sed -i "s/{{TARGET_EXTRA_ATTRIBUTES}}/$TARGET_EXTRA_ATTRIBUTES/g" "$output_file"
    
    # Credentials
    sed -i "s/{{USE_SECRETS_MANAGER}}/$USE_SECRETS_MANAGER/g" "$output_file"
    
    if [ "$USE_SECRETS_MANAGER" = "true" ]; then
        sed -i "s|{{SOURCE_SECRETS_ARN}}|$SOURCE_SECRETS_ARN|g" "$output_file"
        sed -i "s|{{SOURCE_SECRETS_ROLE_ARN}}|$SOURCE_SECRETS_ROLE_ARN|g" "$output_file"
        sed -i "s|{{TARGET_SECRETS_ARN}}|$TARGET_SECRETS_ARN|g" "$output_file"
        sed -i "s|{{TARGET_SECRETS_ROLE_ARN}}|$TARGET_SECRETS_ROLE_ARN|g" "$output_file"
    else
        sed -i "s/{{SOURCE_DB_USERNAME}}/$SOURCE_DB_USERNAME/g" "$output_file"
        sed -i "s/{{SOURCE_DB_PASSWORD}}/$SOURCE_DB_PASSWORD/g" "$output_file"
        sed -i "s/{{TARGET_DB_USERNAME}}/$TARGET_DB_USERNAME/g" "$output_file"
        sed -i "s/{{TARGET_DB_PASSWORD}}/$TARGET_DB_PASSWORD/g" "$output_file"
    fi
    
    # Migration settings
    sed -i "s/{{MIGRATION_TYPE}}/$MIGRATION_TYPE/g" "$output_file"
    sed -i "s/{{SOURCE_SCHEMA_NAME}}/$SOURCE_SCHEMA_NAME/g" "$output_file"
    sed -i "s/{{SOURCE_TABLE_PATTERN}}/$SOURCE_TABLE_PATTERN/g" "$output_file"
    sed -i "s/{{TARGET_SCHEMA_NAME}}/$TARGET_SCHEMA_NAME/g" "$output_file"
    sed -i "s/{{DMS_ENGINE_VERSION}}/$DMS_ENGINE_VERSION/g" "$output_file"
    sed -i "s/{{MAINTENANCE_WINDOW}}/$MAINTENANCE_WINDOW/g" "$output_file"
    
    # Optional settings
    sed -i "s/{{ENFORCE_SSL}}/$ENFORCE_SSL/g" "$output_file"
    sed -i "s/{{REQUIRE_KMS}}/$REQUIRE_KMS/g" "$output_file"
    
    success "Template variables substituted successfully"
}

# Validate Terraform configuration
validate_terraform() {
    local config_file=$1
    
    info "Validating Terraform configuration..."
    
    # Check if terraform is available
    if ! command -v terraform &> /dev/null; then
        error_exit "Terraform is not installed or not in PATH"
    fi
    
    # Initialize terraform
    terraform -chdir="$PROJECT_DIR" init -backend=false > /dev/null
    
    # Validate configuration
    if terraform -chdir="$PROJECT_DIR" validate; then
        success "Terraform configuration is valid"
    else
        error_exit "Terraform configuration validation failed"
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    local dry_run=$1
    
    info "Deploying DMS infrastructure..."
    
    # Initialize terraform
    terraform -chdir="$PROJECT_DIR" init
    
    # Plan deployment
    if terraform -chdir="$PROJECT_DIR" plan -out=tfplan; then
        success "Terraform plan completed successfully"
    else
        error_exit "Terraform plan failed"
    fi
    
    if [ "$dry_run" = true ]; then
        warning "DRY RUN MODE - Deployment plan created but not applied"
        info "To apply this plan, run: terraform apply tfplan"
        return 0
    fi
    
    # Apply deployment
    if terraform -chdir="$PROJECT_DIR" apply tfplan; then
        success "DMS infrastructure deployed successfully"
        
        # Show outputs
        info "Deployment outputs:"
        terraform -chdir="$PROJECT_DIR" output
    else
        error_exit "Terraform apply failed"
    fi
}

# Main script logic
main() {
    local environment=""
    local dry_run=false
    local validate_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --validate)
                validate_only=true
                shift
                ;;
            development|staging|production)
                environment=$1
                shift
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
    
    # Validate arguments
    if [ -z "$environment" ]; then
        error_exit "Environment is required. Use: development, staging, or production"
    fi
    
    # Check if template file exists
    if [ ! -f "$TEMPLATE_FILE" ]; then
        error_exit "Template file not found: $TEMPLATE_FILE"
    fi
    
    # Set environment
    export ENVIRONMENT=$environment
    
    info "Starting DMS CI/CD deployment for environment: $environment"
    
    # Set environment defaults
    set_environment_defaults "$environment"
    
    # Validate environment variables
    validate_environment_variables
    
    # Substitute template variables
    substitute_template_variables "$TEMPLATE_FILE" "$DEPLOY_FILE"
    
    # Validate Terraform configuration
    validate_terraform "$DEPLOY_FILE"
    
    if [ "$validate_only" = true ]; then
        success "Configuration validation completed successfully"
        return 0
    fi
    
    # Deploy infrastructure
    deploy_infrastructure "$dry_run"
    
    success "DMS CI/CD deployment completed successfully!"
}

# Run main function
main "$@"