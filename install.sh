#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  ⚡ AMBERGLOW DOTFILES — MODULAR INSTALLER & MANAGER ⚡
#  Supports modular installation, symlinking, automated backups, dependency
#  checks, and live reload for MangoWM, Waybar, Rofi, Mako, and Alacritty.
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors (Amberglow CRT Phosphor Palette)
AMBER='\033[38;2;232;149;45m'
BRIGHT_AMBER='\033[38;2;242;169;74m'
DIM_AMBER='\033[38;2;138;125;99m'
GREEN='\033[38;2;157;187;92m'
RED='\033[38;2;217;83;79m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_HOME="${HOME}"
BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Flags & Options
MODE="link"         # "link" or "copy"
DO_BACKUP=true
NON_INTERACTIVE=false
DRY_RUN=false
SELECTED_MODULES=()

log_info() {
    echo -e "${DIM_AMBER}[INFO]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[ OK ]${NC} $1"
}

log_warn() {
    echo -e "${AMBER}[WARN]${NC} $1"
}

log_err() {
    echo -e "${RED}[ERR ]${NC} $1" >&2
}

log_step() {
    echo -e "${BRIGHT_AMBER}${BOLD}❯ $1${NC}"
}

print_banner() {
    echo -e "${AMBER}${BOLD}"
    cat << "EOF"
    ░█████╗░███╗░░░███╗██████╗░███████╗██████╗░░██████╗░██╗░░░░░░█████╗░░██╗░░░░░░░██╗
    ██╔══██╗████╗░████║██╔══██╗██╔════╝██╔══██╗██╔════╝░██║░░░░░██╔══██╗░██║░░██╗░░██║
    ███████║██╔████╔██║██████╦╝█████╗░░██████╔╝██║░░██╗░██║░░░░░██║░░██║░╚██╗████╗██╔╝
    ██╔══██║██║╚██╔╝██║██╔══██╗██╔══╝░░██╔══██╗██║░░╚██╗██║░░░░░██║░░██║░░████╔═████║░
    ██║░░██║██║░╚═╝░██║██████╦╝███████╗██║░░██║╚██████╔╝███████╗╚█████╔╝░░╚██╔╝░╚██╔╝░
    ╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝░╚═════╝░╚══════╝░╚════╝░░░░░╚═╝░░░╚═╝░░
EOF
    echo -e "${BRIGHT_AMBER}        Retro CRT Phosphor Rice • Modular Dotfiles Manager & Installer${NC}\n"
}

print_help() {
    print_banner
    cat << EOF
Usage: ./install.sh [options]

Modes:
  -l, --link              Symlink files to \$HOME (Recommended for active maintenance)
  -c, --copy              Copy files to \$HOME instead of symlinking
  -b, --backup            Create timestamped backup before modifying files (Default: enabled)
  --no-backup             Skip backup creation
  -n, --dry-run           Preview actions without writing any files
  -y, --yes               Non-interactive mode (use defaults without prompting)

Components / Modules:
  -m, --module <name>     Install only a specific module. Can be specified multiple times.
                          Available modules:
                            • mango      (MangoWM compositor configs, rules, binds & scripts)
                            • waybar     (Waybar status bar config, styles, Pomodoro & scripts)
                            • rofi       (Rofi launcher themes & custom modal script modes)
                            • mako       (Mako notification daemon & OSD volume widget)
                            • alacritty  (Alacritty terminal emulator theme & font config)
                            • kitty      (Kitty terminal emulator theme, opacity & font config)
                            • cava       (CAVA audio visualizer Amberglow CRT theme & configs)
                            • bin        (Helper binaries, wrappers & utilities in ~/.local/bin)
                            • desktop    (Desktop application overrides & Chromium themes)
                            • env        (Environment.d configs, browser Wayland flags & .XCompose)
                            • mangohud   (MangoHud desktop silent configuration)
                            • all        (All of the above — Default)

Maintenance Actions:
  --check                 Perform dependency and environment health check
  --reload                Reload MangoWM, Waybar, and Mako without logging out
  -u, --update            Pull latest git changes, re-link/refresh permissions & reload
  -h, --help              Show this help message

Examples:
  ./install.sh                      # Interactive modular installation
  ./install.sh --link --yes          # Full automated symlink setup
  ./install.sh -m waybar -m rofi     # Install only Waybar and Rofi
  ./install.sh --check              # Verify required dependencies
  ./install.sh --update             # Pull latest updates and reload environment
EOF
}

