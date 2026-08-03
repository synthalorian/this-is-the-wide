#!/bin/bash
# revert.sh — back to factory reality.
set -euo pipefail

EDID_NAME="skg-2560x1080.bin"
LIMINE="/boot/limine.conf"

echo "[1/3] removing EDID firmware"
sudo rm -f "/usr/lib/firmware/edid/$EDID_NAME"

echo "[2/3] cleaning kernel cmdline"
sudo sed -i "s| drm.edid_firmware=HDMI-A-1:edid/${EDID_NAME}||" "$LIMINE"

echo "[3/3] done — REBOOT to apply. Monitor returns to stock EDID on next boot."
echo "(Albion prefs: set Screenmanager Resolution Width/Height back to 2560/1440"
echo " in ~/.config/unity3d/Sandbox Interactive GmbH/Albion Online Client/prefs)"
