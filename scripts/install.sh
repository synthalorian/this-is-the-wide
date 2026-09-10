#!/bin/bash
# install.sh — install the forged EDID and wire it into limine's kernel cmdline.
set -euo pipefail

EDID_NAME="skg-2560x1080.bin"
OUTPUT="DP-2" # SKG primary is wired to the RX 9070 XT's DP-2 (was HDMI-A-1 on the GTX 1080 Ti)
PARAM="drm.edid_firmware=${OUTPUT}:edid/${EDID_NAME}"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIMINE="/boot/limine.conf"

echo "[1/3] installing EDID firmware"
sudo mkdir -p /usr/lib/firmware/edid
sudo cp "$REPO_DIR/edid/$EDID_NAME" "/usr/lib/firmware/edid/$EDID_NAME"

echo "[2/3] patching $LIMINE (backup first)"
# Only the ACTIVE entries matter: their cmdline contains "rootflags=subvol=/@ root="
# (snapshot entries use "/@/.snapshots/..."). Kernel updates regenerate ONE active
# entry via limine-entry-tool and drop the param THERE — while an older active
# entry may still carry it. Check EVERY active line: the old "any match = skip"
# grep saw the surviving param on the stale entry and skipped the entry you
# actually boot (bug hit 2026-08-11 after the 7.1.6 -> 7.1.8 upgrade).
LIVE_ROOT="rootflags=subvol=/@ root="
if ! sudo grep -F "$LIVE_ROOT" "$LIMINE" | grep -v "$PARAM" | grep -qF "$LIVE_ROOT"; then
  echo "  param already present in all active entries, skipping"
else
  sudo cp "$LIMINE" "$LIMINE.bak-this-is-the-wide"
  sudo sed -i "/rootflags=subvol=\\/@ root=/ { /drm.edid_firmware/! s|cmdline: quiet nowatchdog splash rw |cmdline: quiet nowatchdog splash rw $PARAM | }" "$LIMINE"
  echo "  injected; active entries now carrying the param: $(sudo grep -F "$LIVE_ROOT" "$LIMINE" | grep -c "$PARAM")"
fi

echo "[3/4] baking EDID into initramfs (amdgpu probes BEFORE rootfs mounts —"
echo "      without this, 'Direct firmware load failed with error -2' at boot)"
if ! grep -q "$EDID_NAME" /etc/mkinitcpio.conf; then
  sudo sed -i "s|^FILES=(\(.*\))|FILES=(\1 /usr/lib/firmware/edid/$EDID_NAME)|" /etc/mkinitcpio.conf
fi
sudo mkinitcpio -P
echo "  verify: lsinitcpio /boot/initramfs-linux-cachyos.img | grep $EDID_NAME"

echo "[4/4] done — REBOOT to apply"
echo "verify after boot: edid-decode /sys/class/drm/card1-${OUTPUT}/edid | grep 2560x1080"
