# Repository Guidelines

## Project Structure & Module Organization

This repository contains a compact Z80 ASM UI library for Sprinter Peters Plus text mode `80x32`. The library must remain modular: applications include only the widgets they need.

- `include/` - public API and local platform constants. Always include copied files from `include/platform/`, never absolute paths to external manuals.
- `src/core/` - init/shutdown, theme, events, mouse/keyboard integration.
- `src/draw/` - text-mode char/attribute drawing primitives.
- `src/widgets/` - independent widget modules: window, dialog, button, checkbox, radio button, group box, separator.
- `examples/demo/ui_demo.asm` - current integration demo.
- `docs/ru/`, `docs/en/` - bilingual API and widget docs.
- `run/` - build and FAT12 image scripts.
- `references/` - visual references from TASM/fformat-style UIs.

Reference sources: `sprinter_ai_doc/manual` is the primary DSS/BIOS source; `sprinter_dss` and `sprinter_bios` are secondary verification sources. UI behavior should be compared with TASM, fformat, fm, and texteditor.

## Build, Test, and Development Commands

- `run/make.sh` - builds `build/demo/UI_DEMO.EXE` with `sjasmplus --syntax=f` and writes `build/demo/UI_DEMO.LST`.
- `run/create_floppy_image.sh` - creates `build/demo/ui_demo.img` and copies `UI_DEMO.EXE` into it.
- `mdir -i build/demo/ui_demo.img ::` - verifies image contents.
- `git diff --check` - catches whitespace/patch issues.

After every code iteration, build the demo and regenerate the disk image.

## Coding Style & Naming Conventions

Use English comments in ASM. Keep labels lowercase with `ui_` prefixes for public routines, for example `ui_init`, `ui_draw_button`, `ui_dialog_run`. File names use lowercase snake case, e.g. `radio_button.asm`.

Every routine should document inputs, outputs, and clobbered registers. Preserve `IX/IY` around BIOS/DSS calls when descriptors are live. Descriptors use relative coordinates inside a parent window and must remain relocatable; do not require fixed code addresses.

## UI Style Guide

The accepted visual direction is Borland Pascal/TASM-like text UI:

- gray dialog/window body, white double outer frame, black inner group frames and separators;
- black labels on gray, yellow hotkey letters;
- green buttons, yellow hotkey letters, black text for inactive buttons, white text when focused if theme enables it;
- black window shadows; button shadow should follow the fformat style, not a tall block;
- pressed buttons shift one text cell right and hide their button shadow until release;
- support `Tab`, `Shift+Tab`/`Alt+Tab`, `Space`, `Enter`, hotkeys, mouse focus and activation.

Theme colors are runtime-configurable through `ui_set_theme` and the `UI_THEME_*` layout in `include/ui.inc`.

## Testing Guidelines

Demo behavior must cover keyboard navigation, mouse activation, hotkeys, focus changes, checked/unchecked states, disabled states, button pressed feedback, and shadow rendering. Prefer screenshots or emulator notes for visible UI changes.

## Documentation Guidelines

Keep Russian and English docs in sync. Document descriptor formats, module dependencies, init/shutdown, memory assumptions, optional DSS-backed window buffer behavior, theme layout, and example usage.

## Agent-Specific Instructions

Do not revert user changes. Do not introduce absolute include paths. Keep modules separable and avoid pulling unrelated widgets into single-widget consumers. When fixing UI behavior, inspect TASM/fformat/fm implementations before inventing a new pattern.
