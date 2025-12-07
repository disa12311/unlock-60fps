#!/bin/sh

# Enable strict error handling
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
  echo "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo "${RED}[ERROR]${NC} $1"
}

# Header display
show_header() {
  echo "[ 𝗜𝗻𝗳𝗼𝗿𝗺𝗮𝘁𝗶𝗼𝗻🔥 ] "
  echo "▶ Version : 3.0 (60FPS Removal + SDR Reset) "
  echo "▶ Status : No Root "
  sleep 1
  echo ""
  echo "█▀▀▀ █▀▀█ ░█▀▀▀ ░█▀▀█ ░█▀▀▀█"
  echo "█▀▀▄ █▄▀█ ░█▀▀▀ ░█▄▄█ ─▀▀▀▄▄"
  echo "█▄▄█ █▄▄█ ░█─── ░█─── ░█▄▄▄█"
  echo ""
  sleep 1
}

# Display device information
show_device_info() {
  echo "▎𝗗𝗲𝘃𝗶𝗰𝗲 𝗜𝗻𝗳𝗼📱"
  sleep 0.3
  
  device=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
  brand=$(getprop ro.product.system.brand 2>/dev/null || echo "Unknown")
  model=$(getprop ro.build.product 2>/dev/null || echo "Unknown")
  kernel=$(uname -r 2>/dev/null || echo "Unknown")
  gpu=$(getprop ro.hardware.egl 2>/dev/null || echo "Unknown")
  cpu=$(getprop ro.hardware 2>/dev/null || echo "Unknown")
  android_version=$(getprop ro. build.version.release 2>/dev/null || echo "Unknown")
  
  echo "▎ DEVICE: $device"
  sleep 0.2
  echo "▎ BRAND: $brand"
  sleep 0. 2
  echo "▎ MODEL: $model"
  sleep 0.2
  echo "▎ KERNEL: $kernel"
  sleep 0.2
  echo "▎ GPU: $gpu"
  sleep 0.2
  echo "▎ CPU: $cpu"
  sleep 0.2
  echo "▎ ANDROID: $android_version"
  sleep 1
}

# Progress bar display
show_progress_bar() {
  echo ""
  echo " ▶ PROCESSING... ..."
  sleep 1
  echo " ▶ WAITING......"
  sleep 2
  echo ""
  
  for i in $(seq 1 10); do
    percent=$((i * 10))
    bar=""
    for j in $(seq 1 $i); do
      bar="${bar}█"
    done
    for k in $(seq $((i+1)) 10); do
      bar="${bar}░"
    done
    printf "  [$bar] %3d%%\r" "$percent"
    sleep 0. 4
  done
  echo ""
  echo ""
}

# Revert 60 FPS settings
revert_60fps_settings() {
  log_info "Reverting 60 FPS settings..."
  
  # System settings
  settings put system peak_refresh_rate null
  settings put system user_refresh_rate null
  settings put system min_refresh_rate null
  settings put system thermal_limit_refresh_rate null
  settings put system miui_refresh_rate null
  settings put system ext_force_refresh_rate_list null
  settings put system db_screen_rate null
  settings put system framepredict_enable null
  settings put system is_smart_fps null
  settings put system screen_optimize_mode null
  
  # Secure settings
  settings put secure user_refresh_rate null
  settings put secure max_refresh_rate null
  settings put secure miui_refresh_rate null
  settings put secure match_content_frame_rate null
  settings put secure refresh_rate_mode null
  
  log_info "60 FPS settings reverted"
}

# Revert performance settings
revert_performance_settings() {
  log_info "Reverting performance settings..."
  
  cmd display set-match-content-frame-rate-pref 1 2>/dev/null || true
  cmd power set-fixed-performance-mode-enabled false 2>/dev/null || true
  cmd thermalservice reset 2>/dev/null || true
  
  log_info "Performance settings reverted"
}

# Reload SDR to reset rendering
reload_sdr_reset() {
  log_info "Reloading SDR to reset rendering..."
  
  if pidof surfaceflinger >/dev/null 2>&1; then
    svc=$(pidof surfaceflinger)
    kill -HUP $svc 2>/dev/null && log_info "SurfaceFlinger reset via SIGHUP" || log_warn "Failed to reset SurfaceFlinger"
  else
    service call SurfaceFlinger 33 >/dev/null 2>&1 && log_info "SurfaceFlinger reset via service call" || log_warn "SurfaceFlinger reset method unavailable"
  fi
  
  sleep 1
}

# Send notification
send_notification() {
  cmd notification post -S bigtext -t '🚀 60FPS Module - JordanTweaks' 'Tag' 'DELETED! !' >/dev/null 2>&1 || true
}

# Main execution
main() {
  show_header
  show_device_info
  show_progress_bar
  
  log_info "Starting 60FPS removal module..."
  echo ""
  
  # Revert all optimizations in reverse order
  revert_60fps_settings
  revert_performance_settings
  reload_sdr_reset
  
  echo ""
  log_info "Module successfully removed (60FPS + SDR Reset)"
  sleep 1
  
  send_notification
  
  echo ""
  echo " ✓ REMOVAL COMPLETE"
  echo " ✓ SUBSCRIBE | LIKE | SHARE | COMMENT"
  echo ""
  echo " ⚠ REBOOT YOUR PHONE TO APPLY CHANGES"
  echo ""
}

# Execute main function
main
