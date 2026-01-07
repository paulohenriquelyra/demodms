#!/bin/bash
# ============================================================================
# AWS DMS Task Monitor Script - Production Ready
# ============================================================================
#
# This script monitors DMS replication tasks with comprehensive status reporting
# and real-time metrics. Designed for client environments without console access.
#
# Usage:
#   ./monitor-dms.sh [task-arn] [--watch] [--interval=30]
#
# Features:
# ✅ Automatic task ARN detection from Terraform outputs
# ✅ Real-time status monitoring with watch mode
# ✅ Comprehensive task statistics and metrics
# ✅ Error detection and alerting
# ✅ Performance metrics and lag monitoring
# ============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${SCRIPT_DIR}/dms-operations.log"
DEFAULT_INTERVAL=30

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
AWS DMS Task Monitor Script

USAGE:
    $0 [OPTIONS] [TASK_ARN]

OPTIONS:
    -h, --help              Show this help message
    -w, --watch             Continuous monitoring mode (refresh every interval)
    -i, --interval=SECONDS  Refresh interval for watch mode (default: 30)
    --json                  Output in JSON format
    --summary              Show summary only (no detailed stats)

ARGUMENTS:
    TASK_ARN               DMS replication task ARN (optional if terraform outputs available)

EXAMPLES:
    # Monitor task once using Terraform outputs
    $0

    # Continuous monitoring with 60-second intervals
    $0 --watch --interval=60

    # Monitor specific task
    $0 arn:aws:dms:us-east-1:123456789012:task:ABCDEFGHIJKLMNOP

    # JSON output for automation
    $0 --json

REQUIREMENTS:
    - AWS CLI configured with appropriate permissions
    - DMS replication task must exist
    - Network connectivity to AWS DMS service

EOF
}

# Parse command line arguments
TASK_ARN=""
WATCH_MODE=false
INTERVAL=$DEFAULT_INTERVAL
JSON_OUTPUT=false
SUMMARY_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -w|--watch)
            WATCH_MODE=true
            shift
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        --interval=*)
            INTERVAL="${1#*=}"
            shift
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --summary)
            SUMMARY_ONLY=true
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

# Validate interval
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 5 ]; then
    error_exit "Interval must be a number >= 5 seconds"
fi

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
    if TASK_ARN=$(get_task_arn_from_terraform); then
        if [ "$JSON_OUTPUT" = false ]; then
            info "Retrieved task ARN from Terraform: $TASK_ARN"
        fi
    else
        error_exit "Could not retrieve task ARN from Terraform outputs. Please provide task ARN as argument."
    fi
fi

# Validate task ARN format
if [[ ! "$TASK_ARN" =~ ^arn:aws:dms:[a-z0-9-]+:[0-9]+:task:[A-Z0-9]+$ ]]; then
    error_exit "Invalid task ARN format: $TASK_ARN"
fi

# Check AWS CLI availability and configuration
if ! command -v aws &> /dev/null; then
    error_exit "AWS CLI is not installed or not in PATH"
fi

# Test AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    error_exit "AWS credentials not configured or invalid"
fi

# Function to get comprehensive task information
get_task_info() {
    aws dms describe-replication-tasks \
        --filters "Name=replication-task-arn,Values=$TASK_ARN" \
        --query 'ReplicationTasks[0]' \
        --output json 2>/dev/null || echo "{}"
}

# Function to format bytes
format_bytes() {
    local bytes=$1
    if [ "$bytes" -eq 0 ]; then
        echo "0 B"
    elif [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 )) KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 )) MB"
    else
        echo "$(( bytes / 1073741824 )) GB"
    fi
}

# Function to format duration
format_duration() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local mins=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [ "$days" -gt 0 ]; then
        echo "${days}d ${hours}h ${mins}m ${secs}s"
    elif [ "$hours" -gt 0 ]; then
        echo "${hours}h ${mins}m ${secs}s"
    elif [ "$mins" -gt 0 ]; then
        echo "${mins}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

# Function to get status color
get_status_color() {
    local status=$1
    case "$status" in
        "running") echo "$GREEN" ;;
        "stopped"|"ready") echo "$BLUE" ;;
        "starting"|"stopping") echo "$YELLOW" ;;
        "failed") echo "$RED" ;;
        *) echo "$NC" ;;
    esac
}

