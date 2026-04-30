# Repository Guidelines

## Project Structure & Module Organization

This repository is for a compact Z80 ASM UI library for the Sprinter Peters Plus text-mode screen. Consumers must link only required widgets.

- `src/core/` for init/shutdown, input, focus, events, and drawing helpers.
- `src/widgets/` for optional `button`, `checkbox`, `radio_button`, `text_field`, `window`, `dialog`, etc.
- `include/` for public `.inc` files; `examples/` for sjasmplus demos.
- `tools/` or `run/` for build/image scripts; `docs/ru/` and `docs/en/` for documentation.

Use these Sprinter projects as adaptation sources:
`/Users/dmitry/dev/zx/sprinter/sprinter_bios`,
`/Users/dmitry/dev/zx/sprinter/sprinter_dss`,
`/Users/dmitry/dev/zx/sprinter/sprinter_ai_doc/manual`,
`/Users/dmitry/dev/zx/sprinter/sources/tasm_071/TASM`,
`/Users/dmitry/dev/zx/sprinter/sources/fformat/src/fformat_v113`,
`/Users/dmitry/dev/zx/sprinter/sources/fm/FM-SRC/FM`.

## Architecture Requirements

Match or exceed `fformat`/`TASM` UI quality: mouse support, hotkeys, focus traversal, activation shortcuts, pressed/highlighted feedback, and disabled states. Window background save/restore is optional. When enabled, allocate DSS-reserved page memory in init and release it in shutdown. When disabled, callers repaint or restore the screen.

Do not make the full library mandatory. Each widget must keep separable code/data dependencies, so single-widget users do not pull unrelated code or RAM.

## Build, Test, and Development Commands

Use `sjasmplus`. Keep scripts in `run/` or `tools/`, modeled after `/Users/dmitry/dev/zx/sprinter/kode/run/make.sh` and `create_floppy_image.sh`.

Expected workflow after each implementation iteration:

- build library and demo apps with `sjasmplus`;
- generate listings for debugging;
- prepare a bootable/testable disk image with scripts similar to `kode/run`;
- run repository checks such as `git diff --check`.

## Coding Style & Naming Conventions

Write assembly comments in English. Use lowercase names with underscores, for example `radio_button.asm`. Prefix public labels consistently: `ui_init`, `ui_shutdown`, `ui_button_draw`. Keep public API `.inc` files separate from private implementation.

Favor small routines, explicit register contracts, and documented clobbers. Note RAM usage near buffers, tables, and per-widget state.

## Testing Guidelines

Every feature needs a demo under `examples/`. Cover keyboard-only use, mouse use, hotkeys, disabled controls, focus changes, and window close/restore behavior. Include one single-widget demo to verify modular linking and RAM savings.

## Documentation Guidelines

Maintain Russian and English docs. Cover API entry points, init/shutdown calls, memory model, DSS-backed window buffers, widget states, shortcuts, mouse behavior, and examples.

## Commit & Pull Request Guidelines

Use imperative commit subjects such as `Add button widget core`. PRs should describe UI behavior, list build/demo/image commands, and include screenshots or emulator notes for visible changes.

## Agent-Specific Instructions

Before implementing, inspect reference projects. Preserve user changes, avoid unrelated refactors, and do not invent unavailable tools or commands. After code changes, build demos and prepare a disk image when scripts exist.
