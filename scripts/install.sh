#!/bin/bash
# install.sh — install the forged EDID and wire it into limine's kernel cmdline.
set -euo pipefail

EDID_NAME="skg-2560x1080.bin"
OUTPUT="HDMI-A-1"
PARAM="drm.edid_firmware=${OUTPUT}:edid/${EDID_NAME}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIMINE="/boot/limine.conf"

echo "[1/3] installing EDID firmware"
sudo mkdir -p /usr/lib/firmware/edid
sudo cp "$REPO_DIR/edid/$EDID_NAME" "/usr/lib/firmware/edid/$EDID_NAME"

echo "[2/3] patching $LIMINE (backup first)"
# Only the ACTIVE entries matter: their cmdline contains "rootflags=subvol=/@ root="
# (snapshot entries use "/@/.snapshots/..."). Kernel updates regenerate the active
# entries via limine-entry-tool, which drops the param — so check those, not the
# whole file (old snapshots still contain it and would fool a plain grep).
LIVE_ROOT="rootflags=subvol=/@ root="
if sudo grep -F "$LIVE_ROOT" "$LIMINE" | grep -q "$PARAM"; then
  echo "  param already present in active entries, skipping"
else
  sudo cp "$LIMINE" "$LIMINE.bak-this-is-the-wide"
  sudo sed -i "s|cmdline: quiet nowatchdog splash rw $LIVE_ROOT|cmdline: quiet nowatchdog splash rw $PARAM $LIVE_ROOT|" "$LIMINE"
  echo "  injected into $(sudo grep -F "$LIVE_ROOT" "$LIMINE" | grep -c "$PARAM") active entr(ies)"
fi

echo "[3/3] done — REBOOT to apply"
echo "verify after boot: edid-decode /sys/class/drm/card1-${OUTPUT}/edid | grep 'DTD 1'"
