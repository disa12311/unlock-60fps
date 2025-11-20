#!/bin/sh
echo "[ 𝗜𝗻𝗳𝗼𝗿𝗺𝗮𝘁𝗶𝗼𝗻🔥 ] "
echo "▶ Developer : @JordanTweaks "
echo "▶ Credits : @jordantweaks "
echo "▶ Version : 1.0 "
echo "▶ Status : No Root "
sleep 2
echo "
▄█─ █▀█ █▀▀█ ░█▀▀▀ ░█▀▀█ ░█▀▀▀█
─█─ ─▄▀ █▄▀█ ░█▀▀▀ ░█▄▄█ ─▀▀▀▄▄
▄█▄ █▄▄ █▄▄█ ░█─── ░█─── ░█▄▄▄█"
echo ""
sleep 2
echo "▎𝗗𝗲𝘃𝗶𝗰𝗲 𝗜𝗻𝗳𝗼📱 "
sleep 0.5
echo "▎DEVICE=$(getprop ro.product.model) "
sleep 1
echo "▎BRAND=$(getprop ro.product.system.brand) "
sleep 1
echo "▎MODEL=$(getprop ro.build.product) "
sleep 1
echo "▎KERNEL=$(uname -r) "
sleep 1
echo "▎GPU INFO=$(getprop ro.hardware.egl) "
sleep 1
echo "▎CPU INFO=$(getprop ro.hardware) "
sleep 1
echo "▎ ANDROID VERSION : $(getprop ro.build.version.release) "
sleep 2
echo ""
echo " ▶ PROCES.........  "
echo ""
sleep 2
echo " ▶ WAIT.....  "
echo ""
sleep 5
echo "[■□□□□□□□□□]  "
sleep 1
echo "[■■□□□□□□□□]  "
sleep 1
echo "[■■■□□□□□□□]  "
sleep 1
echo "[■■■■□□□□□□]  "
sleep 1
echo "[■■■■■□□□□□]  "
sleep 1
echo "[■■■■■■□□□□]  "
sleep 1
echo "[■■■■■■■□□□]  "
sleep 1
echo "[■■■■■■■■□□]  "
sleep 1
echo "[■■■■■■■■■□]  "
sleep 1
echo "[■■■■■■■■■■]  "
sleep 0.5
echo ""
sleep 1

(

# 120 FPS
settings put system peak_refresh_rate 120
settings put system user_refresh_rate 120
settings put system min_refresh_rate 120
settings put system thermal_limit_refresh_rate 120
settings put system miui_refresh_rate 120
settings put secure user_refresh_rate 120
settings put secure max_refresh_rate 120
settings put secure miui_refresh_rate 120
settings put secure match_content_frame_rate 1
settings put secure refresh_rate_mode 2
settings put system ext_force_refresh_rate_list 120
settings put system db_screen_rate 2
settings put system framepredict_enable 1
settings put system is_smart_fps 0
settings put system screen_optimize_mode 1
setprop debug.hwui.profile.maxframes 120
setprop debug.hwui.fpslimit 120
setprop debug.hwui.fps_limit 120
setprop debug.display.allow_non_native_refresh_rate_override true
setprop debug.display.render_frame_rate_is_physical_refresh_rate true
setprop debug.sf.frame_rate_multiple_threshold 120
setprop debug.sf.scroll_boost_refreshrate 120
setprop debug.sf.touch_boost_refreshrate 120
setprop debug.sf.showupdates 0
setprop debug.sf.showcpu 0
setprop debug.sf.showbackground 0
setprop debug.sf.showfps 0
setprop debug.refresh_rate.min_fps 120
setprop debug.refresh_rate.max_fps 120
setprop debug.refresh_rate.peak_fps 120
setprop debug.graphics.game_default_frame_rate.disabled true
setprop debug.sf.prim_perf_120hz_base_brightness_zone 120:120:120,120:120:120
setprop debug.sf.prim_perf_120hz_base_brightness_zone 120:120:120,120:120:120,120:120:120
setprop debug.sf.prim_std_brightness_zone 120:120:120,120:120:120
setprop debug.sf.cli_perf_brightness_zone 120:120:120
setprop debug.sf.cli_std_brightness_zone 120:120:120

#Boost Performance
cmd display set-match-content-frame-rate-pref 0
cmd power set-fixed-performance-mode-enabled true
cmd thermalservice override-status 0

# Enable Performance and FPS for all 3rd apps
for pkg in $(pm list packages -3 | cut -f2 -d:); do
  device_config put game_overlay $pkg mode=2,fps=120:mode=3,fps=120
done
for pkg in $(pm list packages -3 | cut -f2 -d:); do
  cmd game set --mode performance --fps 120 $pkg
done

# Disable V-Sync
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
setprop debug.hwc.enable_vsync false
setprop debug.hwc.disable_vsync true
setprop debug.logvsync 0
setprop debug.hwc.vsync_interval 0
setprop debug.hwc.vsync_source 0
setprop debug.sf.no_hw_vsync 1
setprop debug.hwc.fakevsync 0

#Setprops

settprops=(
"debug.hwui.renderer skiagl"
"debug.sf.disable_backpressure 1"
"debug.sf.latch_unsignaled 1"
"debug.sf.enable_hwc_vds 0"
"debug.sf.early_phase_offset_ns 500000"
"debug.sf.early_app_phase_offset_ns 500000"
"debug.sf.early_gl_phase_offset_ns 3000000"
"debug.sf.early_gl_app_phase_offset_ns 15000000"
"debug.sf.high_fps_early_phase_offset_ns 6100000"
"debug.sf.high_fps_early_gl_phase_offset_ns 650000"
"debug.sf.high_fps_late_app_phase_offset_ns 100000"
"debug.sf.phase_offset_threshold_for_next_vsync_ns 6100000"
"debug.sf.showupdates 0"
"debug.sf.showcpu 0"
"debug.sf.showbackground 0"
"debug.sf.showfps 0"
"debug.sf.hw 1"
"debug.performance.accoustic.force true"
"debug.performance.cap 120"
"debug.performance.disturb true"
"debug.performance.tuning 1"
"debug.performance_schema 1"
"debug.performance_schema_max_memory_classes 1000"
"debug.performance_schema_max_socket_classes 10"
"debug.performance.force_fps 2"
"debug.performance.gpu_boost 1"
"debug.profiler.target_performance_percent 100"
)
for settprop in "${settprops[@]}"; do
setprop $settprop
done

)

echo ""
echo "▶ Module Succesfully Flashed "
sleep 1
echo ""
cmd notification post -S bigtext -t ' 🚀 120FPS - JordanTweaks ' 'Tag' 'ACTIVATED!!' > /dev/null 2>&1
echo " SUBSCRIBE | LIKE | SHARE | COMMENT "
echo ""
echo " Done....... "
echo " PLEASE DON'T REBOOT YOUR PHONE "
