#!/bin/bash

################################################################################
# Utils.sh - Enhanced Utility Script with Helper Functions
#
# This script provides reusable helper functions for:
# - Configuration management
# - Validation
# - Logging with rotation
# - Error Handling & Recovery
# - Monitoring & Performance
# - Device detection
#
# Created: 2025-12-07
# Author: disa12311
################################################################################

set -euo pipefail

# ============================================================================
# GLOBAL VARIABLES
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/Config.conf"

# Source configuration file if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Warning: Config. conf not found at $CONFIG_FILE" >&2
fi

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Declare associative arrays for caching
declare -A DEVICE_CACHE
declare -A COMMAND_CACHE
declare -A TIMER_CACHE

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

###############################################################################
# Load configuration from Config.conf
# Arguments:
#   None
# Returns:
#   0 on success, 1 on failure
###############################################################################
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Validate config file syntax
    if ! bash -n "$CONFIG_FILE" 2>/dev/null; then
        log_error "Configuration file has syntax errors: $CONFIG_FILE"
        return 1
    fi
    
    source "$CONFIG_FILE"
    log_debug "Configuration loaded from: $CONFIG_FILE"
    return 0
}

###############################################################################
# Get configuration value with fallback
# Arguments:
#   $1 - Config key
#   $2 - Default value (optional)
# Returns:
#   Configuration value
###############################################################################
get_config() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -v "$key" ]]; then
        echo "${!key}"
    else
        echo "$default"
    fi
}

###############################################################################
# Set configuration value
# Arguments:
#   $1 - Config key
#   $2 - Config value
# Returns:
#   0 on success
###############################################################################
set_config() {
    local key="$1"
    local value="$2"
    
    export "$key=$value"
    log_debug "Configuration updated: $key=$value"
    return 0
}

###############################################################################
# Validate configuration
# Arguments:
#   None
# Returns:
#   0 if valid, 1 otherwise
###############################################################################
validate_config() {
    log_info "Validating configuration..."
    
    local errors=0
    
    # Validate required directories
    for dir in LOG_ROOT_DIR BACKUP_ROOT_DIR CACHE_ROOT_DIR; do
        if [[ -z "${!dir:-}" ]]; then
            log_error "Configuration error: $dir is not set"
            ((errors++))
        fi
    done
    
    # Validate numeric values
    for num_var in TARGET_FPS MIN_FPS MAX_FPS LOG_MAX_SIZE MONITORING_INTERVAL; do
        if !  validate_number "${!num_var:-0}" 2>/dev/null; then
            log_error "Configuration error: $num_var must be numeric"
            ((errors++))
        fi
    done
    
    # Validate boolean values
    for bool_var in MONITORING_ENABLED DEBUG_MODE DRY_RUN_MODE; do
        local value="${!bool_var:-}"
        if [[ "$value" != "true" && "$value" != "false" ]]; then
            log_error "Configuration error: $bool_var must be true or false"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_info "Configuration validation passed"
        return 0
    else
        log_error "Configuration validation failed with $errors error(s)"
        return 1
    fi
}

# ============================================================================
# LOGGING FUNCTIONS WITH ROTATION
# ============================================================================

###############################################################################
# Initialize logging system with rotation support
# Arguments:
#   None
# Returns:
#   0 on success
###############################################################################
init_logging() {
    local log_dir="$(get_config LOG_ROOT_DIR ./logs)"
    
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || return 1
    fi
    
    local log_file="$(get_config LOG_FILE $log_dir/module.log)"
    
    # Rotate logs if needed
    rotate_logs "$log_file"
    
    echo "========================================" >> "$log_file"
    echo "Log initialized at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"
    echo "Log Level: $(get_config LOG_LEVEL INFO)" >> "$log_file"
    echo "Config: $CONFIG_FILE" >> "$log_file"
    echo "========================================" >> "$log_file"
    
    log_debug "Logging system initialized"
    return 0
}

