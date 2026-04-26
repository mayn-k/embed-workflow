#!/usr/bin/env bash
#
# embed-session.sh — builds the tmux layout for an embed project
#
# Usage: embed-session.sh <session_name> <project_dir>
#
set -euo pipefail

SESSION="${1:?usage: embed-session.sh <name> <project_dir>}"
PROJECT_DIR="${2:?usage: embed-session.sh <name> <project_dir>}"

[[ -d "$PROJECT_DIR" ]] || { echo "Project dir not found: $PROJECT_DIR"; exit 1; }

# Load board conf so we can set session env vars
BOARD_CONF="$PROJECT_DIR/.embed/board.conf"
if [[ -f "$BOARD_CONF" ]]; then
    # shellcheck disable=SC1090
    source "$BOARD_CONF"
fi

# Kill existing session with same name (fresh layout every launch)
if tmux has-session -t "$SESSION" 2>/dev/null; then
    # If already attached somewhere, just attach. Otherwise recreate.
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$SESSION"
    else
        tmux attach -t "$SESSION"
    fi
    exit 0
fi

# ─── Create session ──────────────────────────────────────────────────────────
tmux new-session -d -s "$SESSION" -n editor -c "$PROJECT_DIR"

# Expose board info to the session (used by popup bindings)
tmux set-environment -t "$SESSION" EMBED_PROJECT_DIR  "$PROJECT_DIR"
tmux set-environment -t "$SESSION" EMBED_SERIAL_PORT  "${SERIAL_PORT:-/dev/ttyACM0}"
tmux set-environment -t "$SESSION" EMBED_SERIAL_BAUD  "${SERIAL_BAUD:-115200}"
tmux set-environment -t "$SESSION" EMBED_BOARD_ID     "${BOARD_ID:-unknown}"

# Window 1: editor — nvim fullscreen
tmux send-keys -t "$SESSION:editor" 'nvim .' C-m

# Window 2: debug — OpenOCD on top, GDB on bottom (not started — press Enter to run)
tmux new-window  -t "$SESSION" -n debug -c "$PROJECT_DIR"
tmux split-window -t "$SESSION:debug" -v -c "$PROJECT_DIR"

# Pre-type the commands but don't execute — user hits Enter when board is plugged in
tmux send-keys -t "$SESSION:debug.0" 'make openocd'
tmux send-keys -t "$SESSION:debug.1" 'make debug'
tmux select-pane -t "$SESSION:debug.0"

# Land the user on editor
tmux select-window -t "$SESSION:editor"

# Attach / switch
if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach -t "$SESSION"
fi
