#!/bin/bash

################################################################################
# Utils.sh - Utility Script with Helper Functions
# 
# This script provides reusable helper functions for:
# - Validation
# - Logging
# - Error Handling
# - Monitoring
#
# Created: 2025-12-07
# Author: disa12311
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Log file location
LOG_FILE="${LOG_FILE:-./utils.log}"
LOG_LEVEL="${LOG_LEVEL:-INFO}"  # DEBUG, INFO, WARN, ERROR

# Monitoring configuration
MONITORING_ENABLED="${MONITORING_ENABLED:-true}"
PERF_LOG_FILE="${PERF_LOG_FILE:-./performance.log}"

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

###############################################################################
# Initialize logging
# Globals:
#   LOG_FILE, LOG_LEVEL
# Arguments:
#   None
# Returns:
#   0 on success, 1 on failure
###############################################################################
init_logging() {
    if [[ ! -d "$(dirname "$LOG_FILE")" ]]; then
        mkdir -p "$(dirname "$LOG_FILE")" || return 1
    fi
    
    echo "========================================" >> "$LOG_FILE"
    echo "Log initialized at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "Log Level: $LOG_LEVEL" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    return 0
}

###############################################################################
# Log message with timestamp and level
# Globals:
#   LOG_FILE, LOG_LEVEL
# Arguments:
#   $1 - Log level (DEBUG, INFO, WARN, ERROR)
#   $2 - Message
# Returns:
#   0 on success
###############################################################################
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if message should be logged based on log level
    case "$LOG_LEVEL" in
        DEBUG)
            ;;
        INFO)
            [[ "$level" == "DEBUG" ]] && return 0
            ;;
        WARN)
            [[ "$level" =~ ^(DEBUG|INFO)$ ]] && return 0
            ;;
        ERROR)
            [[ "$level" != "ERROR" ]] && return 0
            ;;
    esac
    
    local log_entry="[$timestamp] [$level] $message"
    echo "$log_entry" >> "$LOG_FILE"
    
    # Also print to console with colors for non-DEBUG messages
    case "$level" in
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} $message" >&2
            ;;
        INFO)
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message" >&2
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
    esac
    
    return 0
}

###############################################################################
# Convenience functions for different log levels
###############################################################################
log_debug() {
    log_message "DEBUG" "$1"
}

log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

###############################################################################
# Validate that a variable is not empty
# Arguments:
#   $1 - Variable name
#   $2 - Variable value
# Returns:
#   0 if valid, 1 if empty
###############################################################################
validate_not_empty() {
    local var_name="$1"
    local var_value="$2"
    
    if [[ -z "$var_value" ]]; then
        log_error "Validation failed: $var_name is empty"
        return 1
    fi
    
    log_debug "Validation passed: $var_name is not empty"
    return 0
}

###############################################################################
# Validate that a file exists
# Arguments:
#   $1 - File path
# Returns:
#   0 if file exists, 1 otherwise
###############################################################################
validate_file_exists() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        log_error "File does not exist: $file_path"
        return 1
    fi
    
    log_debug "File exists: $file_path"
    return 0
}

###############################################################################
# Validate that a directory exists
# Arguments:
#   $1 - Directory path
# Returns:
#   0 if directory exists, 1 otherwise
###############################################################################
validate_dir_exists() {
    local dir_path="$1"
    
    if [[ ! -d "$dir_path" ]]; then
        log_error "Directory does not exist: $dir_path"
        return 1
    fi
    
    log_debug "Directory exists: $dir_path"
    return 0
}

###############################################################################
# Validate that a command/binary exists in PATH
# Arguments:
#   $1 - Command name
# Returns:
#   0 if command exists, 1 otherwise
###############################################################################
validate_command_exists() {
    local command="$1"
    
    if ! command -v "$command" &>/dev/null; then
        log_error "Command not found: $command"
        return 1
    fi
    
    log_debug "Command found: $command"
    return 0
}

