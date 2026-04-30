#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if ! command -v sjasmplus >/dev/null 2>&1; then
  echo "Error: sjasmplus is not installed or not in PATH" >&2
  exit 1
fi

mkdir -p "$repo_root/build/demo"

sjasmplus \
  --nologo \
  --syntax=f \
  --fullpath \
  --lst="$repo_root/build/demo/UI_DEMO.LST" \
  "$repo_root/examples/demo/ui_demo.asm"

echo "Built $repo_root/build/demo/UI_DEMO.EXE"
