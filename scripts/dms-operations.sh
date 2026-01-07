#!/bin/bash
# ============================================================================
# AWS DMS Operations Manager - Unified CLI Interface
# ============================================================================
#
# This script provides a unified interface for all DMS operations including
# start, stop, monitor, and status checks. Designed for client environments
# without console access.
#
# Usage:
#   ./dms-operations.sh <command> [options]
#
# Features:
# ✅ Unified interface for all DMS operations
# ✅ Automatic task ARN detection from Terraform outputs
# ✅ Comprehensive error handling and validation
# ✅ Interactive and automated modes
# ✅ Detailed logging and status reporting
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${SCRIPT_DIR}/dms-operations.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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
    echo -e "${GREEN}$1${NC}"
}

# Warning message
warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Info message
info() {
    echo -e "${BLUE}$1${NC}"
}

# Highlight message
highlight() {
    echo -e "${CYAN}${BOLD}$1${NC}"
}

# Help function
show_help() {
    cat << EOF
AWS DMS Operations Manager

USAGE:
    $0 <command> [options]

COMMANDS:
    start       Start DMS replication task
    stop        Stop DMS replication task
    monitor     Monitor DMS task status and statistics
    status      Get current task status (quick check)
    restart     Stop and start DMS task
    logs        View DMS task logs from CloudWatch
    help        Show this help message

GLOBAL OPTIONS:
    --task-arn=ARN         Specify DMS task ARN (auto-detected if not provided)
    --wait                 Wait for operation completion
    --timeout=SECONDS      Timeout for wait operations (default: 300)
    --json                 Output in JSON format (where applicable)
    --dry-run             Show what would be done without executing

EXAMPLES:
    # Start task and wait for completion
    $0 start --wait

    # Stop specific task
    $0 stop --task-arn=arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOP

    # Monitor task continuously
    $0 monitor --watch --interval=60

    # Get quick status check
    $0 status --json

    # Restart task with timeout
    $0 restart --wait --timeout=600

REQUIREMENTS:
    - AWS CLI configured with appropriate permissions
    - DMS replication task deployed via Terraform
    - Network connectivity to AWS DMS service

For command-specific help, use: $0 <command> --help

EOF
}

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

# Function to validate prerequisites
validate_prerequisites() {
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error_exit "AWS CLI is not installed or not in PATH"
    fi
    
    # Test AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error_exit "AWS credentials not configured or invalid"
    fi
    
    # Check for jq (needed for JSON processing)
    if ! command -v jq &> /dev/null; then
        warning "jq is not installed - JSON processing will be limited"
    fi
}

# Function to get current task status
get_task_status() {
    local task_arn=$1
    aws dms describe-replication-tasks \
        --filters "Name=replication-task-arn,Values=$task_arn" \
        --query 'ReplicationTasks[0].Status' \
        --output text 2>/dev/null || echo "UNKNOWN"
}

# Function to execute command with proper script
execute_command() {
    local command=$1
    shift
    local args=("$@")
    
    case "$command" in
        "start")
            exec "$SCRIPT_DIR/start-dms.sh" "${args[@]}"
            ;;
        "stop")
            exec "$SCRIPT_DIR/stop-dms.sh" "${args[@]}"
            ;;
        "monitor")
            exec "$SCRIPT_DIR/monitor-dms.sh" "${args[@]}"
            ;;
        "status")
            # Quick status check
            local task_arn=""
            local json_output=false
            
            # Parse args for status command
            for arg in "${args[@]}"; do
                case "$arg" in
                    --task-arn=*)
                        task_arn="${arg#*=}"
                        ;;
                    --json)
                        json_output=true
                        ;;
                esac
            done
            
            # Get task ARN if not provided
            if [ -z "$task_arn" ]; then
                if task_arn=$(get_task_arn_from_terraform); then
                    if [ "$json_output" = false ]; then
                        info "Using task ARN from Terraform: $task_arn"
                    fi
                else
                    error_exit "Could not retrieve task ARN. Please provide --task-arn option."
                fi
            fi
            
            local status=$(get_task_status "$task_arn")
            
            if [ "$json_output" = true ]; then
                echo "{\"task_arn\":\"$task_arn\",\"status\":\"$status\",\"timestamp\":\"$(date -Iseconds)\"}"
            else
                echo "Task Status: $status"
                echo "Task ARN: $task_arn"
                echo "Checked: $(date)"
            fi
            ;;
        "restart")
            # Restart = stop + start
            info "Restarting DMS task (stop + start)..."
            
            # Execute stop first
            "$SCRIPT_DIR/stop-dms.sh" "${args[@]}"
            local stop_exit_code=$?
            
            if [ $stop_exit_code -eq 0 ]; then
                success "Stop completed successfully, starting task..."
                sleep 5  # Brief pause between operations
                "$SCRIPT_DIR/start-dms.sh" "${args[@]}"
            else
                error_exit "Stop operation failed, aborting restart"
            fi
            ;;
        "logs")
            # CloudWatch logs viewing
            local task_arn=""
            
            # Parse args for logs command
            for arg in "${args[@]}"; do
                case "$arg" in
                    --task-arn=*)
                        task_arn="${arg#*=}"
                        ;;
                esac
            done
            
            # Get task ARN if not provided
            if [ -z "$task_arn" ]; then
                if task_arn=$(get_task_arn_from_terraform); then
                    info "Using task ARN from Terraform: $task_arn"
                else
                    error_exit "Could not retrieve task ARN. Please provide --task-arn option."
                fi
            fi
            
            # Extract task ID from ARN
            local task_id=$(basename "$task_arn")
            local log_group="dms-tasks-$task_id"
            
            info "Viewing logs for task: $task_id"
            info "Log group: $log_group"
            
            # Check if log group exists
            if aws logs describe-log-groups --log-group-name-prefix "$log_group" --query 'logGroups[0].logGroupName' --output text 2>/dev/null | grep -q "$log_group"; then
                # Get recent log events
                aws logs filter-log-events \
                    --log-group-name "$log_group" \
                    --start-time $(($(date +%s) * 1000 - 3600000)) \
                    --query 'events[*].[timestamp,message]' \
                    --output table
            else
                warning "Log group '$log_group' not found or no recent logs available"
                info "Available DMS log groups:"
                aws logs describe-log-groups --log-group-name-prefix "dms-tasks" --query 'logGroups[*].logGroupName' --output table
            fi
            ;;
        *)
            error_exit "Unknown command: $command. Use 'help' for available commands."
            ;;
    esac
}

# Main script logic
main() {
    # Check if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 1
    fi
    
    local command=$1
    shift
    
    # Handle help command
    if [ "$command" = "help" ] || [ "$command" = "--help" ] || [ "$command" = "-h" ]; then
        show_help
        exit 0
    fi
    
    # Validate prerequisites
    validate_prerequisites
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Log operation start
    log "INFO" "Starting DMS operation: $command"
    
    # Execute the command
    execute_command "$command" "$@"
}

# Run main function with all arguments
main "$@"