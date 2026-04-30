#!/usr/bin/env bash
set -euo pipefail

if ! command -v mformat >/dev/null 2>&1 || ! command -v mcopy >/dev/null 2>&1; then
  echo "Error: mtools is required: mformat and mcopy were not found." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

exe_path="${1:-$repo_root/build/demo/UI_DEMO.EXE}"
image_path="${2:-$repo_root/build/demo/ui_demo.img}"

if [ ! -f "$exe_path" ]; then
  echo "Error: EXE file not found: $exe_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$image_path")"
rm -f "$image_path"

mformat -C -i "$image_path" -f 1440 ::
mcopy -i "$image_path" -o "$exe_path" ::UI_DEMO.EXE

echo "Created FAT12 floppy image: $image_path"
echo "Copied file: $exe_path -> ::UI_DEMO.EXE"
