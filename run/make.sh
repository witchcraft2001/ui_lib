#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if ! command -v sjasmplus >/dev/null 2>&1; then
  echo "Error: sjasmplus is not installed or not in PATH" >&2
  exit 1
fi

mkdir -p "$repo_root/build/demo" "$repo_root/build/examples"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/demo/UI_DEMO.LST" \
  "$repo_root/examples/demo/ui_demo.asm"

echo "Built $repo_root/build/demo/UI_DEMO.EXE"

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

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/examples/PROGRESS_ONLY.LST" \
  "$repo_root/examples/progress_only/progress_only.asm"

echo "Built $repo_root/build/examples/PROGRESS_ONLY.EXE"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/examples/LIST_ONLY.LST" \
  "$repo_root/examples/list_only/list_only.asm"

echo "Built $repo_root/build/examples/LIST_ONLY.EXE"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/examples/MSGBOX.LST" \
  "$repo_root/examples/msgbox/msgbox.asm"

echo "Built $repo_root/build/examples/MSGBOX.EXE"
