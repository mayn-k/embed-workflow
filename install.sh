#!/usr/bin/env bash
#
# install.sh — wire the embed workflow into the user's system.
#
# Run this ONCE after cloning/unzipping. It:
#   1. Symlinks `embed` and `embed-session.sh` into ~/.local/bin/
#   2. Makes scripts executable
#   3. Adds a source-file line to ~/.tmux.conf for the popup bindings
#   4. Symlinks nvim/embed.lua into ~/.config/nvim/lua/ (if that dir exists)
#   5. Checks for required tools and reports what's missing
#
set -euo pipefail

EMBED_ROOT="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

C_GRN=$'\e[32m'; C_YLW=$'\e[33m'; C_RED=$'\e[31m'; C_BLU=$'\e[34m'; C_RST=$'\e[0m'
say()  { printf '%s▸%s %s\n' "$C_BLU" "$C_RST" "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YLW" "$C_RST" "$*"; }
bad()  { printf '%s✗%s %s\n' "$C_RED" "$C_RST" "$*"; }

echo
say "embed workflow installer — $EMBED_ROOT"
echo

# ─── 1. Make scripts executable ──────────────────────────────────────────────
say "Setting executable bits"
chmod +x "$EMBED_ROOT/bin/embed"
chmod +x "$EMBED_ROOT/tmux/embed-session.sh"
find "$EMBED_ROOT/templates" -name "*.sh" -exec chmod +x {} \;
ok "Scripts are now executable"

# ─── 2. Symlink into ~/.local/bin ────────────────────────────────────────────
say "Symlinking binaries into ~/.local/bin"
mkdir -p "$HOME/.local/bin"
ln -sfn "$EMBED_ROOT/bin/embed"              "$HOME/.local/bin/embed"
ln -sfn "$EMBED_ROOT/bin/embed-doctor"       "$HOME/.local/bin/embed-doctor"
ln -sfn "$EMBED_ROOT/tmux/embed-session.sh"  "$HOME/.local/bin/embed-session.sh"
# Popup helpers (called by tmux bindings — must be on PATH)
for helper in "$EMBED_ROOT"/bin/embed-popup-*; do
    [[ -f "$helper" ]] || continue
    ln -sfn "$helper" "$HOME/.local/bin/$(basename "$helper")"
done
ok "Symlinked: embed, embed-session.sh, embed-popup-* (shell/serial/build/flash/erase)"

# Ensure ~/.local/bin is on PATH
if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    warn "~/.local/bin is not on your PATH. Add this to ~/.bashrc and ~/.zshrc:"
    warn "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ─── 3. tmux config ──────────────────────────────────────────────────────────
say "Wiring tmux config"
TMUX_CONF="$HOME/.tmux.conf"
SOURCE_LINE="source-file $EMBED_ROOT/tmux/embed.tmux.conf"
if [[ -f "$TMUX_CONF" ]]; then
    if grep -Fxq "$SOURCE_LINE" "$TMUX_CONF"; then
        ok "tmux config already sources embed.tmux.conf"
    else
        {
            echo ""
            echo "# Added by embed-workflow installer"
            echo "$SOURCE_LINE"
        } >> "$TMUX_CONF"
        ok "Appended source-file line to $TMUX_CONF"
        warn "Reload tmux config: prefix + r  (or: tmux source ~/.tmux.conf)"
    fi
else
    warn "No ~/.tmux.conf found. Skipping — add this line yourself when ready:"
    warn "  $SOURCE_LINE"
fi

