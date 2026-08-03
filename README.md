# this-is-the-wide ⚔️🖥️

*This is the wave. This is the wide.*

Forging a **21:9 2560x1080 "native" mode** for a 2560x1440 monitor (SKG GMQ3225RVC, GTX 1080 Ti,
CachyOS + KDE Plasma Wayland, limine bootloader) — so Albion Online officially *approves* of our
lifestyle choices.

## The problem

Albion Online's resolution dropdown is **hardcoded** — it filters exotic aspect ratios and its
settings manager re-vets your resolution mid-load, reverting anything weird to 1280x800.
But research (Steam Community archaeology) revealed the whitelist: **21:9 is officially supported**
(3440x1440 works natively). 32:10 gets the boot. 64:27 gets a handshake.

So instead of fighting the game, we lie to the *monitor's identity*.

## The trick

`drm.edid_firmware` — a kernel parameter that swaps a display's EDID at probe time.
We hand the panel a forged EDID where the **preferred native mode is 2560x1080** (with a bonus
120Hz variant), all stock modes preserved. Result:

- NVIDIA accepts it (proprietary driver rejects *custom* modes, but native EDID modes are gospel)
- KWin auto-picks it as preferred
- Albion's settings manager sees legit 21:9 and **holds it past the loading screen** ✅
- Bonus FOV for spotting Caerleon gankers before they spot you

## What's in here

| Path | What |
|---|---|
| `edid/skg-2560x1080.bin` | The forged EDID (DTD1 = 2560x1080@60 preferred, DTD2 = @120 CVT-RB) |
| `scripts/forge-edid.py` | Rebuild a forged EDID from the panel's stock EDID + any `cvt` modeline |
| `scripts/install.sh` | Install EDID to `/usr/lib/firmware/edid/` + inject kernel param into limine.conf |
| `scripts/revert.sh` | Remove everything, back to factory reality |

## Usage

```bash
sudo scripts/install.sh
# reboot
# optional: KDE Display settings → try 2560x1080@120 (auto-revert safety dialog)
```

Albion side: launch normally (`gamemoderun %command%`). The Qt launcher reads Unity
PlayerPrefs and injects `-screen-width 2560 -screen-height 1080` itself. Prefs template:

```
Screenmanager Resolution Width  = 2560
Screenmanager Resolution Height = 1080
```

## Revert

```bash
sudo scripts/revert.sh
# reboot
```

Backups of `limine.conf` are written next to the original before every edit.

## Warnings (read these, future me)

- If the panel won't sync the forged mode you get a black screen **on that output**.
  Keep a second monitor un-forged (HDMI-A-2 is never touched here) — that's your lifeline.
- `video=HDMI-A-1:2560x1080@60` cmdline does **NOT** work: nvidia-drm ignores `video=`
  and KWin re-applies its stored output config at login. EDID override is the way.
- kscreen-doctor / KWin custom modes: **driver rejects all of them** on this stack (580.173.02).
- Do NOT patch the game binary — SBI anti-cheat. This setup is display-level only;
  the game sees an ordinary 21:9 monitor and stays happy.
- Letterbox vs stretch (black bars vs smeared pixels) is the **monitor OSD's** aspect setting,
  not Linux's.

## The saga (abridged)

1. gamescope letterbox → NVIDIA rejects all custom modes, game collapses to "the square"
2. Config-file surgery → launcher reads prefs, injects args, game rewrites prefs. Loop of pain.
3. `video=` kernel force → ignored by nvidia-drm
4. EDID forge at 2560x800 (32:10) → WORKS at the display level… game vetoes it mid-load 💀
5. Research → 21:9 is whitelisted by Albion. Rebuild EDID at 2560x1080.
6. `Desktop is 2560 x 1080 @ 120 Hz` — `requesting fullscreen 2560 x 1080` — **held.** 🏆

---

Made by synth with synthclaw 🎹🦞
