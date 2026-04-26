#!/usr/bin/env bash
# .embed/serial.sh — open tio on the board's configured port
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$DIR/board.conf"
if ! command -v tio >/dev/null 2>&1; then
    echo "tio not installed. Install with: sudo apt install tio"
    echo "Press Enter to close..."; read -r
    exit 1
fi
echo "Connecting to $SERIAL_PORT @ $SERIAL_BAUD (Ctrl-T ? for tio help, Ctrl-T q to quit)"
exec tio "$SERIAL_PORT" -b "$SERIAL_BAUD"