###############################################################################
# Rotate log files based on size
# Arguments:
#   $1 - Log file path
# Returns:
#   0 on success
###############################################################################
rotate_logs() {
    local log_file="$1"
    local max_size=$(get_config LOG_MAX_SIZE 100)
    local rotate_count=$(get_config LOG_ROTATE_COUNT 5)
    
    # Skip rotation if max_size is 0 (unlimited)
    [[ $max_size -eq 0 ]] && return 0
    
    # Check if log file exists and exceeds max size
    if [[ -f "$log_file" ]]; then
        local file_size_mb=$(( $(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0) / 1024 / 1024 ))
        
        if [[ $file_size_mb -gt $max_size ]]; then
            # Rotate existing logs
            for ((i = rotate_count - 1; i > 0; i--)); do
                if [[ -f "${log_file}.$i" ]]; then
                    mv "${log_file}.$i" "${log_file}.$((i + 1))"
                fi
            done
            
            # Move current log to . 1
            mv "$log_file" "${log_file}.1"
            log_debug "Rotated log file: $log_file (size: ${file_size_mb}MB)"
        fi
    fi
    
    return 0
}

###############################################################################
# Log message with timestamp, level, and optional context
# Arguments:
#   $1 - Log level (DEBUG, INFO, WARN, ERROR)
#   $2 - Message
#   $3 - Context/Category (optional)
# Returns:
#   0 on success
###############################################################################
log_message() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_level="$(get_config LOG_LEVEL INFO)"
    local log_file="$(get_config LOG_FILE ./logs/module. log)"
    
    # Check if message should be logged based on log level
    case "$log_level" in
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
    
    # Format log entry
    local context_str=""
    [[ -n "$context" ]] && context_str=" [$context]"
    local log_entry="[$timestamp] [$level]$context_str $message"
    
    # Create log directory if needed
    mkdir -p "$(dirname "$log_file")" 2>/dev/null || true
    
    # Append to log file
    echo "$log_entry" >> "$log_file"
    
    # Also print to console with colors
    case "$level" in
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC}$context_str $message" >&2
            ;;
        INFO)
            echo -e "${GREEN}[INFO]${NC}$context_str $message"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC}$context_str $message" >&2
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC}$context_str $message" >&2
            ;;
    esac
    
    return 0
}

# Convenience logging functions
log_debug() {
    log_message "DEBUG" "$1" "${2:-}"
}

log_info() {
    log_message "INFO" "$1" "${2:-}"
}

log_warn() {
    log_message "WARN" "$1" "${2:-}"
}

log_error() {
    log_message "ERROR" "$1" "${2:-}"
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
# Validate that a command/binary exists
# Arguments:
#   $1 - Command name
# Returns:
#   0 if command exists, 1 otherwise
###############################################################################
validate_command_exists() {
    local command="$1"
    
    if !  command -v "$command" &>/dev/null; then
        log_error "Command not found: $command"
        return 1
    fi
    
    log_debug "Command found: $command"
    return 0
}

###############################################################################
# Validate numeric value with optional range
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
    
    if !  [[ "$value" =~ ^-?[0-9]+$ ]]; then
        log_error "Not a valid number: $value"
        return 1
    fi
    
    if [[ -n "$min" && $value -lt $min ]]; then
        log_error "Value $value is less than minimum $min"
        return 1
    fi
    
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
    
    if [[ !  "$email" =~ $email_regex ]]; then
        log_error "Invalid email format: $email"
        return 1
    fi
    
    log_debug "Email validation passed: $email"
    return 0
}

###############################################################################
# Validate IPv4 address
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
# ERROR HANDLING & RECOVERY
# ============================================================================

###############################################################################
# Handle error with logging and optional recovery
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
    
    # Execute error hook if defined
    local error_hook="$(get_config ERROR_HOOK)"
    if [[ -n "$error_hook" && -f "$error_hook" ]]; then
        log_debug "Executing error hook: $error_hook"
        bash "$error_hook" 2>/dev/null || true
    fi
    
    # Auto rollback if enabled
    if [[ "$(get_config AUTO_ROLLBACK true)" == "true" ]]; then
        log_warn "Attempting automatic rollback..."
        perform_rollback
    fi
    
    exit "$exit_code"
}

