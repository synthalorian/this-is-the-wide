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
if sudo grep -q "$PARAM" "$LIMINE"; then
  echo "  param already present, skipping"
else
  sudo cp "$LIMINE" "$LIMINE.bak-this-is-the-wide"
  sudo sed -i "s|cmdline: quiet nowatchdog splash rw|& $PARAM|" "$LIMINE"
  echo "  injected into $(sudo grep -c "$PARAM" "$LIMINE") entr(ies)"
fi

echo "[3/3] done — REBOOT to apply"
echo "verify after boot: edid-decode /sys/class/drm/card1-${OUTPUT}/edid | grep 'DTD 1'"
