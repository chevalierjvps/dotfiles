<div align="center">

# ⚡ AMBERGLOW ⚡
### Retro CRT Phosphor Rice for MangoWM & Arch Linux

[![OS](https://img.shields.io/badge/OS-Arch_Linux_%2F_CachyOS-1793d1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Compositor](https://img.shields.io/badge/Compositor-MangoWM-e8952d?style=for-the-badge&logo=wayland&logoColor=white)](https://github.com/DreamMaoMao/mangowc)
[![Bar](https://img.shields.io/badge/Bar-Waybar-241d15?style=for-the-badge&logo=rust&logoColor=e8952d)](https://github.com/Alexays/Waybar)
[![Launcher](https://img.shields.io/badge/Launcher-Rofi_Wayland-e8952d?style=for-the-badge&logo=gnome-terminal&logoColor=white)](https://github.com/lbonn/rofi)
[![Font](https://img.shields.io/badge/Font-DepartureMono_Nerd_Font-e0d4b0?style=for-the-badge&logo=terminal&logoColor=1a150f)](https://departuremono.com/)

<br>

<img src="screenshots/rofi-launcher.png" alt="Amberglow Rice Preview — Rofi Launcher & Waybar" width="960px" style="border: 2px solid #e8952d; border-radius: 4px;" />

<br>

*Warm amber phosphor glow • Crisp zero-radius geometry • Solid CRT aesthetic • Zero emojis • Pure typography*

</div>

---

## 🌟 Highlights & Philosophy

- **Retro CRT Phosphor Palette:** Deep obsidian (`#16120c`) paired with vibrant amber (`#e8952d`), dim bronze (`#8a7d63`), and phosphor highlight (`#ffaa40`).
- **Strictly Zero Emojis:** Standardized on **DepartureMono Nerd Font** glyphs and concise retro terminal labels.
- **Audio Feedback & Synchronous OSD:** Instant sound feedback tick when adjusting volume via media keys, with a compact progress-bar OSD rendered via Mako.
- **Dedicated Audio Hub & Pavucontrol:** Instant access to Pavucontrol (`SUPER+A`) or Rofi Audio Selector (`SUPER+Shift+A`) to switch output sinks and input sources on the fly.
- **First-Class Cedilla (`ç`) on Wayland:** Full support for `us-intl` dead keys across Chromium, Brave, and Electron apps powered by Fcitx5, `.XCompose`, and Ozone Wayland IME.
- **Clean Monorepo Tracking:** Repo tracks only rice files out of `$HOME` via an explicit allowlist `.gitignore`.

---

## 🗂️ What's Included

| Path | Description |
| :--- | :--- |
| [`.config/mango/`](.config/mango/) | Compositor config: binds, window rules, monitors, autostart, per-device keyboard rules |
| [`.config/waybar/mango/`](.config/waybar/mango/) | Top bar: tags, active title, media, weather, Pac-Man update chomper, tray, notifications |
| [`.config/rofi/`](.config/rofi/) | Rofi launcher theme + 9 custom script modes (apps, run, win, calc, wifi, bt, keys, layout, audio, notif) |
| [`.config/mako/config`](.config/mako/config) | Notification daemon theme with retro amber progress bar & volume OSD widget |
| [`.config/alacritty/`](.config/alacritty/) | Alacritty terminal configuration with subtle blur transparency and Amberglow palette |
| [`.config/kitty/`](.config/kitty/) | Kitty terminal configuration with subtle blur transparency and Amberglow palette |
| [`.config/MangoHud/`](.config/MangoHud/) | MangoHud configuration ensuring overlay remains silent (`no_display=1`) for desktop apps |
| [`.config/environment.d/`](.config/environment.d/) | Session environment fixes (Fcitx5 input method, MangoHud crash workaround, cursor theme) |
| [`.local/bin/`](.local/bin/) | Helper scripts and wrappers (Brave, Rofi, Kitty) for environment sanitization and flag parsing |
| [`.local/share/applications/`](.local/share/applications/) | `.desktop` entries with baked-in Wayland flags and theme extensions |
| [`.local/share/chrome-themes/`](.local/share/chrome-themes/) | Unpacked Chromium amber theme extensions for Brave & Helium |
| [`browser-themes/`](browser-themes/) | `userChrome.css` and `user.js` for Zen Browser and LibreWolf |
| [`ly-theme/config.ini`](ly-theme/config.ini) | Themed `ly` display manager configuration |

---

## ⌨️ Keybindings

Over 90 binds defined in [`.config/mango/bind.conf`](.config/mango/bind.conf). The most notable shortcuts:

| Keybinding | Action |
| :--- | :--- |
| `SUPER + D` / `SUPER + Ctrl + Return` | **Rofi Launcher** (cycle modes with `Tab` / `Shift+Tab`) |
| `SUPER + A` | **PulseAudio Volume Control (Pavucontrol GUI)** (floating) |
| `SUPER + Shift + A` | **Rofi Audio Hub** (switch sinks, sources & volume presets) |
| `SUPER + V` | **Clipboard History** (with real image thumbnail previews) |
| `SUPER + Y` | **Layout Switcher** (dynamic cycle across 14 MangoWM layouts) |
| `SUPER + Shift + Q` | **Power Menu** (Lock, Suspend, Reboot, Power Off, Log Out) |
| `SUPER + Shift + W` | **Wallpaper Picker** (interactive image thumbnail grid) |
| `SUPER + Shift + Y` | **Yazi File Manager** (dedicated dropdown scratchpad) |
| `SUPER + Shift + T` | **Kitty Terminal** (dedicated dropdown scratchpad) |
| `SUPER + E` | **Nautilus File Manager** |
| `SUPER + W` / `SUPER + B` | **Brave Browser** (pre-loaded with Amberglow theme) |
| `SUPER + O` | **Obsidian** (knowledge hub) |
| `SUPER + P` | **Pomodoro Menu** (interactive Rofi task selector from Obsidian Vault) |
| `SUPER + Shift + P` | **Pomodoro Toggle** (instant start/pause focus countdown) |
| `SUPER + K` / `SUPER + Shift + Space` | **Keyboard Layout Toggle** (instant switch between US-Intl and BR-ABNT2 with Mako OSD) |
| `SUPER + Shift + K` | **Keyboard Layout Menu** (interactive Rofi layout picker) |
| `Alt + Shift` | **Hardware Keyboard Layout Switch** (via XKB toggle) |
| `SUPER + J` | **Ryotunes** (floating centered music player) |
| `SUPER + Space` | **Toggle Floating Window** |
| `SUPER + F` | **Toggle Fullscreen** |
| `SUPER + Tab` | **Toggle Overview** |
| `Print` / `SUPER + Print` | **Screenshots** (saved directly to `~/Pictures/Screenshots`) |
| `XF86AudioRaiseVolume` | **Volume +5%** (sound tick feedback + retro Mako OSD) |
| `XF86AudioLowerVolume` | **Volume -5%** (sound tick feedback + retro Mako OSD) |
| `XF86AudioMute` | **Toggle Audio Mute** (with OSD status) |
| `XF86AudioMicMute` | **Toggle Microphone Mute** (with OSD status) |

---

## 🔊 Audio & OSD Feedback

Volume keys trigger [`~/.config/mango/scripts/volume.sh`](.config/mango/scripts/volume.sh):
1. Adjusts volume using `wpctl`.
2. Emits immediate audio feedback tick using `canberra-gtk-play` or `pw-play` (`audio-volume-change.oga`).
3. Sends a synchronous Mako notification (`-h string:synchronous:volume -h int:value:<pct>`) that updates smoothly in-place without flooding the notification queue.

---

## ⌨️ Cedilla (`ç`) on Wayland / US-Intl

For users with US-International keyboard layouts (`' + c = ç`):
- **Daemon:** Fcitx5 autostarted via [`.config/mango/autostart.sh`](.config/mango/autostart.sh).
- **Environment:** `INPUT_METHOD`, `GTK_IM_MODULE`, `QT_IM_MODULE`, `XMODIFIERS`, and `XCOMPOSEFILE` exported to DBus and systemd in [`.config/mango/env.conf`](.config/mango/env.conf).
- **Compose Table:** Custom [`.XCompose`](.XCompose) file mapping `<dead_acute> + c` to `ç`.
- **Browser Flags:** Automated Wayland IME integration for Brave, Chrome, Chromium, and Electron:
  ```text
  --ozone-platform=wayland
  --enable-wayland-ime
  --wayland-text-input-version=3
  ```

---

## 🍅 Pomodoro & Focus Hub (Waybar + Obsidian Sync)

- **Status Bar Integration:** Embedded left module beside Pac-Man update indicator, styled with glowing CRT phosphor amber (`#e8952d` / `#f2a94a`) and phosphor charging green (`#9dbb5c`) for breaks.
- **Multi-Monitor Lockstep:** Unix Domain Socket Master/Subscriber daemon synchronizing timers across multiple displays (`eDP-1`, `HDMI-A-1`) with zero drift and single-source event logging.
- **Automated Obsidian Logging:** Automatically records completed and interrupted focus sessions into `🍅 Pomodoro & Focus Log.md` in your Obsidian Vault with Dataview inline fields (`(pomodoro:: WORK)`) and daily markdown tables.
- **Vault Task Integration (`SUPER+P`):** Reads pending tasks (`- [ ]`) directly from `🎯 Central de Tarefas & Missão.md` via Rofi, allowing you to pick your active focus topic on the fly.
- **Mouse Controls on Waybar:** Left click to toggle start/pause, Right click to reset, Middle click for Rofi menu, Scroll up/down to skip/reset.

---

## 🎵 Clock Audio Visualizer & Floating CAVA (Waybar + PipeWire)

- **Center Placement:** Embedded in `modules-center` alongside the clock, styled in matching phosphor amber with zero-radius geometry.
- **Live Spectrum Analysis:** Pure monospace Unicode block glyphs (` ▂▄▆▇▅▃ `) reacting to rhythm, bass, and frequencies across all active PipeWire/MPRIS media players.
- **Zero Idle Overhead:** Automatically stops background audio capture and collapses into hidden state (`hide-empty-text: true`) when music is paused or stopped.
- **Interactive Controls & Floating CAVA:**
  - **Left Click:** Toggles a dedicated, floating, centered CAVA terminal window (`kitty --class cava-float`) with a 60fps 6-stop Amberglow phosphor CRT gradient.
  - **Right Click:** Play / Pause.
  - **Middle Click:** Next track.
  - **Scroll Up / Down:** Adjust volume (+- 5%).

---

## 📥 Collapsible System Tray Drawer (Windows-style Chevron)

- **Minimalist Default:** Replaces permanently visible cluttered tray icons with a discrete phosphor chevron (`󰅃`).
- **Click-to-Reveal:** Native Waybar group drawer that expands smoothly to reveal active background system tray icons on click, collapsing back on second click.
- **Seamless Amberglow Integration:** Matches the CRT scanline aesthetic with phosphor amber borders and hover highlights.

---

## 🎛️ Rofi Session & Mode Keyboard Navigation (`SUPER+D`)

- **Cycle Sessions / Modes:** Press `Tab` or `Shift+Right` / `Control+Tab` / `Alt+Right` / `Alt+l` to cycle forward across all 10 modal sessions (`apps`, `run`, `win`, `calc`, `wifi`, `bt`, `keys`, `layout`, `audio`, `notif`).
- **Reverse Cycle:** Press `Shift+Tab` (`ISO_Left_Tab`) or `Shift+Left` / `Control+Shift+Tab` / `Alt+Left` / `Alt+h` to cycle backwards.
- **Entry Navigation:** Standard keyboard navigation (`Up` / `Down`, `Ctrl+P` / `Ctrl+N`) with zero conflicting keybinding warnings.

---

## 🚀 Installation & Maintenance

The repository includes a comprehensive modular installer and manager script (`install.sh`):

### Automated Installation
```sh
# 1. Clone the repository
git clone https://github.com/chevalierjvps/dotfiles.git ~/amberglow-dotfiles
cd ~/amberglow-dotfiles

# 2. Run the interactive installer
./install.sh

# Or run non-interactive symlink setup (recommended for live editing):
./install.sh --link --yes
```

### Modular Component Deployment
Install only the components you need:
```sh
./install.sh -m waybar -m rofi     # Deploy only Waybar and Rofi
./install.sh -m mango -m bin       # Deploy only MangoWM and custom utilities
./install.sh --check              # Check required system dependencies
```

### Continuous Updates & Maintenance
Pull the latest changes, update symlinks, verify execution permissions, and live-reload running components without logging out:
```sh
./install.sh --update
```

---

<div align="center">

Crafted with care by **chevalierjvps**

</div>