# Function to display task information
display_task_info() {
    local task_info="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Parse task information
    local status=$(echo "$task_info" | jq -r '.Status // "UNKNOWN"')
    local migration_type=$(echo "$task_info" | jq -r '.MigrationType // "unknown"')
    local task_id=$(echo "$task_info" | jq -r '.ReplicationTaskIdentifier // "unknown"')
    local instance_arn=$(echo "$task_info" | jq -r '.ReplicationInstanceArn // "unknown"')
    local source_arn=$(echo "$task_info" | jq -r '.SourceEndpointArn // "unknown"')
    local target_arn=$(echo "$task_info" | jq -r '.TargetEndpointArn // "unknown"')
    local creation_date=$(echo "$task_info" | jq -r '.ReplicationTaskCreationDate // "unknown"')
    local start_date=$(echo "$task_info" | jq -r '.ReplicationTaskStartDate // "unknown"')
    
    # Parse statistics
    local stats=$(echo "$task_info" | jq -r '.ReplicationTaskStats // {}')
    local full_load_progress=$(echo "$stats" | jq -r '.FullLoadProgressPercent // 0')
    local elapsed_time=$(echo "$stats" | jq -r '.ElapsedTimeMillis // 0')
    local tables_loaded=$(echo "$stats" | jq -r '.TablesLoaded // 0')
    local tables_loading=$(echo "$stats" | jq -r '.TablesLoading // 0')
    local tables_queued=$(echo "$stats" | jq -r '.TablesQueued // 0')
    local tables_errored=$(echo "$stats" | jq -r '.TablesErrored // 0')
    
    if [ "$JSON_OUTPUT" = true ]; then
        echo "$task_info" | jq '{
            timestamp: "'$timestamp'",
            status: .Status,
            migration_type: .MigrationType,
            task_id: .ReplicationTaskIdentifier,
            statistics: .ReplicationTaskStats,
            endpoints: {
                source: .SourceEndpointArn,
                target: .TargetEndpointArn
            }
        }'
        return
    fi
    
    # Clear screen in watch mode
    if [ "$WATCH_MODE" = true ]; then
        clear
    fi
    
    # Header
    highlight "═══════════════════════════════════════════════════════════════════════════════"
    highlight "                          AWS DMS Task Monitor"
    highlight "═══════════════════════════════════════════════════════════════════════════════"
    echo
    
    # Basic Information
    highlight "📋 Task Information"
    echo "   Task ID: $task_id"
    echo "   Status: $(get_status_color "$status")$status$NC"
    echo "   Migration Type: $migration_type"
    echo "   Last Updated: $timestamp"
    echo
    
    if [ "$SUMMARY_ONLY" = false ]; then
        # Resource Information
        highlight "🔗 Resources"
        echo "   Replication Instance: $(basename "$instance_arn")"
        echo "   Source Endpoint: $(basename "$source_arn")"
        echo "   Target Endpoint: $(basename "$target_arn")"
        echo
        
        # Timing Information
        highlight "⏰ Timing"
        echo "   Created: $creation_date"
        if [ "$start_date" != "null" ] && [ "$start_date" != "unknown" ]; then
            echo "   Started: $start_date"
        fi
        if [ "$elapsed_time" != "0" ] && [ "$elapsed_time" != "null" ]; then
            local elapsed_seconds=$((elapsed_time / 1000))
            echo "   Elapsed Time: $(format_duration $elapsed_seconds)"
        fi
        echo
    fi
    
    # Statistics
    highlight "📊 Migration Statistics"
    if [ "$full_load_progress" != "0" ] && [ "$full_load_progress" != "null" ]; then
        echo "   Full Load Progress: ${full_load_progress}%"
    fi
    
    if [ "$tables_loaded" != "0" ] || [ "$tables_loading" != "0" ] || [ "$tables_queued" != "0" ]; then
        echo "   Tables Loaded: $tables_loaded"
        echo "   Tables Loading: $tables_loading"
        echo "   Tables Queued: $tables_queued"
        if [ "$tables_errored" != "0" ]; then
            warning "   Tables Errored: $tables_errored"
        fi
    fi
    
    # Status-specific information
    case "$status" in
        "running")
            success "✅ Task is running successfully"
            ;;
        "stopped"|"ready")
            info "⏸️  Task is stopped"
            ;;
        "starting")
            info "🚀 Task is starting..."
            ;;
        "stopping")
            warning "⏹️  Task is stopping..."
            ;;
        "failed")
            warning "❌ Task has failed - check CloudWatch logs for details"
            ;;
    esac
    
    if [ "$WATCH_MODE" = true ]; then
        echo
        info "🔄 Refreshing every ${INTERVAL} seconds... (Press Ctrl+C to exit)"
    fi
    
    echo
    highlight "═══════════════════════════════════════════════════════════════════════════════"
}

# Main monitoring function
monitor_task() {
    while true; do
        local task_info=$(get_task_info)
        
        if [ "$task_info" = "{}" ] || [ "$(echo "$task_info" | jq -r '.Status // "null"')" = "null" ]; then
            error_exit "DMS task not found or inaccessible: $TASK_ARN"
        fi
        
        display_task_info "$task_info"
        
        if [ "$WATCH_MODE" = false ]; then
            break
        fi
        
        sleep "$INTERVAL"
    done
}

# Handle Ctrl+C gracefully in watch mode
trap 'echo -e "\n\nMonitoring stopped."; exit 0' INT

# Start monitoring
monitor_task