# ──────────────────────────────────────────────────────────────────────────────
#  DEPENDENCY CHECKER
# ──────────────────────────────────────────────────────────────────────────────
check_dependencies() {
    log_step "Checking System Dependencies..."
    local missing=()
    local optional_missing=()

    local required_pkgs=(
        "mango:mangowc or mango compositor"
        "waybar:waybar status bar"
        "rofi:rofi or rofi-wayland"
        "mako:mako notification daemon"
        "alacritty:alacritty terminal"
        "kitty:kitty terminal emulator"
        "fcitx5:fcitx5 input method"
        "jq:jq JSON processor"
        "playerctl:playerctl media controller"
        "wpctl:wireplumber audio control"
        "cava:cava console audio visualizer (clock spectrum analyzer)"
        "notify-send:libnotify notification utility"
    )

    for item in "${required_pkgs[@]}"; do
        local bin="${item%%:*}"
        local desc="${item#*:}"
        if command -v "$bin" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} ${bin} (${desc})"
        else
            echo -e "  ${RED}✗${NC} ${bin} (${desc}) — ${RED}MISSING${NC}"
            missing+=("$bin")
        fi
    done

    # Font check
    echo -n "  Checking font 'DepartureMono Nerd Font'... "
    if fc-list : family | grep -iq "DepartureMono Nerd Font"; then
        echo -e "${GREEN}✓ Found${NC}"
    else
        echo -e "${AMBER}! Not found (recommended: install ttf-departure-mono-nerd via paru/AUR)${NC}"
        optional_missing+=("ttf-departure-mono-nerd")
    fi

    echo ""
    if [ ${#missing[@]} -eq 0 ]; then
        log_ok "All core dependencies are satisfied!"
    else
        log_warn "Missing required packages: ${missing[*]}"
        echo -e "Install them on Arch Linux via:"
        echo -e "${AMBER}sudo pacman -S --needed ${missing[*]}${NC}\n"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  BACKUP HELPER
# ──────────────────────────────────────────────────────────────────────────────
backup_target() {
    local target="$1"
    if [ "$DO_BACKUP" = false ]; then
        return 0
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY-RUN] Would backup: $target -> $BACKUP_DIR/"
            return 0
        fi

        mkdir -p "$BACKUP_DIR"
        local rel_path="${target#"$TARGET_HOME"/}"
        local dest_dir="$BACKUP_DIR/$(dirname "$rel_path")"
        mkdir -p "$dest_dir"
        cp -a "$target" "$dest_dir/"
        log_info "Backed up: $rel_path"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  INSTALLATION ENGINE (LINK OR COPY)
# ──────────────────────────────────────────────────────────────────────────────
deploy_file() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        return 0
    fi

    # Skip if src and dest are the exact same file path (e.g. repo is directly in $HOME)
    if [ "$src" = "$dest" ]; then
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY-RUN] Would deploy ($MODE): $src -> $dest"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    backup_target "$dest"

    if [ "$MODE" = "link" ]; then
        ln -sfn "$src" "$dest"
    else
        rm -rf "$dest"
        cp -a "$src" "$dest"
    fi
}

