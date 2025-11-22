#!/system/bin/sh

# ============================================
# 60FPS Dynamic Optimizer v3.0
# ============================================

MODPATH="/sdcard/60FPS"
LOG_FILE="$MODPATH/execution.log"
CONFIG_FILE="$MODPATH/device_config.conf"

# Logging function
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ============================================
# HEADER & DEVICE DETECTION
# ============================================
clear
echo "╔═══════════════════════════════════════╗"
echo "║   🚀 60FPS DYNAMIC OPTIMIZER v3.0    ║"
echo "╚═══════════════════════════════════════╝"
log "Starting Dynamic 60FPS Optimizer"

# Device Information
DEVICE_MODEL=$(getprop ro.product.model)
DEVICE_BRAND=$(getprop ro.product.system.brand)
SOC_NAME=$(getprop ro.hardware)
GPU_DRIVER=$(getprop ro.hardware.egl)
ANDROID_VER=$(getprop ro.build.version.release)
KERNEL_VER=$(uname -r)
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')

echo ""
echo "📱 Device: $DEVICE_BRAND $DEVICE_MODEL"
echo "🔧 SoC: $SOC_NAME | GPU: $GPU_DRIVER"
echo "📊 RAM: ${TOTAL_RAM}MB | Android: $ANDROID_VER"
echo "🔩 Kernel: $KERNEL_VER"
echo ""

# ============================================
# DYNAMIC REFRESH RATE DETECTION
# ============================================
log "Detecting display capabilities..."

# Detect max supported refresh rate
MAX_REFRESH=$(dumpsys display | grep -oP 'mSupportedModes=\[\K[^]]+' | grep -oP '\d+\.?\d*Hz' | sed 's/Hz//' | sort -n | tail -1)
if [ -z "$MAX_REFRESH" ]; then
    MAX_REFRESH=60
fi
MAX_REFRESH=${MAX_REFRESH%.*}  # Remove decimal

# Detect current refresh rate
CURRENT_REFRESH=$(dumpsys SurfaceFlinger | grep 'refresh-rate' | head -1 | grep -oP '\d+' | head -1)
[ -z "$CURRENT_REFRESH" ] && CURRENT_REFRESH=60

log "Max refresh rate: ${MAX_REFRESH}Hz | Current: ${CURRENT_REFRESH}Hz"

# Determine target FPS (adaptive)
if [ "$MAX_REFRESH" -ge 120 ]; then
    TARGET_FPS=120
    MODE="ULTRA"
elif [ "$MAX_REFRESH" -ge 90 ]; then
    TARGET_FPS=90
    MODE="HIGH"
else
    TARGET_FPS=60
    MODE="STANDARD"
fi

echo "🎯 Target Mode: $MODE ($TARGET_FPS FPS)"
echo ""

# ============================================
# PERFORMANCE CLASS DETECTION
# ============================================
log "Analyzing device performance class..."

# Detect CPU cores and frequency
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo "2000000")
MAX_FREQ=$((MAX_FREQ / 1000))  # Convert to MHz

# Classify device tier
if [ "$TOTAL_RAM" -ge 8000 ] && [ "$MAX_FREQ" -ge 2400 ]; then
    DEVICE_TIER="FLAGSHIP"
    AGGRESSION=3
elif [ "$TOTAL_RAM" -ge 6000 ] && [ "$MAX_FREQ" -ge 2000 ]; then
    DEVICE_TIER="HIGH_END"
    AGGRESSION=2
elif [ "$TOTAL_RAM" -ge 4000 ]; then
    DEVICE_TIER="MID_RANGE"
    AGGRESSION=1
else
    DEVICE_TIER="BUDGET"
    AGGRESSION=0
fi

echo "⚡ Device Tier: $DEVICE_TIER"
echo "🔥 Optimization Level: $AGGRESSION"
echo ""

# Save config for future use
cat > "$CONFIG_FILE" << EOF
MAX_REFRESH=$MAX_REFRESH
TARGET_FPS=$TARGET_FPS
DEVICE_TIER=$DEVICE_TIER
AGGRESSION=$AGGRESSION
TOTAL_RAM=$TOTAL_RAM
CPU_CORES=$CPU_CORES
MAX_FREQ=$MAX_FREQ
EOF

# ============================================
# PROGRESS BAR
# ============================================
progress_bar() {
    echo -n "["
    for i in $(seq 1 10); do
        echo -n "■"
        sleep 0.2
    done
    echo "] 100%"
}

