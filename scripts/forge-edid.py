#!/usr/bin/env python3
"""forge-edid.py — build a forged EDID with a custom mode as preferred DTD1.

Usage:
  ./forge-edid.py --stock /sys/class/drm/card1-HDMI-A-1/edid \
                  --mode "230.00 2560 2720 2992 3424 1080 1083 1093 1120 -hsync +vsync" \
                  --mode2 "373.00 2560 2608 2640 2720 1080 1083 1093 1144 +hsync -vsync" \
                  --out skg-2560x1080.bin

Get modelines from: cvt 2560 1080 60  /  cvt -r 2560 1080 120
Image size bytes are copied from the stock DTD1 so the panel keeps its
physical dimensions. Extension blocks are never touched.
"""
import argparse, sys

def build_dtd(modeline: str, img_lo_hi: bytes) -> bytes:
    p = modeline.split()
    pclk = int(round(float(p[0]) * 100))            # MHz -> 10kHz units
    ha, hs, he, ht = map(int, p[1:5])
    va, vs, ve, vt = map(int, p[5:9])
    flags = p[9:]
    hblank, vblank = ht - ha, vt - va
    hso, hsw = hs - ha, he - hs
    vso, vsw = vs - va, ve - vs
    d = bytearray(18)
    d[0], d[1] = pclk & 0xFF, (pclk >> 8) & 0xFF
    d[2] = ha & 0xFF; d[3] = hblank & 0xFF
    d[4] = ((ha >> 8) << 4) | ((hblank >> 8) & 0xF)
    d[5] = va & 0xFF; d[6] = vblank & 0xFF
    d[7] = ((va >> 8) << 4) | ((vblank >> 8) & 0xF)
    d[8] = hso & 0xFF; d[9] = hsw & 0xFF
    d[10] = ((vso & 0xF) << 4) | (vsw & 0xF)
    d[11] = (((hso >> 8) & 3) << 6) | (((hsw >> 8) & 3) << 4) | (((vso >> 8) & 3) << 2) | ((vsw >> 8) & 3)
    d[12:15] = img_lo_hi                           # image size (mm), copied from stock
    d[15] = d[16] = 0                              # no border
    # digital separate sync; bit2=+vsync, bit1=+hsync
    f = 0x18
    if '+vsync' in flags: f |= 0x04
    if '-vsync' in flags: f &= ~0x04
    if '+hsync' in flags: f |= 0x02
    if '-hsync' in flags: f &= ~0x02
    d[17] = f
    return bytes(d)

ap = argparse.ArgumentParser()
ap.add_argument('--stock', required=True)
ap.add_argument('--mode', required=True, help='primary (preferred) modeline')
ap.add_argument('--mode2', help='optional second modeline (descriptor slot 2)')
ap.add_argument('--out', required=True)
a = ap.parse_args()

edid = bytearray(open(a.stock, 'rb').read())
if len(edid) < 128:
    sys.exit('EDID too small')
img = bytes(edid[54 + 12: 54 + 15])                # image size from stock DTD1
edid[54:72] = build_dtd(a.mode, img)
if a.mode2:
    edid[72:90] = build_dtd(a.mode2, img)
edid[127] = (-sum(edid[:127])) % 256
open(a.out, 'wb').write(bytes(edid))
assert sum(edid[:128]) % 256 == 0
print(f'forged {a.out} — validate with: edid-decode {a.out}')
