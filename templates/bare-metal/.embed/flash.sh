#!/usr/bin/env bash
# .embed/flash.sh — build if needed, then flash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
make flash