# ─── 4. Neovim plugins ───────────────────────────────────────────────────────
say "Installing neovim plugin files"
NVIM_PLUGINS_DIR="$HOME/.config/nvim/lua/plugins"
NVIM_LUA_DIR="$HOME/.config/nvim/lua"
if [[ -d "$NVIM_LUA_DIR" ]]; then
    mkdir -p "$NVIM_PLUGINS_DIR"
    # The embed.lua standalone module (for :Build :Flash :Debug etc.)
    ln -sfn "$EMBED_ROOT/nvim/embed.lua" "$NVIM_LUA_DIR/embed.lua"
    ok "Symlinked $NVIM_LUA_DIR/embed.lua"

    # Drop-in plugin files that lazy.nvim will auto-load
    for plugin in "$EMBED_ROOT"/nvim/plugins/*.lua; do
        [[ -f "$plugin" ]] || continue
        name="$(basename "$plugin")"
        target="$NVIM_PLUGINS_DIR/$name"
        if [[ -e "$target" && ! -L "$target" ]]; then
            warn "  $target already exists (not a symlink) — skipped. Back it up and re-run."
        else
            ln -sfn "$plugin" "$target"
            ok "  $NVIM_PLUGINS_DIR/$name"
        fi
    done

    warn "Add ONE line to ~/.config/nvim/init.lua to activate embed commands:"
    warn "  require(\"embed\").setup()"
    warn ""
    warn "After restarting nvim, run :Lazy sync to install mason/lspconfig/cmp."
    warn "Then inside nvim: :Mason  →  install 'clangd'"
else
    warn "No ~/.config/nvim/lua/ directory found. Skipping neovim wiring."
    warn "If you want the nvim integration, first initialize your config, then re-run install.sh."
fi

# ─── 5. Projects dir ─────────────────────────────────────────────────────────
PROJECTS_DIR="$HOME/work/embedded_systems/projects"
mkdir -p "$PROJECTS_DIR"
ok "Projects dir ready: $PROJECTS_DIR"

# ─── 6. Dependency check ─────────────────────────────────────────────────────
echo
say "Checking required tools"
missing=()
check() {
    local cmd="$1" pkg="$2" optional="${3:-no}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$cmd  ($(command -v "$cmd"))"
    else
        if [[ "$optional" == "yes" ]]; then
            warn "$cmd missing (optional) — install: $pkg"
        else
            bad "$cmd missing — install: $pkg"
            missing+=("$pkg")
        fi
    fi
}

check tmux                   "sudo apt install tmux"
check nvim                   "sudo apt install neovim"
check arm-none-eabi-gcc      "sudo apt install gcc-arm-none-eabi"
check arm-none-eabi-gdb      "sudo apt install gdb-multiarch  # provides gdb for arm"
check openocd                "sudo apt install openocd"
check st-flash               "sudo apt install stlink-tools" yes
check tio                    "sudo apt install tio"
check bear                   "sudo apt install bear"          yes
check fzf                    "sudo apt install fzf"           yes
check git                    "sudo apt install git"

# tmux version check — display-popup requires >= 3.2
if command -v tmux >/dev/null 2>&1; then
    tmux_ver="$(tmux -V | awk '{print $2}' | tr -d '[:alpha:]')"
    tmux_major="${tmux_ver%%.*}"
    tmux_minor="${tmux_ver#*.}"
    tmux_minor="${tmux_minor%%.*}"
    if [[ "$tmux_major" -lt 3 ]] || { [[ "$tmux_major" -eq 3 ]] && [[ "$tmux_minor" -lt 2 ]]; }; then
        bad "tmux $tmux_ver is too old — popups need tmux >= 3.2"
        warn "Upgrade: sudo apt install tmux  (Pop!_OS 24.04 ships 3.4)"
    else
        ok "tmux $tmux_ver supports display-popup"
    fi
fi

# arm-none-eabi-gdb — ubuntu often ships only gdb-multiarch; symlink or alias
if ! command -v arm-none-eabi-gdb >/dev/null 2>&1; then
    if command -v gdb-multiarch >/dev/null 2>&1; then
        warn "arm-none-eabi-gdb not found, but gdb-multiarch is available."
        warn "You can symlink it:"
        warn "  sudo ln -s \$(which gdb-multiarch) /usr/local/bin/arm-none-eabi-gdb"
    fi
fi

# udev rules for ST-Link (so you don't need sudo to flash)
say "Checking ST-Link udev rules"
if [[ -f /etc/udev/rules.d/49-stlinkv2-1.rules ]] || \
   [[ -f /etc/udev/rules.d/49-stlinkv2.rules ]]  || \
   [[ -f /lib/udev/rules.d/60-openocd.rules ]]; then
    ok "ST-Link udev rules present"
else
    warn "No ST-Link udev rules found. Without them, OpenOCD needs sudo."
    warn "Install with: sudo apt install stlink-tools  (drops the rules in place)"
    warn "Then: sudo udevadm control --reload-rules && sudo udevadm trigger"
fi

echo
if [[ ${#missing[@]} -eq 0 ]]; then
    ok "All required tools installed. You're ready."
else
    bad "Missing required tools. Install them before using embed:"
    for p in "${missing[@]}"; do echo "     $p"; done
fi

echo
cat <<EOF
${C_BLU}Next steps:${C_RST}
  1. Reload your shell (or: source ~/.zshrc)
  2. Reload tmux config: tmux kill-server  (or  prefix + r in an existing session)
  3. Add to your nvim init.lua:  require("embed").setup()
  4. Try it:
       ${C_GRN}embed list boards${C_RST}
       ${C_GRN}embed new blink nucleo-l476rg${C_RST}
       ${C_GRN}embed new rtos-demo nucleo-l476rg --os=freertos${C_RST}

${C_BLU}tmux bindings (prefix = C-s):${C_RST}
  prefix + g     shell popup
  prefix + t     serial (tio) popup
  prefix + B     build popup
  prefix + F     flash popup
  prefix + E     erase chip (confirm)
  prefix + S     fuzzy-pick embed project

${C_BLU}nvim commands:${C_RST}
  :Build :Flash :Debug :DebugWin :Monitor :Erase :Reset :Size :Ccdb :EmbedClean
  Default keymaps: <leader>mb / mf / md / mw / mm / ms / mc / me / mr
EOF
