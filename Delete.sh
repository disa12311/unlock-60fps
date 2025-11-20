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

#Boost Performance
cmd display set-match-content-frame-rate-pref 1
cmd power set-fixed-performance-mode-enabled false
cmd thermalservice reset

echo ""
echo "▶ Module Succesfully Deleted "
sleep 1
echo ""
cmd notification post -S bigtext -t ' 🚀 120FPS - JordanTweaks ' 'Tag' 'DELETED!!' > /dev/null 2>&1
echo " SUBSCRIBE | LIKE | SHARE | COMMENT "
echo ""
echo " Done....... "
echo " REBOOT YOUR PHONE "