###############################################################################
# Validate numeric value (integer)
# Arguments:
#   $1 - Value to validate
#   $2 - Minimum value (optional)
#   $3 - Maximum value (optional)
# Returns:
#   0 if valid, 1 otherwise
###############################################################################
validate_number() {
    local value="$1"
    local min="${2:-}"
    local max="${3:-}"
    
    # Check if value is a number
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "Not a valid number: $value"
        return 1
    fi
    
    # Check minimum
    if [[ -n "$min" && $value -lt $min ]]; then
        log_error "Value $value is less than minimum $min"
        return 1
    fi
    
    # Check maximum
    if [[ -n "$max" && $value -gt $max ]]; then
        log_error "Value $value is greater than maximum $max"
        return 1
    fi
    
    log_debug "Number validation passed: $value"
    return 0
}

###############################################################################
# Validate email format
# Arguments:
#   $1 - Email address
# Returns:
#   0 if valid, 1 otherwise
###############################################################################
validate_email() {
    local email="$1"
    local email_regex="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    
    if [[ ! "$email" =~ $email_regex ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi
    
    log_debug "Email validation passed: $email"
    return 0
}

###############################################################################
# Validate IP address (IPv4)
# Arguments:
#   $1 - IP address
# Returns:
#   0 if valid, 1 otherwise
###############################################################################
validate_ip_address() {
    local ip="$1"
    local ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ ! "$ip" =~ $ip_regex ]]; then
        log_error "Invalid IP address: $ip"
        return 1
    fi
    
    # Additional check: ensure octets are 0-255
    local IFS='.'
    local -a octets=($ip)
    for octet in "${octets[@]}"; do
        if [[ $octet -gt 255 ]]; then
            log_error "Invalid IP address (octet > 255): $ip"
            return 1
        fi
    done
    
    log_debug "IP address validation passed: $ip"
    return 0
}

# ============================================================================
# ERROR HANDLING FUNCTIONS
# ============================================================================

###############################################################################
# Handle error and exit with status code
# Arguments:
#   $1 - Error message
#   $2 - Exit code (optional, default 1)
# Returns:
#   Does not return (exits)
###############################################################################
handle_error() {
    local error_message="$1"
    local exit_code="${2:-1}"
    
    log_error "$error_message"
    exit "$exit_code"
}

###############################################################################
# Assert condition is true, exit if false
# Arguments:
#   $1 - Condition/Command to execute
#   $2 - Error message
#   $3 - Exit code (optional, default 1)
# Returns:
#   0 on success, exits on failure
###############################################################################
assert() {
    local condition="$1"
    local error_message="$2"
    local exit_code="${3:-1}"
    
    if ! eval "$condition"; then
        handle_error "$error_message" "$exit_code"
    fi
    
    return 0
}

###############################################################################
# Check exit code of last command
# Arguments:
#   $1 - Exit code
#   $2 - Error message
# Returns:
#   0 on success, exits on failure
###############################################################################
check_exit_code() {
    local exit_code="$1"
    local error_message="${2:-Command failed with exit code $exit_code}"
    
    if [[ $exit_code -ne 0 ]]; then
        handle_error "$error_message" "$exit_code"
    fi
    
    return 0
}

###############################################################################
# Safe command execution with error handling
# Arguments:
#   $1 - Command to execute
#   $2 - Error message on failure (optional)
# Returns:
#   0 on success, exits on failure
###############################################################################
safe_exec() {
    local command="$1"
    local error_message="${2:-Command failed: $command}"
    
    log_debug "Executing: $command"
    
    if ! eval "$command"; then
        handle_error "$error_message"
    fi
    
    return 0
}

###############################################################################
# Cleanup function (for trap)
# Arguments:
#   None
# Returns:
#   0
###############################################################################
cleanup() {
    log_info "Cleaning up resources..."
    # Add cleanup operations here
    return 0
}

###############################################################################
# Setup signal handlers for graceful shutdown
# Arguments:
#   None
# Returns:
#   0
###############################################################################
setup_signal_handlers() {
    trap cleanup EXIT
    trap 'handle_error "Script interrupted by user" 130' INT TERM
    log_debug "Signal handlers configured"
    return 0
}

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

