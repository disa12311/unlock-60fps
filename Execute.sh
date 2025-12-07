#!/bin/sh

# Enable strict error handling
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
  echo "▶ Version : 3.0 (60FPS Optimized + SDR Reload) "
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
  echo " ▶ PROCESSING......"
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

# Apply 60 FPS settings
apply_60fps_settings() {
  log_info "Applying 60 FPS settings..."
  
  # System settings
  settings put system peak_refresh_rate 60
  settings put system user_refresh_rate 60
  settings put system min_refresh_rate 60
  settings put system thermal_limit_refresh_rate 60
  settings put system miui_refresh_rate 60
  settings put system ext_force_refresh_rate_list 60
  settings put system db_screen_rate 1
  settings put system framepredict_enable 1
  settings put system is_smart_fps 0
  settings put system screen_optimize_mode 1
  
  # Secure settings
  settings put secure user_refresh_rate 60
  settings put secure max_refresh_rate 60
  settings put secure miui_refresh_rate 60
  settings put secure match_content_frame_rate 1
  settings put secure refresh_rate_mode 1
  
  log_info "60 FPS settings applied successfully"
}

# Apply hardware UI properties
apply_hwui_props() {
  log_info "Applying hardware UI optimizations..."
  
  setprop debug. hwui.profile. maxframes 60
  setprop debug.hwui.fpslimit 60
  setprop debug.hwui.fps_limit 60
  setprop debug.display.allow_non_native_refresh_rate_override true
  setprop debug.display.render_frame_rate_is_physical_refresh_rate true
  setprop debug.sf.frame_rate_multiple_threshold 60
  setprop debug.sf.scroll_boost_refreshrate 60
  setprop debug.sf.touch_boost_refreshrate 60
  setprop debug.refresh_rate. min_fps 60
  setprop debug.refresh_rate.max_fps 60
  setprop debug.refresh_rate. peak_fps 60
  setprop debug.graphics.game_default_frame_rate. disabled true
  
  log_info "Hardware UI optimizations applied"
}

# Apply performance optimizations
apply_performance_boost() {
  log_info "Applying performance boost..."
  
  cmd display set-match-content-frame-rate-pref 0 2>/dev/null || true
  cmd power set-fixed-performance-mode-enabled true 2>/dev/null || true
  cmd thermalservice override-status 0 2>/dev/null || true
  
  log_info "Performance boost applied"
}

# Apply V-Sync disabling
disable_vsync() {
  log_info "Disabling V-Sync..."
  
  setprop debug.hwui.disable_vsync true
  setprop debug.egl.swapinterval 0
  setprop debug.gr.swapinterval 0
  setprop debug.sf.swapinterval 0
  setprop debug.gl.swapinterval 0
  setprop debug.cpurend.vsync false
  setprop debug.gpurend.vsync false
  setprop debug.sf.latch_to_present false
  setprop debug.hwc.force_cpu_vsync false
  setprop debug.hwc.force_gpu_vsync false
  setprop debug.hwc. enable_vsync false
  setprop debug.hwc.disable_vsync true
  setprop debug.logvsync 0
  setprop debug.hwc.vsync_interval 0
  setprop debug.hwc.vsync_source 0
  setprop debug.sf.no_hw_vsync 1
  setprop debug. hwc.fakevsync 0
  
  log_info "V-Sync disabled"
}

# Apply renderer & UI optimizations
apply_renderer_optimization() {
  log_info "Applying renderer optimizations..."
  
  setprop debug.sf.disable_backpressure 1
  setprop debug. sf.latch_unsignaled 1
  setprop debug. sf.enable_hwc_vds 0
  setprop debug.sf.early_phase_offset_ns 500000
  setprop debug. sf.early_app_phase_offset_ns 500000
  setprop debug. sf.early_gl_phase_offset_ns 3000000
  setprop debug.sf.early_gl_app_phase_offset_ns 15000000
  setprop debug.sf.high_fps_early_phase_offset_ns 6100000
  setprop debug. sf.high_fps_early_gl_phase_offset_ns 650000
  setprop debug. sf.high_fps_late_app_phase_offset_ns 100000
  setprop debug. sf.phase_offset_threshold_for_next_vsync_ns 6100000
  setprop debug.sf.showupdates 0
  setprop debug. sf.showcpu 0
  setprop debug.sf.showbackground 0
  setprop debug.sf.showfps 0
  setprop debug. sf.hw 1
  setprop debug.performance.accoustic. force true
  setprop debug.performance.cap 60
  setprop debug.performance.disturb true
  setprop debug.performance.tuning 1
  setprop debug.performance_schema 1
  setprop debug. performance_schema_max_memory_classes 1000
  setprop debug.performance_schema_max_socket_classes 10
  setprop debug.performance. force_fps 2
  setprop debug.performance.gpu_boost 1
  setprop debug.profiler.target_performance_percent 100
  
  log_info "Renderer optimizations applied"
}

# Apply game mode settings for 3rd party apps
apply_game_mode() {
  log_info "Configuring game mode for third-party apps..."
  
  # Count 3rd party packages
  pkg_count=$(pm list packages -3 2>/dev/null | wc -l)
  log_info "Found $pkg_count third-party applications"
  
  # Apply device config
  for pkg in $(pm list packages -3 2>/dev/null | cut -f2 -d:); do
    device_config put game_overlay "$pkg" mode=2,fps=60:mode=3,fps=60 2>/dev/null || true
  done
  
  # Apply game commands
  for pkg in $(pm list packages -3 2>/dev/null | cut -f2 -d:); do
    cmd game set --mode performance --fps 60 "$pkg" 2>/dev/null || true
  done
  
  log_info "Game mode configuration applied to all apps"
}

# Reload SDR (SurfaceFlinger Display Rendering)
reload_sdr() {
  log_info "Reloading SDR (SurfaceFlinger Display Rendering)..."
  
  if pidof surfaceflinger >/dev/null 2>&1; then
    svc=$(pidof surfaceflinger)
    kill -HUP $svc 2>/dev/null && log_info "SurfaceFlinger reloaded via SIGHUP" || log_warn "Failed to reload SurfaceFlinger"
  else
    # Fallback to service call
    service call SurfaceFlinger 33 >/dev/null 2>&1 && log_info "SurfaceFlinger reloaded via service call" || log_warn "SurfaceFlinger reload method unavailable"
  fi
  
  sleep 1
}

# Send notification
send_notification() {
  cmd notification post -S bigtext -t '🚀 60FPS Module - JordanTweaks' 'Tag' 'ACTIVATED! !' >/dev/null 2>&1 || true
}

# Main execution
main() {
  show_header
  show_device_info
  show_progress_bar
  
  log_info "Starting 60FPS optimization module..."
  echo ""
  
  # Apply all optimizations in sequence
  apply_60fps_settings
  apply_hwui_props
  apply_performance_boost
  disable_vsync
  apply_renderer_optimization
  apply_game_mode
  reload_sdr
  
  echo ""
  log_info "Module successfully flashed (60FPS + SDR Reload)"
  sleep 1
  
  send_notification
  
  echo ""
  echo " ✓ OPTIMIZATION COMPLETE"
  echo " ✓ SUBSCRIBE | LIKE | SHARE | COMMENT"
  echo ""
  echo " ⚠ DO NOT REBOOT YOUR PHONE YET"
  echo ""
}

# Execute main function
main
