#!/usr/bin/env bash
# .embed/build.sh — build the project
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
make