###############################################################################
# Initialize performance monitoring
# Globals:
#   PERF_LOG_FILE, MONITORING_ENABLED
# Arguments:
#   None
# Returns:
#   0 on success
###############################################################################
init_monitoring() {
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    if [[ ! -d "$(dirname "$PERF_LOG_FILE")" ]]; then
        mkdir -p "$(dirname "$PERF_LOG_FILE")" || return 1
    fi
    
    echo "========================================" >> "$PERF_LOG_FILE"
    echo "Performance monitoring started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$PERF_LOG_FILE"
    echo "========================================" >> "$PERF_LOG_FILE"
    
    return 0
}

###############################################################################
# Start performance timer for operation
# Arguments:
#   $1 - Operation name
# Returns:
#   0
# Outputs:
#   Timer ID in TIMER_ID variable
###############################################################################
start_timer() {
    local operation="$1"
    
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    TIMER_ID="${operation}_$(date +%s%N)"
    export "TIMER_START_$TIMER_ID=$(date +%s%N)"
    
    log_debug "Timer started: $operation"
    return 0
}

###############################################################################
# End performance timer and log elapsed time
# Arguments:
#   $1 - Operation name
# Returns:
#   0
###############################################################################
end_timer() {
    local operation="$1"
    
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local timer_id="${operation}_$(date +%s%N)"
    local start_var="TIMER_START_$TIMER_ID"
    local start_time="${!start_var:-0}"
    
    if [[ $start_time -eq 0 ]]; then
        log_warn "Timer not found for operation: $operation"
        return 1
    fi
    
    local end_time=$(date +%s%N)
    local elapsed_ms=$(( (end_time - start_time) / 1000000 ))
    
    local log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] $operation: ${elapsed_ms}ms"
    echo "$log_entry" >> "$PERF_LOG_FILE"
    
    log_debug "Timer ended: $operation (${elapsed_ms}ms)"
    
    unset "TIMER_START_$TIMER_ID"
    return 0
}

###############################################################################
# Get system resource usage statistics
# Arguments:
#   None
# Returns:
#   0
# Outputs:
#   Resource stats to performance log
###############################################################################
log_system_stats() {
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu_usage=$(ps -o %cpu= -p $$)
    local mem_usage=$(ps -o %mem= -p $$)
    local virtual_mem=$(ps -o vsz= -p $$)
    local resident_mem=$(ps -o rss= -p $$)
    
    local stats="[$timestamp] CPU: ${cpu_usage}% | MEM: ${mem_usage}% | VSZ: ${virtual_mem}KB | RSS: ${resident_mem}KB"
    
    echo "$stats" >> "$PERF_LOG_FILE"
    log_debug "System stats logged"
    
    return 0
}

###############################################################################
# Log disk usage statistics
# Arguments:
#   $1 - Path to monitor (optional, default current directory)
# Returns:
#   0
###############################################################################
log_disk_usage() {
    local path="${1:-.}"
    
    if [[ "$MONITORING_ENABLED" != "true" ]]; then
        return 0
    fi
    
    if ! validate_dir_exists "$path"; then
        return 1
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local disk_usage=$(du -sh "$path" 2>/dev/null | cut -f1)
    local disk_usage_bytes=$(du -sb "$path" 2>/dev/null | cut -f1)
    
    local stats="[$timestamp] Disk usage for '$path': $disk_usage ($disk_usage_bytes bytes)"
    echo "$stats" >> "$PERF_LOG_FILE"
    
    log_debug "Disk usage logged for $path"
    return 0
}

