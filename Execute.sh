#!/bin/sh
echo "[ 𝗜𝗻𝗳𝗼𝗿𝗺𝗮𝘁𝗶𝗼𝗻🔥 ] "
echo "▶ Version : 2.1 (60FPS Reload SDR) "
echo "▶ Status : No Root "
sleep 2
echo "
█▀▀▀ █▀▀█ ░█▀▀▀ ░█▀▀█ ░█▀▀▀█
█▀▀▄ █▄▀█ ░█▀▀▀ ░█▄▄█ ─▀▀▀▄▄
█▄▄█ █▄▄█ ░█─── ░█─── ░█▄▄▄█"
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
echo "▎ANDROID VERSION: $(getprop ro.build.version.release) "
sleep 2
echo ""
echo " ▶ PROCES.........  "
echo ""
sleep 2
echo " ▶ WAIT.....  "
echo ""
sleep 5

# Progress bar
for i in 1 2 3 4 5 6 7 8 9 10; do
  bar=$(head -c $i < /dev/zero | tr '\0' '■')
  rem=$(expr 10 - $i)
  bar_rem=$(head -c $rem < /dev/zero | tr '\0' '□')
  echo "[$bar$bar_rem]  "
  sleep 0.3
done

echo ""
sleep 1

(
# 60 FPS configurations (set both system & secure settings)
settings put system peak_refresh_rate 60
settings put system user_refresh_rate 60
settings put system min_refresh_rate 60
settings put system thermal_limit_refresh_rate 60
settings put system miui_refresh_rate 60
settings put secure user_refresh_rate 60
settings put secure max_refresh_rate 60
settings put secure miui_refresh_rate 60
settings put secure match_content_frame_rate 1
settings put secure refresh_rate_mode 1
settings put system ext_force_refresh_rate_list 60
settings put system db_screen_rate 1
settings put system framepredict_enable 1
settings put system is_smart_fps 0
settings put system screen_optimize_mode 1

setprop debug.hwui.profile.maxframes 60
setprop debug.hwui.fpslimit 60
setprop debug.hwui.fps_limit 60
setprop debug.display.allow_non_native_refresh_rate_override true
setprop debug.display.render_frame_rate_is_physical_refresh_rate true
setprop debug.sf.frame_rate_multiple_threshold 60
setprop debug.sf.scroll_boost_refreshrate 60
setprop debug.sf.touch_boost_refreshrate 60
setprop debug.refresh_rate.min_fps 60
setprop debug.refresh_rate.max_fps 60
setprop debug.refresh_rate.peak_fps 60
setprop debug.graphics.game_default_frame_rate.disabled true

# Optimize performance (match content frame rate, fixed performance mode, allow game overlay etc.)
cmd display set-match-content-frame-rate-pref 0
cmd power set-fixed-performance-mode-enabled true
cmd thermalservice override-status 0

for pkg in $(pm list packages -3 | cut -f2 -d:); do
  device_config put game_overlay $pkg mode=2,fps=60:mode=3,fps=60
done
for pkg in $(pm list packages -3 | cut -f2 -d:); do
  cmd game set --mode performance --fps 60 $pkg
done

# Disable V-Sync (if needed; can improve performance consistency)
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

# Renderer & UI optimizations: tối ưu UI, hiệu năng
setprop debug.sf.disable_backpressure 1
setprop debug.sf.latch_unsignaled 1
setprop debug.sf.enable_hwc_vds 0
setprop debug.sf.early_phase_offset_ns 500000
setprop debug.sf.early_app_phase_offset_ns 500000
setprop debug.sf.early_gl_phase_offset_ns 3000000
setprop debug.sf.early_gl_app_phase_offset_ns 15000000
setprop debug.sf.high_fps_early_phase_offset_ns 6100000
setprop debug.sf.high_fps_early_gl_phase_offset_ns 650000
setprop debug.sf.high_fps_late_app_phase_offset_ns 100000
setprop debug.sf.phase_offset_threshold_for_next_vsync_ns 6100000
setprop debug.sf.showupdates 0
setprop debug.sf.showcpu 0
setprop debug.sf.showbackground 0
setprop debug.sf.showfps 0
setprop debug.sf.hw 1
setprop debug.performance.accoustic.force true
setprop debug.performance.cap 60
setprop debug.performance.disturb true
setprop debug.performance.tuning 1
setprop debug.performance_schema 1
setprop debug.performance_schema_max_memory_classes 1000
setprop debug.performance_schema_max_socket_classes 10
setprop debug.performance.force_fps 2
setprop debug.performance.gpu_boost 1
setprop debug.profiler.target_performance_percent 100

# Tải lại SDR (SurfaceFlinger Display Rendering)
# Khởi động lại dịch vụ SurfaceFlinger hoặc layer rendering giúp load lại SDR cho hiệu năng mới được áp dụng.
# Thiết bị nào không có service call  SurfaceFlinger sẽ bỏ qua lệnh này.
(svc=$(pidof surfaceflinger 2>/dev/null); [ -n "$svc" ] && kill -HUP $svc) || (service call SurfaceFlinger 33 >/dev/null 2>&1) || true

)

echo ""
echo "▶ Module Successfully Flashed (60FPS + reload SDR) "
sleep 1
echo ""
cmd notification post -S bigtext -t ' 🚀 60FPS - JordanTweaks ' 'Tag' 'ACTIVATED!!' > /dev/null 2>&1
echo " SUBSCRIBE | LIKE | SHARE | COMMENT "
echo ""
echo " Done....... "
echo " PLEASE DON'T REBOOT YOUR PHONE "
