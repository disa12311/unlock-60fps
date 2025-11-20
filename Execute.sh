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
# Revert/Remove 60 FPS and optimize settings
settings put system peak_refresh_rate null
settings put system user_refresh_rate null
settings put system min_refresh_rate null
settings put system thermal_limit_refresh_rate null
settings put system miui_refresh_rate null
settings put secure user_refresh_rate null
settings put secure max_refresh_rate null
settings put secure match_content_frame_rate null
settings put secure refresh_rate_mode null
settings put system ext_force_refresh_rate_list null
settings put system db_screen_rate null
settings put system framepredict_enable null
settings put system is_smart_fps null
settings put system screen_optimize_mode null

# Revert performance-related settings
cmd display set-match-content-frame-rate-pref 1
cmd power set-fixed-performance-mode-enabled false
cmd thermalservice reset

# Reload SDR để trả về trạng thái ban đầu
(svc=$(pidof surfaceflinger 2>/dev/null); [ -n "$svc" ] && kill -HUP $svc) || (service call SurfaceFlinger 33 >/dev/null 2>&1) || true
)

echo ""
echo "▶ Module Successfully Deleted (60FPS + reload SDR) "
sleep 1
echo ""
cmd notification post -S bigtext -t ' 🚀 60FPS - JordanTweaks ' 'Tag' 'DELETED!!' > /dev/null 2>&1
echo " SUBSCRIBE | LIKE | SHARE | COMMENT "
echo ""
echo " Done....... "
echo " REBOOT YOUR PHONE "
