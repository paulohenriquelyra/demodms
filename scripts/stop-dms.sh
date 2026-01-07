#!/bin/bash
# ============================================================================
# AWS DMS Task Stop Script - Production Ready
# ============================================================================
#
# This script stops DMS replication tasks with comprehensive error handling
# and validation. Designed for client environments without console access.
#
# Usage:
#   ./stop-dms.sh [task-arn] [--wait] [--timeout=300]
#
# Features:
# ✅ Automatic task ARN detection from Terraform outputs
# ✅ Pre-flight validation checks
# ✅ Comprehensive error handling
# ✅ Optional wait for task completion
# ✅ Detailed logging and status reporting
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${SCRIPT_DIR}/dms-operations.log"
DEFAULT_TIMEOUT=300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Success message
success() {
    log "INFO" "${GREEN}$1${NC}"
}

# Warning message
warning() {
    log "WARN" "${YELLOW}$1${NC}"
}

# Info message
info() {
    log "INFO" "${BLUE}$1${NC}"
}

# Help function
show_help() {
    cat << EOF
AWS DMS Task Stop Script

USAGE:
    $0 [OPTIONS] [TASK_ARN]

OPTIONS:
    -h, --help              Show this help message
    -w, --wait              Wait for task to reach stopped state
    -t, --timeout=SECONDS   Timeout for wait operation (default: 300)
    --dry-run              Show what would be done without executing

ARGUMENTS:
    TASK_ARN               DMS replication task ARN (optional if terraform outputs available)

EXAMPLES:
    # Stop task using Terraform outputs
    $0 --wait

    # Stop specific task
    $0 arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOP

    # Stop with custom timeout
    $0 --wait --timeout=600

REQUIREMENTS:
    - AWS CLI configured with appropriate permissions
    - DMS replication task must exist and be in 'running' or 'starting' state
    - Network connectivity to AWS DMS service

EOF
}

# Parse command line arguments
TASK_ARN=""
WAIT_FOR_COMPLETION=false
TIMEOUT=$DEFAULT_TIMEOUT
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -w|--wait)
            WAIT_FOR_COMPLETION=true
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --timeout=*)
            TIMEOUT="${1#*=}"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        arn:aws:dms:*)
            TASK_ARN="$1"
            shift
            ;;
        *)
            error_exit "Unknown option: $1. Use --help for usage information."
            ;;
    esac
done

# Validate timeout
if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -lt 30 ]; then
    error_exit "Timeout must be a number >= 30 seconds"
fi

info "Starting DMS task stop script..."
info "Log file: $LOG_FILE"

# Function to get task ARN from Terraform outputs
get_task_arn_from_terraform() {
    if [ -f "$PROJECT_DIR/terraform.tfstate" ]; then
        local arn=$(terraform -chdir="$PROJECT_DIR" output -raw replication_task_arn 2>/dev/null || echo "")
        if [ -n "$arn" ] && [ "$arn" != "null" ]; then
            echo "$arn"
            return 0
        fi
    fi
    
    # Try structured output
    if [ -f "$PROJECT_DIR/terraform.tfstate" ]; then
        local arn=$(terraform -chdir="$PROJECT_DIR" output -json replication_task 2>/dev/null | jq -r '.arn // empty' 2>/dev/null || echo "")
        if [ -n "$arn" ] && [ "$arn" != "null" ]; then
            echo "$arn"
            return 0
        fi
    fi
    
    return 1
}

# Get task ARN if not provided
if [ -z "$TASK_ARN" ]; then
    info "Task ARN not provided, attempting to retrieve from Terraform outputs..."
    if TASK_ARN=$(get_task_arn_from_terraform); then
        success "Retrieved task ARN from Terraform: $TASK_ARN"
    else
        error_exit "Could not retrieve task ARN from Terraform outputs. Please provide task ARN as argument."
    fi
fi

# Validate task ARN format
if [[ ! "$TASK_ARN" =~ ^arn:aws:dms:[a-z0-9-]+:[0-9]+:task:[A-Z0-9]+$ ]]; then
    error_exit "Invalid task ARN format: $TASK_ARN"
fi

info "Using DMS task ARN: $TASK_ARN"

# Check AWS CLI availability and configuration
if ! command -v aws &> /dev/null; then
    error_exit "AWS CLI is not installed or not in PATH"
fi

# Test AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    error_exit "AWS credentials not configured or invalid"
fi