###############################################################################
# Monitor command execution and log performance
# Arguments:
#   $1 - Operation name
#   $2 - Command to execute
# Returns:
#   Exit code of command
###############################################################################
monitor_command() {
    local operation="$1"
    local command="$2"
    
    start_timer "$operation"
    
    log_info "Starting: $operation"
    eval "$command"
    local exit_code=$?
    
    end_timer "$operation"
    
    if [[ $exit_code -eq 0 ]]; then
        log_info "Completed: $operation"
    else
        log_error "Failed: $operation (exit code: $exit_code)"
    fi
    
    log_system_stats
    
    return "$exit_code"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

###############################################################################
# Print formatted header
# Arguments:
#   $1 - Header text
# Returns:
#   0
###############################################################################
print_header() {
    local text="$1"
    local length=${#text}
    local padding=$(( (80 - length - 2) / 2 ))
    
    echo ""
    printf "%${padding}s" | tr ' ' '='
    echo " $text "
    printf "%${padding}s" | tr ' ' '='
    echo ""
}

###############################################################################
# Print formatted section
# Arguments:
#   $1 - Section name
# Returns:
#   0
###############################################################################
print_section() {
    local section="$1"
    echo ""
    echo -e "${BLUE}>>> $section${NC}"
    echo ""
}

###############################################################################
# Retry command with exponential backoff
# Arguments:
#   $1 - Maximum retry count
#   $2 - Initial delay in seconds
#   $3 - Command to execute
# Returns:
#   Exit code of command
###############################################################################
retry_with_backoff() {
    local max_retries="$1"
    local initial_delay="$2"
    shift 2
    local command="$@"
    
    local attempt=1
    local delay=$initial_delay
    
    while [[ $attempt -le $max_retries ]]; do
        log_info "Attempt $attempt/$max_retries: $command"
        
        if eval "$command"; then
            log_info "Command succeeded on attempt $attempt"
            return 0
        fi
        
        if [[ $attempt -lt $max_retries ]]; then
            log_warn "Attempt $attempt failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$(( delay * 2 ))
        fi
        
        attempt=$(( attempt + 1 ))
    done
    
    log_error "Command failed after $max_retries attempts"
    return 1
}

###############################################################################
# Get script version
# Arguments:
#   None
# Returns:
#   Version string
###############################################################################
get_version() {
    echo "Utils.sh v1.0.0"
}

###############################################################################
# Display help/usage information
# Arguments:
#   None
# Returns:
#   0
###############################################################################
show_help() {
    cat << EOF
Utils.sh - Utility Script with Helper Functions

USAGE:
    source Utils.sh

FUNCTIONS:
    Logging:
        log_debug <message>          - Log debug message
        log_info <message>           - Log info message
        log_warn <message>           - Log warning message
        log_error <message>          - Log error message
        init_logging                 - Initialize logging system

    Validation:
        validate_not_empty <name> <value>     - Validate variable not empty
        validate_file_exists <path>           - Check if file exists
        validate_dir_exists <path>            - Check if directory exists
        validate_command_exists <cmd>         - Check if command exists
        validate_number <value> [min] [max]   - Validate numeric value
        validate_email <email>                - Validate email format
        validate_ip_address <ip>              - Validate IPv4 address

    Error Handling:
        handle_error <msg> [code]    - Log error and exit
        assert <condition> <msg> [code] - Assert condition
        check_exit_code <code> [msg] - Check exit code
        safe_exec <cmd> [msg]        - Execute command safely
        setup_signal_handlers        - Setup signal traps

    Monitoring:
        init_monitoring              - Initialize monitoring
        start_timer <operation>      - Start performance timer
        end_timer <operation>        - End performance timer
        log_system_stats             - Log system resource usage
        log_disk_usage [path]        - Log disk usage
        monitor_command <op> <cmd>   - Monitor command execution

    Utility:
        print_header <text>          - Print formatted header
        print_section <name>         - Print formatted section
        retry_with_backoff <max> <delay> <cmd> - Retry with backoff
        get_version                  - Get script version
        show_help                    - Display this help

ENVIRONMENT VARIABLES:
    LOG_FILE                - Path to log file (default: ./utils.log)
    LOG_LEVEL               - Log level: DEBUG, INFO, WARN, ERROR (default: INFO)
    MONITORING_ENABLED      - Enable monitoring (default: true)
    PERF_LOG_FILE           - Path to performance log (default: ./performance.log)

EXAMPLES:
    source ./Utils.sh
    init_logging
    init_monitoring
    setup_signal_handlers

    log_info "Starting process"
    validate_file_exists "/path/to/file" || exit 1
    
    monitor_command "data_processing" "process_data.sh"
    
    retry_with_backoff 3 2 "curl -s https://example.com"

EOF
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Only run initialization if script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    log_debug "Utils.sh loaded successfully"
fi