###############################################################################
# Assert condition and handle failure
# Arguments:
#   $1 - Condition/Command
#   $2 - Error message
#   $3 - Exit code (optional)
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
# Check exit code and handle error
# Arguments:
#   $1 - Exit code
#   $2 - Error message (optional)
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
# Execute command safely with error handling
# Arguments:
#   $1 - Command to execute
#   $2 - Error message (optional)
# Returns:
#   Exit code of command
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
# Perform rollback from backup
# Arguments:
#   None
# Returns:
#   0 on success, 1 on failure
###############################################################################
perform_rollback() {
    local backup_dir="$(get_config ROLLBACK_BACKUP_DIR ./backups)"
    
    if [[ !  -d "$backup_dir" ]]; then
        log_warn "No backup directory found: $backup_dir"
        return 1
    fi
    
    local latest_backup=$(ls -t "$backup_dir" 2>/dev/null | head -n1)
    
    if [[ -z "$latest_backup" ]]; then
        log_warn "No backups found in: $backup_dir"
        return 1
    fi
    
    log_info "Performing rollback from: $latest_backup"
    # Add rollback logic here based on your backup format
    
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

###############################################################################
# Cleanup function called on exit
# Arguments:
#   None
# Returns:
#   0
###############################################################################
cleanup() {
    log_info "Cleaning up resources..."
    
    # Execute post-operation hooks
    local post_hook="$(get_config POST_APPLY_HOOK)"
    if [[ -n "$post_hook" && -f "$post_hook" ]]; then
        log_debug "Executing post-operation hook: $post_hook"
        bash "$post_hook" 2>/dev/null || true
    fi
    
    return 0
}

# ============================================================================
# DEVICE DETECTION & CACHING
# ============================================================================

###############################################################################
# Get device information with caching
# Arguments:
#   None
# Returns:
#   0 on success
###############################################################################
get_device_info() {
    local cache_enabled="$(get_config CACHE_DEVICE_INFO true)"
    local cache_file="$(get_config DEVICE_INFO_CACHE ./cache/device_info.cache)"
    
    # Load from cache if enabled
    if [[ "$cache_enabled" == "true" && -f "$cache_file" ]]; then
        log_debug "Loading device info from cache"
        source "$cache_file"
        return 0
    fi
    
    log_info "Detecting device information..."
    
    # Get device properties
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    DEVICE_BRAND=$(getprop ro.product. system.brand 2>/dev/null || echo "Unknown")
    DEVICE_BUILD=$(getprop ro.build. product 2>/dev/null || echo "Unknown")
    DEVICE_KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
    DEVICE_GPU=$(getprop ro.hardware.egl 2>/dev/null || echo "Unknown")
    DEVICE_CPU=$(getprop ro.hardware 2>/dev/null || echo "Unknown")
    DEVICE_ANDROID=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    DEVICE_FINGERPRINT=$(getprop ro.build.fingerprint 2>/dev/null || echo "Unknown")
    
    # Cache the information
    if [[ "$cache_enabled" == "true" ]]; then
        mkdir -p "$(dirname "$cache_file")" 2>/dev/null || true
        cat > "$cache_file" << EOF
# Device info cache - generated $(date)
DEVICE_MODEL="$DEVICE_MODEL"
DEVICE_BRAND="$DEVICE_BRAND"
DEVICE_BUILD="$DEVICE_BUILD"
DEVICE_KERNEL="$DEVICE_KERNEL"
DEVICE_GPU="$DEVICE_GPU"
DEVICE_CPU="$DEVICE_CPU"
DEVICE_ANDROID="$DEVICE_ANDROID"
DEVICE_FINGERPRINT="$DEVICE_FINGERPRINT"
EOF
        log_debug "Device info cached to: $cache_file"
    fi
    
    return 0
}

###############################################################################
# Display device information
# Arguments:
#   None
# Returns:
#   0
###############################################################################
show_device_info() {
    get_device_info
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▎ Device Information${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Model:       ${GREEN}$DEVICE_MODEL${NC}"
    echo -e "Brand:       ${GREEN}$DEVICE_BRAND${NC}"
    echo -e "Build:       ${GREEN}$DEVICE_BUILD${NC}"
    echo -e "Kernel:      ${GREEN}$DEVICE_KERNEL${NC}"
    echo -e "GPU:         ${GREEN}$DEVICE_GPU${NC}"
    echo -e "CPU:         ${GREEN}$DEVICE_CPU${NC}"
    echo -e "Android:     ${GREEN}$DEVICE_ANDROID${NC}"
    echo -e "Fingerprint: ${GREEN}$DEVICE_FINGERPRINT${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ============================================================================
# MONITORING FUNCTIONS
# ============================================================================

###############################################################################
# Initialize performance monitoring
# Arguments:
#   None
# Returns:
#   0 on success
###############################################################################
init_monitoring() {
    local monitoring_enabled="$(get_config MONITORING_ENABLED true)"
    
    if [[ "$monitoring_enabled" != "true" ]]; then
        return 0
    fi
    
    local perf_log_dir="$(dirname "$(get_config PERF_LOG_FILE ./logs/performance.log)")"
    
    if [[ ! -d "$perf_log_dir" ]]; then
        mkdir -p "$perf_log_dir" || return 1
    fi
    
    local perf_log_file="$(get_config PERF_LOG_FILE)"
    
    echo "========================================" >> "$perf_log_file"
    echo "Performance monitoring started at: $(date '+%Y-%m-%d %H:%M:%S')" >> "$perf_log_file"
    echo "Config: $CONFIG_FILE" >> "$perf_log_file"
    echo "========================================" >> "$perf_log_file"
    
    log_debug "Monitoring system initialized"
    return 0
}

###############################################################################
# Start performance timer
# Arguments:
#   $1 - Operation name
# Returns:
#   Timer ID
###############################################################################
start_timer() {
    local operation="$1"
    local monitoring_enabled="$(get_config MONITORING_ENABLED true)"
    
    if [[ "$monitoring_enabled" != "true" ]]; then
        return 0
    fi
    
    local timer_id="${operation}_$$_$(date +%s%N)"
    local start_time=$(date +%s%N)
    
    TIMER_CACHE["$timer_id"]=$start_time
    export CURRENT_TIMER_ID="$timer_id"
    
    log_debug "Timer started: $operation (ID: $timer_id)"
    echo "$timer_id"
}

###############################################################################
# End performance timer and log results
# Arguments:
#   $1 - Operation name
#   $2 - Timer ID (optional)
# Returns:
#   0
###############################################################################
end_timer() {
    local operation="$1"
    local timer_id="${2:-$CURRENT_TIMER_ID}"
    local monitoring_enabled="$(get_config MONITORING_ENABLED true)"
    
    if [[ "$monitoring_enabled" != "true" ]]; then
        return 0
    fi
    
    if [[ -z "$timer_id" || -z "${TIMER_CACHE[$timer_id]:-}" ]]; then
        log_warn "Timer not found: $timer_id"
        return 1
    fi
    
    local start_time="${TIMER_CACHE[$timer_id]}"
    local end_time=$(date +%s%N)
    local elapsed_ms=$(( (end_time - start_time) / 1000000 ))
    
    local perf_log_file="$(get_config PERF_LOG_FILE)"
    local log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] $operation: ${elapsed_ms}ms"
    
    echo "$log_entry" >> "$perf_log_file"
    log_debug "Timer ended: $operation (${elapsed_ms}ms)"
    
    unset TIMER_CACHE["$timer_id"]
    return 0
}

###############################################################################
# Log system resource usage
# Arguments:
#   None
# Returns:
#   0
###############################################################################
log_system_stats() {
    local monitoring_enabled="$(get_config MONITORING_ENABLED true)"
    local perf_log_file="$(get_config PERF_LOG_FILE)"
    
    if [[ "$monitoring_enabled" != "true" ]]; then
        return 0
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local cpu_usage=$(ps -o %cpu= -p $$ 2>/dev/null || echo "0")
    local mem_usage=$(ps -o %mem= -p $$ 2>/dev/null || echo "0")
    local virtual_mem=$(ps -o vsz= -p $$ 2>/dev/null || echo "0")
    local resident_mem=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    
    local stats="[$timestamp] CPU: ${cpu_usage}% | MEM: ${mem_usage}% | VSZ: ${virtual_mem}KB | RSS: ${resident_mem}KB"
    
    echo "$stats" >> "$perf_log_file"
    log_debug "System stats logged"
    
    return 0
}

###############################################################################
# Monitor command execution
# Arguments:
#   $1 - Operation name
#   $2 - Command to execute
# Returns:
#   Exit code of command
###############################################################################
monitor_command() {
    local operation="$1"
    local command="$2"
    
    local timer_id=$(start_timer "$operation")
    
    log_info "Starting: $operation"
    eval "$command"
    local exit_code=$? 
    
    end_timer "$operation" "$timer_id"
    log_system_stats
    
    if [[ $exit_code -eq 0 ]]; then
        log_info "Completed: $operation"
    else
        log_error "Failed: $operation (exit code: $exit_code)"
    fi
    
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
    local width=80
    local padding=$(( (width - length - 2) / 2 ))
    
    echo ""
    printf "%-${width}s\n" | tr ' ' '='
    printf "%${padding}s %s %${padding}s\n" "" "$text" ""
    printf "%-${width}s\n" | tr ' ' '='
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
#   $3+ - Command to execute
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
# Display progress bar
# Arguments:
#   $1 - Current progress (0-100)
#   $2 - Label (optional)
# Returns:
#   0
###############################################################################
show_progress() {
    local progress="$1"
    local label="${2:-Processing}"
    local show_bar="$(get_config SHOW_PROGRESS_BAR true)"
    
    if [[ "$show_bar" != "true" ]]; then
        return 0
    fi
    
    local bar_length=40
    local filled=$(( progress * bar_length / 100 ))
    local empty=$(( bar_length - filled ))
    
    printf "\r${label} ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$progress"
}

###############################################################################
# Get script version
# Arguments:
#   None
# Returns:
#   Version string
###############################################################################
get_version() {
    echo "Utils. sh v$(get_config MODULE_VERSION 3. 0)"
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
${GREEN}Utils.sh - Enhanced Utility Script with Configuration Management${NC}

${BLUE}USAGE:${NC}
    source Utils.sh

${BLUE}FUNCTIONS:${NC}

${GREEN}Configuration:${NC}
    load_config                  - Load Config.conf
    get_config <key> [default]   - Get configuration value
    set_config <key> <value>     - Set configuration value
    validate_config              - Validate configuration

${GREEN}Logging:${NC}
    init_logging                 - Initialize logging system
    log_debug <msg>              - Log debug message
    log_info <msg>               - Log info message
    log_warn <msg>               - Log warning message
    log_error <msg>              - Log error message

${GREEN}Validation:${NC}
    validate_not_empty <name> <val> - Validate variable not empty
    validate_file_exists <path>     - Check if file exists
    validate_dir_exists <path>      - Check if directory exists
    validate_command_exists <cmd>   - Check if command exists
    validate_number <val> [min] [max] - Validate numeric value
    validate_email <email>          - Validate email format
    validate_ip_address <ip>        - Validate IPv4 address

${GREEN}Error Handling:${NC}
    handle_error <msg> [code]    - Log error and exit
    assert <condition> <msg> [code] - Assert condition
    check_exit_code <code> [msg] - Check exit code
    safe_exec <cmd> [msg]        - Execute command safely
    setup_signal_handlers        - Setup signal traps
    perform_rollback             - Perform rollback

${GREEN}Device:${NC}
    get_device_info              - Get device information (cached)
    show_device_info             - Display device information

${GREEN}Monitoring:${NC}
    init_monitoring              - Initialize monitoring
    start_timer <operation>      - Start performance timer
    end_timer <operation> [id]   - End performance timer
    log_system_stats             - Log system resource usage
    monitor_command <op> <cmd>   - Monitor command execution

${GREEN}Utility:${NC}
    print_header <text>          - Print formatted header
    print_section <name>         - Print formatted section
    show_progress <0-100> [label] - Display progress bar
    retry_with_backoff <max> <delay> <cmd> - Retry with backoff
    get_version                  - Get script version
    show_help                    - Display this help

${BLUE}ENVIRONMENT VARIABLES:${NC}
    All settings are configured in Config.conf

${BLUE}EXAMPLES:${NC}
    source ./Utils.sh
    load_config
    validate_config
    init_logging
    init_monitoring
    setup_signal_handlers
    
    log_info "Starting process"
    validate_file_exists "/path/to/file" || exit 1
    
    timer=$(start_timer "my_operation")
    # ... do work ...
    end_timer "my_operation" "$timer"
    
    retry_with_backoff 3 2 "curl -s https://example.com"

EOF
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Only run initialization if script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Load and validate configuration
    load_config || log_warn "Using default configuration"
    log_debug "Utils.sh v$(get_config MODULE_VERSION 3.0) loaded successfully"
fi
