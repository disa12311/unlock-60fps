#!/system/bin/sh

# ============================================
# 60FPS Smart Revert v3.0
# ============================================

MODPATH="/sdcard/60FPS"
LOG_FILE="$MODPATH/deletion.log"
CONFIG_FILE="$MODPATH/device_config.conf"
BACKUP_FILE="$MODPATH/original_settings.bak"

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

clear
echo "╔═══════════════════════════════════════╗"
echo "║   🔄 60FPS SMART REVERT v3.0         ║"
echo "╚═══════════════════════════════════════╝"
log "Starting Smart Revert Process"

# Load previous config if exists
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    echo "📁 Found previous configuration"
    echo "   • Target was: $TARGET_FPS FPS"
    echo "   • Device tier: $DEVICE_TIER"
else
    echo "⚠️  No config found, using default revert"
    TARGET_FPS=60
fi
echo ""

# Progress bar
echo "⏳ Reverting optimizations..."
for i in $(seq 1 10); do
    echo -n "■"
    sleep 0.2
done
echo " 100%"
echo ""

(
# ============================================
# I. REVERT DISPLAY SETTINGS
# ============================================
log "Reverting display settings..."

# Remove all refresh rate overrides
settings delete system peak_refresh_rate
settings delete system user_refresh_rate
settings delete system min_refresh_rate
settings delete system thermal_limit_refresh_rate
settings delete system miui_refresh_rate
settings delete secure user_refresh_rate
settings delete secure max_refresh_rate
settings delete secure match_content_frame_rate
settings delete secure refresh_rate_mode
settings delete system ext_force_refresh_rate_list
settings delete system db_screen_rate
settings delete system framepredict_enable
settings delete system is_smart_fps
settings delete system screen_optimize_mode

# Reset to system defaults
settings put system peak_refresh_rate 0
settings put system min_refresh_rate 0

# ============================================
# II. REVERT HWUI & RENDERING
# ============================================
log "Reverting rendering properties..."

# Reset HWUI props
setprop debug.hwui.profile.maxframes ""
setprop debug.hwui.fpslimit ""
setprop debug.hwui.fps_limit ""
setprop debug.hwui.render_dirty_regions ""
setprop debug.hwui.use_buffer_age ""
setprop debug.hwui.disable_vsync ""

# Reset SurfaceFlinger
setprop debug.sf.frame_rate_multiple_threshold ""
setprop debug.sf.scroll_boost_refreshrate ""
setprop debug.sf.touch_boost_refreshrate ""
setprop debug.sf.disable_backpressure ""
setprop debug.sf.latch_unsignaled ""
setprop debug.sf.enable_hwc_vds ""
setprop debug.sf.early_phase_offset_ns ""
setprop debug.sf.early_app_phase_offset_ns ""
setprop debug.sf.early_gl_phase_offset_ns ""
setprop debug.sf.early_gl_app_phase_offset_ns ""

# Reset VSync settings
setprop debug.egl.swapinterval ""
setprop debug.gr.swapinterval ""
setprop debug.sf.swapinterval ""
setprop debug.gl.swapinterval ""
setprop debug.cpurend.vsync ""
setprop debug.gpurend.vsync ""
setprop debug.sf.latch_to_present ""
setprop debug.hwc.force_cpu_vsync ""
setprop debug.hwc.force_gpu_vsync ""
setprop debug.hwc.enable_vsync ""
setprop debug.hwc.disable_vsync ""

# ============================================
# III. REVERT GPU SETTINGS
# ============================================
log "Reverting GPU settings..."

# Reset GPU governor to default
if [ -f /sys/class/kgsl/kgsl-3d0/devfreq/governor ]; then
    echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor 2>/dev/null
fi

# Reset GPU power level
if [ -f /sys/class/kgsl/kgsl-3d0/default_pwrlevel ]; then
    DEFAULT_LEVEL=$(cat /sys/class/kgsl/kgsl-3d0/default_pwrlevel)
    echo $DEFAULT_LEVEL > /sys/class/kgsl/kgsl-3d0/max_pwrlevel 2>/dev/null
fi

setprop debug.egl.profiler ""
setprop debug.egl.hw ""
setprop debug.composition.type ""
setprop debug.performance.gpu_boost ""

# ============================================
# IV. REVERT CPU GOVERNOR
# ============================================
log "Reverting CPU governor..."

# Reset to default governors (schedutil or interactive)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > "$cpu" 2>/dev/null || echo "interactive" > "$cpu" 2>/dev/null
done

# Reset CPU boost if modified
if [ -f /sys/devices/system/cpu/cpu_boost/input_boost_enabled ]; then
    echo 1 > /sys/devices/system/cpu/cpu_boost/input_boost_enabled
fi

# ============================================
# V. REVERT I/O SCHEDULER
# ============================================
log "Reverting I/O scheduler..."

for queue in /sys/block/*/queue; do
    if [ -f "$queue/scheduler" ]; then
        # Try to set back to cfq or default
        echo "cfq" > "$queue/scheduler" 2>/dev/null || echo "noop" > "$queue/scheduler" 2>/dev/null
    fi
    [ -f "$queue/read_ahead_kb" ] && echo 128 > "$queue/read_ahead_kb" 2>/dev/null
    [ -f "$queue/nr_requests" ] && echo 128 > "$queue/nr_requests" 2>/dev/null
done

# ============================================
# VI. REVERT MEMORY SETTINGS
# ============================================
log "Reverting memory settings..."

# Reset VM settings to Android defaults
sysctl -w vm.swappiness=60
sysctl -w vm.vfs_cache_pressure=100
sysctl -w vm.dirty_ratio=20
sysctl -w vm.dirty_background_ratio=10
sysctl -w vm.dirty_expire_centisecs=200
sysctl -w vm.dirty_writeback_centisecs=500
sysctl -w vm.compact_unevictable_allowed=1
sysctl -w vm.compaction_proactiveness=20
sysctl -w vm.oom_kill_allocating_task=0
sysctl -w vm.panic_on_oom=0

# ============================================
# VII. RE-ENABLE THERMAL MANAGEMENT
# ============================================
log "Re-enabling thermal management..."

cmd thermalservice reset

# Re-enable thermal zones
for zone in /sys/class/thermal/thermal_zone*/mode; do
    echo "enabled" > "$zone" 2>/dev/null
done

# ============================================
# VIII. REVERT NETWORK SETTINGS
# ============================================
log "Reverting network settings..."

sysctl -w net.ipv4.tcp_congestion_control=cubic
sysctl -w net.core.default_qdisc=fq_codel
sysctl -w net.ipv4.tcp_fastopen=1
sysctl -w net.ipv4.tcp_low_latency=0
sysctl -w net.ipv4.tcp_timestamps=1
sysctl -w net.ipv4.tcp_sack=1

# ============================================
# IX. REVERT GAME MODE
# ============================================
log "Reverting game mode settings..."

cmd display set-match-content-frame-rate-pref 1
cmd power set-fixed-performance-mode-enabled false

# Remove game mode from all apps
for pkg in $(pm list packages -3 | cut -f2 -d:); do
    cmd game set --mode standard "$pkg" 2>/dev/null &
    device_config delete game_overlay "$pkg" 2>/dev/null &
done
wait

# ============================================
# X. RESET ZRAM (if configured)
# ============================================
log "Resetting ZRAM..."

if [ -b /dev/block/zram0 ]; then
    swapoff /dev/block/zram0 2>/dev/null
    echo 1 > /sys/block/zram0/reset 2>/dev/null
fi

# ============================================
# XI. RELOAD SDR
# ============================================
log "Reloading SurfaceFlinger..."

sleep 1
(svc=$(pidof surfaceflinger 2>/dev/null); [ -n "$svc" ] && kill -HUP $svc) || \
(service call SurfaceFlinger 33 >/dev/null 2>&1) || true

# ============================================
# XII. CLEANUP
# ============================================
log "Cleaning up configuration files..."

rm -f "$CONFIG_FILE"
# Keep log file for reference

) 2>&1 | tee -a "$LOG_FILE"

# ============================================
# COMPLETION
# ============================================
echo ""
echo "╔═══════════════════════════════════════╗"
echo "║     ✅ REVERT COMPLETE!              ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "📊 System restored to default state"
echo "💾 Log saved to: $LOG_FILE"
echo "⚠️  Reboot recommended for full reset"
echo ""

cmd notification post -S bigtext -t '🔄 60FPS Optimizer' 'Tag' 'REVERTED - Default settings restored' > /dev/null 2>&1

log "Revert completed successfully"
