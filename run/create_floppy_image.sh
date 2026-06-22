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
image_exe_name="${3:-UI_DEMO.EXE}"
include_default_examples=0

if [ "$#" -eq 0 ]; then
  include_default_examples=1
fi

if [ ! -f "$exe_path" ]; then
  echo "Error: EXE file not found: $exe_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$image_path")"
rm -f "$image_path"

mformat -C -i "$image_path" -f 1440 ::
mcopy -i "$image_path" -o "$exe_path" ::"$image_exe_name"

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/BUTTON_ONLY.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/BUTTON_ONLY.EXE" ::BUTTON.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/MENU_ONLY.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/MENU_ONLY.EXE" ::MENU.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/PROGRESS_ONLY.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/PROGRESS_ONLY.EXE" ::PROGRESS.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/LIST_ONLY.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/LIST_ONLY.EXE" ::LIST.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/MSGBOX.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/MSGBOX.EXE" ::MSGBOX.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/TEXTVIEW.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/TEXTVIEW.EXE" ::TEXTVIEW.EXE
fi

if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/CTXMENU.EXE" ]; then
  mcopy -i "$image_path" -o "$repo_root/build/examples/CTXMENU.EXE" ::CTXMENU.EXE
fi

echo "Created FAT12 floppy image: $image_path"
echo "Copied file: $exe_path -> ::$image_exe_name"
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/BUTTON_ONLY.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/BUTTON_ONLY.EXE -> ::BUTTON.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/MENU_ONLY.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/MENU_ONLY.EXE -> ::MENU.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/PROGRESS_ONLY.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/PROGRESS_ONLY.EXE -> ::PROGRESS.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/LIST_ONLY.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/LIST_ONLY.EXE -> ::LIST.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/MSGBOX.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/MSGBOX.EXE -> ::MSGBOX.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/TEXTVIEW.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/TEXTVIEW.EXE -> ::TEXTVIEW.EXE"
fi
if [ "$include_default_examples" -eq 1 ] && [ -f "$repo_root/build/examples/CTXMENU.EXE" ]; then
  echo "Copied file: $repo_root/build/examples/CTXMENU.EXE -> ::CTXMENU.EXE"
fi