# Function to get task status
get_task_status() {
    aws dms describe-replication-tasks \
        --filters "Name=replication-task-arn,Values=$TASK_ARN" \
        --query 'ReplicationTasks[0].Status' \
        --output text 2>/dev/null || echo "UNKNOWN"
}

# Function to get task details
get_task_details() {
    aws dms describe-replication-tasks \
        --filters "Name=replication-task-arn,Values=$TASK_ARN" \
        --query 'ReplicationTasks[0]' \
        --output json 2>/dev/null || echo "{}"
}

# Pre-flight checks
info "Performing pre-flight checks..."

# Check if task exists
CURRENT_STATUS=$(get_task_status)
if [ "$CURRENT_STATUS" = "UNKNOWN" ] || [ "$CURRENT_STATUS" = "None" ]; then
    error_exit "DMS task not found or inaccessible: $TASK_ARN"
fi

info "Current task status: $CURRENT_STATUS"

# Check if task can be stopped
case "$CURRENT_STATUS" in
    "running"|"starting")
        success "Task is in stoppable state: $CURRENT_STATUS"
        ;;
    "stopped"|"ready")
        warning "Task is already stopped: $CURRENT_STATUS"
        success "Task is already stopped!"
        exit 0
        ;;
    "stopping")
        warning "Task is already stopping: $CURRENT_STATUS"
        if [ "$WAIT_FOR_COMPLETION" = true ]; then
            info "Will wait for stop completion..."
        else
            success "Task is already stopping!"
            exit 0
        fi
        ;;
    "failed")
        warning "Task is in failed state: $CURRENT_STATUS"
        info "Task is already stopped (failed state)"
        exit 0
        ;;
    *)
        error_exit "Task cannot be stopped from current state: $CURRENT_STATUS"
        ;;
esac

# Get additional task details for validation
TASK_DETAILS=$(get_task_details)
MIGRATION_TYPE=$(echo "$TASK_DETAILS" | jq -r '.MigrationType // "unknown"')
INSTANCE_ARN=$(echo "$TASK_DETAILS" | jq -r '.ReplicationInstanceArn // "unknown"')

info "Migration type: $MIGRATION_TYPE"
info "Replication instance: $(basename "$INSTANCE_ARN")"

# Dry run mode
if [ "$DRY_RUN" = true ]; then
    info "DRY RUN MODE - Would execute:"
    echo "  aws dms stop-replication-task --replication-task-arn $TASK_ARN"
    if [ "$WAIT_FOR_COMPLETION" = true ]; then
        echo "  Wait for task to reach 'stopped' state (timeout: ${TIMEOUT}s)"
    fi
    exit 0
fi

# Stop the replication task (only if not already stopping)
if [ "$CURRENT_STATUS" != "stopping" ]; then
    info "Stopping DMS replication task..."
    if aws dms stop-replication-task --replication-task-arn "$TASK_ARN" &> /dev/null; then
        success "DMS task stop command executed successfully"
    else
        error_exit "Failed to stop DMS task. Check AWS permissions and task state."
    fi
fi

# Wait for completion if requested
if [ "$WAIT_FOR_COMPLETION" = true ]; then
    info "Waiting for task to reach 'stopped' state (timeout: ${TIMEOUT}s)..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + TIMEOUT))
    
    while [ $(date +%s) -lt $end_time ]; do
        CURRENT_STATUS=$(get_task_status)
        
        case "$CURRENT_STATUS" in
            "stopped"|"ready")
                success "Task is now stopped!"
                
                # Get final task statistics
                TASK_STATS=$(aws dms describe-replication-tasks \
                    --filters "Name=replication-task-arn,Values=$TASK_ARN" \
                    --query 'ReplicationTasks[0].ReplicationTaskStats' \
                    --output json 2>/dev/null || echo "{}")
                
                if [ "$TASK_STATS" != "{}" ]; then
                    info "Final Task Statistics:"
                    echo "$TASK_STATS" | jq -r 'to_entries[] | "  \(.key): \(.value)"' 2>/dev/null || true
                fi
                
                exit 0
                ;;
            "failed")
                warning "Task stopped with failed status"
                exit 0
                ;;
            "stopping")
                info "Task is stopping... ($(date '+%H:%M:%S'))"
                ;;
            *)
                warning "Unexpected task status: $CURRENT_STATUS"
                ;;
        esac
        
        sleep 10
    done
    
    error_exit "Timeout waiting for task to stop. Current status: $(get_task_status)"
else
    info "Task stop initiated. Use './monitor-dms.sh' to check progress."
fi

success "DMS task stop operation completed successfully!"