# Amberglow

A retro CRT/phosphor rice for [MangoWM](https://github.com/mangowm/mango), an
Arch/CachyOS wlroots compositor. Warm amber-on-dark palette, sharp corners,
solid panels (no glassmorphism), DepartureMono Nerd Font throughout.

This repo tracks *only* the rice files, out of an otherwise-untracked `$HOME`
— see `.gitignore` if you're wondering why `git status` looks empty on
everything else.

## What's here

| Path | What |
| --- | --- |
| `.config/mango/` | Compositor config: binds, rules, monitors, autostart, per-device keyboard/input rules |
| `.config/waybar/mango/` | Bar: launcher, tags, window title, mpris, weather, Pac-Man update-chomper, system tray, notifications, etc. |
| `.config/rofi/` | Launcher theme + custom script-modes (calc, wifi, bluetooth, keybind cheatsheet, emoji picker, notification manager, powermenu, wallpaper picker, clipboard) |
| `.config/mako/config` | Notification daemon theme + do-not-disturb mode |
| `.config/environment.d/` | Session-wide env fixes (MangoHud Vulkan-layer crash workaround, cursor theme, a Chromium GPU-crash workaround for ZapZap) |
| `.local/share/applications/` | `.desktop` overrides that bake in browser launch flags (Chromium theme extension, GPU flags) |
| `.local/share/chrome-themes/` | Unpacked Chromium "theme" extensions (Helium, Brave) — loaded via `--load-extension`, no manual install needed |
| `browser-themes/` | `userChrome.css`/`user.js` for Firefox-family browsers (Zen, LibreWolf) — copied out of the live profile since profile dirs are random per-install hashes, not symlinked |
| `ly-theme/config.ini` | Themed `ly` display-manager config (lives at `/etc/ly/config.ini`, root-owned, so it's kept here for reference/reapplication) |

## Installing on a new machine

1. **Packages** (Arch/CachyOS names): `mangowm waybar rofi mako swaybg swayidle
   swaylock kitty nautilus brightnessctl playerctl wireplumber pipewire-pulse
   jq python3 pacman-contrib` plus AUR: `ly nerd-fonts-departure-mono
   bibata-cursor-theme-bin papirus-icon-theme-git` (or whatever provides
   `Bibata-Modern-Amber` and `Papirus-Dark`). `paru`/`yay` if you want the
   Pac-Man waybar module to also count AUR updates.

2. **Clone into place** (this repo *is* meant to be your `$HOME`, or cherry-pick
   the paths above into an existing one):

   ```sh
   git clone <this-repo-url> ~/amberglow-dotfiles
   cd ~/amberglow-dotfiles
   cp -r .config/mango .config/waybar .config/rofi .config/mako ~/.config/
   mkdir -p ~/.config/environment.d
   cp .config/environment.d/*.conf ~/.config/environment.d/
   mkdir -p ~/.local/share/applications ~/.local/share/chrome-themes
   cp .local/share/applications/*.desktop ~/.local/share/applications/
   cp -r .local/share/chrome-themes/* ~/.local/share/chrome-themes/
   chmod +x ~/.config/mango/scripts/*.sh ~/.config/mango/autostart.sh \
            ~/.config/waybar/mango/scripts/*.sh ~/.config/rofi/scripts/*.sh
   ```

3. **Fix hardcoded paths.** The `.desktop` overrides and a couple of scripts
   hardcode `/home/jagermeister/...` — if your username differs, `sed -i
   "s#/home/jagermeister#$HOME#g"` across `.local/share/applications/*.desktop`
   and `.config/mango/bind.conf`.

4. **Per-device keyboard rules** in `.config/mango/config.conf` (the
   `devicerule=name:...` lines) are pinned to *this machine's* exact device
   names (`AT Translated Set 2 keyboard`, `ROYUAN Gaming Keyboard`). Run
   `mmsg get all-devices` on the new machine and update the names, or delete
   those two lines if you don't need per-keyboard layouts.

5. **Browser themes:**
   - **Helium / Brave** (Chromium-based): already wired via `--load-extension`
     in the `.desktop` overrides — nothing else to do once the
     `chrome-themes/` files are in place.
   - **Zen / LibreWolf** (Firefox-based): find your actual profile dir
     (`~/.zen/<hash>.Default*` or
     `~/.config/librewolf/librewolf/<hash>.default*`), then:
     ```sh
     mkdir -p <profile-dir>/chrome
     cp browser-themes/zen/userChrome.css <profile-dir>/chrome/        # Zen
     cp browser-themes/librewolf/* <profile-dir>/chrome/ ; \
       cp browser-themes/librewolf/user.js <profile-dir>/               # LibreWolf
     ```
     Both need `toolkit.legacyUserProfileCustomizations.stylesheets = true`
     (LibreWolf's `user.js` here already sets it; for Zen, set it in
     `about:config`).

6. **`ly`:** `sudo cp ly-theme/config.ini /etc/ly/config.ini` (back up the
   original first: `sudo cp /etc/ly/config.ini /etc/ly/config.ini.bak`).

7. Log out and back in (or reboot) so `environment.d` and the display manager
   pick everything up, then `mmsg dispatch reload_config` if you tweak
   anything live afterward.

## Keybinds

~90 binds total, all in `.config/mango/bind.conf` with section comments. The
notable custom ones:

| Key | Action |
| --- | --- |
| `SUPER+D` / `SUPER+Ctrl+Return` | rofi launcher (apps, run, windows, calc, wifi, bluetooth, keybind cheatsheet, emoji, notifications — cycle with Shift+Tab) |
| `SUPER+V` | clipboard history (with image thumbnails) |
| `SUPER+Shift+Q` | power menu |
| `SUPER+Shift+W` | wallpaper picker |
| `SUPER+Shift+E` | Nautilus scratchpad (toggle) |
| `SUPER+Shift+T` | kitty scratchpad (toggle) |
| `SUPER+E` | file manager |
| `SUPER+W` / `SUPER+B` | browser |
| `SUPER+J` | Ryotunes, floating and centered |
| `Print` / `SUPER+Print` / `SUPER+Shift+Print` | screenshots — always saved to `~/Pictures/Screenshots`, not just clipboard |

Everything else (window management, tags/workspaces, media keys, monitor
toggling) mirrors what you'd expect from a `niri`-style setup — see the file
itself, it's commented section by section.
