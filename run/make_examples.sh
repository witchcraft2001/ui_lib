#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if ! command -v sjasmplus >/dev/null 2>&1; then
  echo "Error: sjasmplus is not installed or not in PATH" >&2
  exit 1
fi

mkdir -p "$repo_root/build/examples"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/examples/BUTTON_ONLY.LST" \
  "$repo_root/examples/button_only/button_only.asm"

echo "Built $repo_root/build/examples/BUTTON_ONLY.EXE"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/examples/MENU_ONLY.LST" \
  "$repo_root/examples/menu_only/menu_only.asm"

echo "Built $repo_root/build/examples/MENU_ONLY.EXE"