deploy_directory_contents() {
    local src_dir="$1"
    local dest_dir="$2"

    if [ ! -d "$src_dir" ]; then
        return 0
    fi

    # If repo is already located directly in $HOME, directory contents are already in place
    if [ "$src_dir" = "$dest_dir" ]; then
        return 0
    fi

    mkdir -p "$dest_dir"
    for item in "$src_dir"/*; do
        [ -e "$item" ] || continue
        local basename
        basename="$(basename "$item")"
        deploy_file "$item" "$dest_dir/$basename"
    done
}

# ──────────────────────────────────────────────────────────────────────────────
#  MODULES
# ──────────────────────────────────────────────────────────────────────────────
install_mango() {
    log_step "Installing MangoWM Compositor Config..."
    if [ "$REPO_DIR/.config/mango" != "$TARGET_HOME/.config/mango" ]; then
        deploy_directory_contents "$REPO_DIR/.config/mango" "$TARGET_HOME/.config/mango"
    fi
    chmod +x "$TARGET_HOME"/.config/mango/scripts/*.sh "$TARGET_HOME"/.config/mango/autostart.sh 2>/dev/null || true
    log_ok "MangoWM configuration deployed."
}

install_waybar() {
    log_step "Installing Waybar & Pomodoro Module..."
    if [ "$REPO_DIR/.config/waybar/mango" != "$TARGET_HOME/.config/waybar/mango" ]; then
        deploy_directory_contents "$REPO_DIR/.config/waybar/mango" "$TARGET_HOME/.config/waybar/mango"
    fi
    chmod +x "$TARGET_HOME"/.config/waybar/mango/scripts/*.sh \
             "$TARGET_HOME"/.config/waybar/mango/scripts/*.py 2>/dev/null || true
    log_ok "Waybar configuration & scripts deployed."
}

install_rofi() {
    log_step "Installing Rofi Themes & Script Modes..."
    if [ "$REPO_DIR/.config/rofi" != "$TARGET_HOME/.config/rofi" ]; then
        deploy_directory_contents "$REPO_DIR/.config/rofi" "$TARGET_HOME/.config/rofi"
    fi
    chmod +x "$TARGET_HOME"/.config/rofi/scripts/*.sh 2>/dev/null || true
    log_ok "Rofi configurations deployed."
}

install_mako() {
    log_step "Installing Mako Notification Config..."
    if [ "$REPO_DIR/.config/mako" != "$TARGET_HOME/.config/mako" ]; then
        deploy_directory_contents "$REPO_DIR/.config/mako" "$TARGET_HOME/.config/mako"
    fi
    log_ok "Mako configuration deployed."
}

install_alacritty() {
    log_step "Installing Alacritty Terminal Config..."
    if [ "$REPO_DIR/.config/alacritty" != "$TARGET_HOME/.config/alacritty" ]; then
        deploy_directory_contents "$REPO_DIR/.config/alacritty" "$TARGET_HOME/.config/alacritty"
    fi
    log_ok "Alacritty configuration deployed."
}

install_kitty() {
    log_step "Installing Kitty Terminal Config..."
    if [ "$REPO_DIR/.config/kitty" != "$TARGET_HOME/.config/kitty" ]; then
        deploy_directory_contents "$REPO_DIR/.config/kitty" "$TARGET_HOME/.config/kitty"
    fi
    log_ok "Kitty configuration deployed."
}

install_cava() {
    log_step "Installing CAVA Audio Visualizer Config..."
    if [ "$REPO_DIR/.config/cava" != "$TARGET_HOME/.config/cava" ]; then
        deploy_directory_contents "$REPO_DIR/.config/cava" "$TARGET_HOME/.config/cava"
    fi
    log_ok "CAVA configuration deployed."
}

install_mangohud() {
    log_step "Installing MangoHud Silent Desktop Config..."
    if [ "$REPO_DIR/.config/MangoHud" != "$TARGET_HOME/.config/MangoHud" ]; then
        deploy_directory_contents "$REPO_DIR/.config/MangoHud" "$TARGET_HOME/.config/MangoHud"
    fi
    log_ok "MangoHud configuration deployed."
}

install_bin() {
    log_step "Installing Helper Binaries & Custom Utilities (~/.local/bin)..."
    if [ "$REPO_DIR/.local/bin" != "$TARGET_HOME/.local/bin" ]; then
        deploy_directory_contents "$REPO_DIR/.local/bin" "$TARGET_HOME/.local/bin"
    fi
    chmod +x "$TARGET_HOME"/.local/bin/* 2>/dev/null || true
    log_ok "Helper binaries deployed."
}

install_desktop() {
    log_step "Installing Desktop Entries & Chromium Themes..."
    if [ "$REPO_DIR/.local/share/applications" != "$TARGET_HOME/.local/share/applications" ]; then
        deploy_directory_contents "$REPO_DIR/.local/share/applications" "$TARGET_HOME/.local/share/applications"
    fi
    if [ "$REPO_DIR/.local/share/chrome-themes" != "$TARGET_HOME/.local/share/chrome-themes" ]; then
        deploy_directory_contents "$REPO_DIR/.local/share/chrome-themes" "$TARGET_HOME/.local/share/chrome-themes"
    fi
    log_ok "Desktop entries and themes deployed."
}

install_env() {
    log_step "Installing Environment, Flags & Compose Tables..."
    if [ "$REPO_DIR/.config/environment.d" != "$TARGET_HOME/.config/environment.d" ]; then
        deploy_directory_contents "$REPO_DIR/.config/environment.d" "$TARGET_HOME/.config/environment.d"
    fi

    for f in "$REPO_DIR"/.config/*flags.conf; do
        [ -f "$f" ] || continue
        deploy_file "$f" "$TARGET_HOME/.config/$(basename "$f")"
    done

    if [ -f "$REPO_DIR/.XCompose" ]; then
        deploy_file "$REPO_DIR/.XCompose" "$TARGET_HOME/.XCompose"
    fi
    log_ok "Environment and IME configs deployed."
}

# ──────────────────────────────────────────────────────────────────────────────
#  LIVE RELOAD
# ──────────────────────────────────────────────────────────────────────────────
reload_environment() {
    log_step "Reloading Active Desktop Components..."

    # Reload MangoWM
    if command -v mmsg >/dev/null 2>&1; then
        echo -n "  Reloading MangoWM config... "
        if mmsg dispatch reload_config >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Success${NC}"
        else
            echo -e "${AMBER}! Failed (Compositor may not be active)${NC}"
        fi
    fi

    # Reload Waybar
    if [ -f "$TARGET_HOME/.local/bin/restart-waybar" ]; then
        echo -n "  Restarting Waybar... "
        "$TARGET_HOME/.local/bin/restart-waybar" >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Success${NC}"
    fi

    # Reload Mako
    if command -v makoctl >/dev/null 2>&1; then
        echo -n "  Reloading Mako notification daemon... "
        makoctl reload >/dev/null 2>&1 || true
        echo -e "${GREEN}✓ Success${NC}"
    fi

    # Reload Kitty
    if command -v killall >/dev/null 2>&1; then
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi

    log_ok "Live reload completed!"
}

# ──────────────────────────────────────────────────────────────────────────────
#  GIT UPDATE
# ──────────────────────────────────────────────────────────────────────────────
update_dotfiles() {
    log_step "Updating Dotfiles from Git..."
    if [ -d "$REPO_DIR/.git" ]; then
        git -C "$REPO_DIR" pull --rebase origin main || {
            log_warn "Git pull failed or has conflicts. Continuing with local files."
        }
    fi
    SELECTED_MODULES=("all")
    execute_installation
    reload_environment
    log_ok "Dotfiles successfully updated and reloaded!"
}

# ──────────────────────────────────────────────────────────────────────────────
#  EXECUTE MODULES
# ──────────────────────────────────────────────────────────────────────────────
execute_installation() {
    local modules=("${SELECTED_MODULES[@]}")
    if [ ${#modules[@]} -eq 0 ] || [[ " ${modules[*]} " =~ " all " ]]; then
        modules=("mango" "waybar" "rofi" "mako" "alacritty" "kitty" "cava" "mangohud" "bin" "desktop" "env")
    fi

    log_info "Installation mode: ${BOLD}${MODE}${NC}"
    log_info "Selected modules: ${BOLD}${modules[*]}${NC}"
    echo ""

    for mod in "${modules[@]}"; do
        case "$mod" in
            mango)     install_mango ;;
            waybar)    install_waybar ;;
            rofi)      install_rofi ;;
            mako)      install_mako ;;
            alacritty) install_alacritty ;;
            kitty)     install_kitty ;;
            cava)      install_cava ;;
            mangohud)  install_mangohud ;;
            bin)       install_bin ;;
            desktop)   install_desktop ;;
            env)       install_env ;;
            *)         log_warn "Unknown module: $mod" ;;
        esac
    done

    if [ "$DO_BACKUP" = true ] && [ -d "$BACKUP_DIR" ]; then
        log_ok "Backups saved to: ${BOLD}$BACKUP_DIR${NC}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
#  INTERACTIVE MENU
# ──────────────────────────────────────────────────────────────────────────────
run_interactive() {
    print_banner

    echo -e "${BOLD}Welcome to the Amberglow Dotfiles Installer!${NC}\n"
    echo -e "Choose your installation method:"
    echo -e "  ${AMBER}1)${NC} ${BOLD}Symlink Mode${NC} (Recommended — Live editing syncs directly to git)"
    echo -e "  ${AMBER}2)${NC} ${BOLD}Copy Mode${NC}    (Standalone copy into ~/.config)"
    echo -e "  ${AMBER}3)${NC} ${BOLD}Check Dependencies${NC}"
    echo -e "  ${AMBER}4)${NC} ${BOLD}Update & Reload${NC}"
    echo -e "  ${AMBER}5)${NC} ${BOLD}Exit${NC}"
    echo ""
    read -rp "Select an option [1-5] (default: 1): " choice
    choice="${choice:-1}"

    case "$choice" in
        1)
            MODE="link"
            SELECTED_MODULES=("all")
            execute_installation
            reload_environment
            ;;
        2)
            MODE="copy"
            SELECTED_MODULES=("all")
            execute_installation
            reload_environment
            ;;
        3)
            check_dependencies
            ;;
        4)
            update_dotfiles
            ;;
        5)
            echo "Exiting."
            exit 0
            ;;
        *)
            log_err "Invalid selection."
            exit 1
            ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────────
#  CLI ARGUMENT PARSER
# ──────────────────────────────────────────────────────────────────────────────
main() {
    if [ $# -eq 0 ]; then
        run_interactive
        exit 0
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            -l|--link)
                MODE="link"
                ;;
            -c|--copy)
                MODE="copy"
                ;;
            -b|--backup)
                DO_BACKUP=true
                ;;
            --no-backup)
                DO_BACKUP=false
                ;;
            -n|--dry-run)
                DRY_RUN=true
                ;;
            -y|--yes)
                NON_INTERACTIVE=true
                ;;
            -m|--module)
                shift
                if [ $# -gt 0 ]; then
                    SELECTED_MODULES+=("$1")
                fi
                ;;
            --check)
                print_banner
                check_dependencies
                exit 0
                ;;
            --reload)
                reload_environment
                exit 0
                ;;
            -u|--update)
                update_dotfiles
                exit 0
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                log_err "Unknown argument: $1"
                print_help
                exit 1
                ;;
        esac
        shift
    done

    print_banner
    execute_installation
    if [ "$NON_INTERACTIVE" = false ]; then
        read -rp "Do you want to reload running desktop components now? [Y/n]: " do_reload
        if [[ ! "$do_reload" =~ ^[Nn] ]]; then
            reload_environment
        fi
    fi
}

main "$@"