echo "⏳ Initializing optimizations..."
progress_bar
echo ""

# ============================================
# DEEP KERNEL TWEAKS
# ============================================
log "Applying deep kernel optimizations..."

(
# ============================================
# I. DISPLAY & REFRESH RATE SETTINGS
# ============================================

# Dynamic refresh rate settings
settings put system peak_refresh_rate $TARGET_FPS
settings put system user_refresh_rate $TARGET_FPS
settings put system min_refresh_rate $TARGET_FPS
settings put system thermal_limit_refresh_rate $TARGET_FPS
settings put system miui_refresh_rate $TARGET_FPS
settings put secure user_refresh_rate $TARGET_FPS
settings put secure max_refresh_rate $TARGET_FPS
settings put secure match_content_frame_rate 1
settings put secure refresh_rate_mode 1
settings put system ext_force_refresh_rate_list $TARGET_FPS

# HWUI rendering props
setprop debug.hwui.profile.maxframes $TARGET_FPS
setprop debug.hwui.fpslimit $TARGET_FPS
setprop debug.hwui.render_dirty_regions false
setprop debug.hwui.use_buffer_age false
setprop debug.hwui.filter_test_overhead false

# SurfaceFlinger optimizations
setprop debug.sf.frame_rate_multiple_threshold $TARGET_FPS
setprop debug.sf.scroll_boost_refreshrate $TARGET_FPS
setprop debug.sf.touch_boost_refreshrate $TARGET_FPS
setprop debug.sf.disable_backpressure 1
setprop debug.sf.latch_unsignaled 1
setprop debug.sf.enable_hwc_vds 0

# Adaptive phase offsets based on target FPS
VSYNC_PERIOD=$((1000000000 / TARGET_FPS))
EARLY_OFFSET=$((VSYNC_PERIOD / 2))
setprop debug.sf.early_phase_offset_ns $EARLY_OFFSET
setprop debug.sf.early_app_phase_offset_ns $EARLY_OFFSET

# ============================================
# II. GPU OPTIMIZATIONS
# ============================================

# Disable VSync for reduced latency
setprop debug.egl.swapinterval 0
setprop debug.gr.swapinterval 0
setprop debug.sf.swapinterval 0
setprop debug.cpurend.vsync false
setprop debug.gpurend.vsync false
setprop debug.hwc.disable_vsync true

# GPU frequency scaling (aggressive for high-tier)
if [ -f /sys/class/kgsl/kgsl-3d0/devfreq/governor ]; then
    if [ "$AGGRESSION" -ge 2 ]; then
        echo "performance" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
    else
        echo "msm-adreno-tz" > /sys/class/kgsl/kgsl-3d0/devfreq/governor
    fi
fi

# GPU power level (if supported)
if [ -f /sys/class/kgsl/kgsl-3d0/max_pwrlevel ]; then
    echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
fi

# Adreno GPU tweaks
setprop debug.egl.profiler 1
setprop debug.egl.hw 1
setprop debug.composition.type gpu
setprop debug.performance.gpu_boost 1

# ============================================
# III. CPU GOVERNOR & SCHEDULER
# ============================================

# Set CPU governors based on tier
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    if [ "$AGGRESSION" -ge 2 ]; then
        echo "performance" > "$cpu" 2>/dev/null
    else
        echo "schedutil" > "$cpu" 2>/dev/null || echo "interactive" > "$cpu" 2>/dev/null
    fi
done

# CPU frequency boost
if [ -f /sys/devices/system/cpu/cpu_boost/input_boost_freq ]; then
    echo "0:$MAX_FREQ 1:$MAX_FREQ 2:$MAX_FREQ 3:$MAX_FREQ" > /sys/devices/system/cpu/cpu_boost/input_boost_freq
    echo 200 > /sys/devices/system/cpu/cpu_boost/input_boost_ms
fi

# I/O Scheduler optimization
for queue in /sys/block/*/queue; do
    [ -f "$queue/scheduler" ] && echo "deadline" > "$queue/scheduler" 2>/dev/null
    [ -f "$queue/read_ahead_kb" ] && echo 512 > "$queue/read_ahead_kb" 2>/dev/null
    [ -f "$queue/nr_requests" ] && echo 512 > "$queue/nr_requests" 2>/dev/null
done

# ============================================
# IV. MEMORY & VM TUNING
# ============================================

# Adaptive memory management
if [ "$TOTAL_RAM" -ge 8000 ]; then
    # High RAM devices: aggressive caching
    sysctl -w vm.swappiness=10
    sysctl -w vm.vfs_cache_pressure=50
    sysctl -w vm.dirty_ratio=30
    sysctl -w vm.dirty_background_ratio=10
elif [ "$TOTAL_RAM" -ge 4000 ]; then
    # Mid-range: balanced
    sysctl -w vm.swappiness=40
    sysctl -w vm.vfs_cache_pressure=80
    sysctl -w vm.dirty_ratio=20
    sysctl -w vm.dirty_background_ratio=5
else
    # Low RAM: conservative
    sysctl -w vm.swappiness=60
    sysctl -w vm.vfs_cache_pressure=100
fi

# Memory compaction
sysctl -w vm.compact_unevictable_allowed=1
sysctl -w vm.compaction_proactiveness=0

# OOM killer tuning
sysctl -w vm.oom_kill_allocating_task=1
sysctl -w vm.panic_on_oom=0

# ============================================
# V. THERMAL MANAGEMENT
# ============================================

# Disable thermal throttling (for high-tier only)
if [ "$AGGRESSION" -ge 2 ]; then
    cmd thermalservice override-status 0
    for zone in /sys/class/thermal/thermal_zone*/mode; do
        echo "disabled" > "$zone" 2>/dev/null
    done
fi

# ============================================
# VI. NETWORK OPTIMIZATION
# ============================================

# TCP tuning for gaming
sysctl -w net.ipv4.tcp_congestion_control=bbr
sysctl -w net.core.default_qdisc=fq_codel
sysctl -w net.ipv4.tcp_fastopen=3
sysctl -w net.ipv4.tcp_low_latency=1
sysctl -w net.ipv4.tcp_timestamps=0
sysctl -w net.ipv4.tcp_sack=1

# ============================================
# VII. GAME MODE INJECTION
# ============================================

cmd display set-match-content-frame-rate-pref 0
cmd power set-fixed-performance-mode-enabled true

# Apply game mode to all third-party apps
for pkg in $(pm list packages -3 | cut -f2 -d:); do
    cmd game set --mode performance --fps $TARGET_FPS "$pkg" 2>/dev/null &
    device_config put game_overlay "$pkg" "mode=2,fps=$TARGET_FPS:mode=3,fps=$TARGET_FPS" 2>/dev/null &
done
wait

# ============================================
# VIII. ZRAM OPTIMIZATION (if enabled)
# ============================================

if [ -b /dev/block/zram0 ]; then
    # Adaptive ZRAM based on RAM
    ZRAM_SIZE=$((TOTAL_RAM / 4))  # 25% of RAM
    swapoff /dev/block/zram0 2>/dev/null
    echo 1 > /sys/block/zram0/reset
    echo lz4 > /sys/block/zram0/comp_algorithm
    echo ${ZRAM_SIZE}M > /sys/block/zram0/disksize
    mkswap /dev/block/zram0
    swapon /dev/block/zram0 -p 32758
fi

# ============================================
# IX. RELOAD SDR (SurfaceFlinger)
# ============================================

sleep 1
(svc=$(pidof surfaceflinger 2>/dev/null); [ -n "$svc" ] && kill -HUP $svc) || \
(service call SurfaceFlinger 33 >/dev/null 2>&1) || true

) 2>&1 | tee -a "$LOG_FILE"

# ============================================
# COMPLETION
# ============================================
echo ""
echo "╔═══════════════════════════════════════╗"
echo "║     ✅ OPTIMIZATION COMPLETE!        ║"
echo "╚═══════════════════════════════════════╝"
echo ""
echo "📊 Applied Settings:"
echo "   • Target FPS: $TARGET_FPS"
echo "   • Device Tier: $DEVICE_TIER"
echo "   • Aggression: Level $AGGRESSION"
echo "   • CPU Cores: $CPU_CORES @ ${MAX_FREQ}MHz"
echo ""
echo "💾 Log saved to: $LOG_FILE"
echo "⚠️  DO NOT REBOOT - Changes active in memory"
echo ""

cmd notification post -S bigtext -t '🚀 60FPS Optimizer' 'Tag' "ACTIVATED ($MODE mode - $TARGET_FPS FPS)" > /dev/null 2>&1

log "Optimization completed successfully"
