# Widgets

## Minimal Linking

Applications include only the `.asm` modules they use. `examples/button_only/button_only.asm` builds a window with one button without linking `Dialog`, `MenuBar`, `TextField`, `CheckBox`, `RadioButton`, `ItemSelector`, or `ComboBox`. `examples/menu_only/menu_only.asm` builds a top menu with dropdowns, hints, disabled items, and hotkeys without linking `Dialog` or other widgets.

```asm
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"
        include "src/widgets/button_events.asm"
```

Build the example:

```sh
run/make.sh
run/create_floppy_image.sh
```

The default `build/demo/ui_demo.img` image contains `UI_DEMO.EXE`, `BUTTON.EXE`, and `MENU.EXE`. To create a separate button-only image, run `run/create_floppy_image.sh build/examples/BUTTON_ONLY.EXE build/examples/button_only.img BUTTON.EXE`; for menu-only, run `run/create_floppy_image.sh build/examples/MENU_ONLY.EXE build/examples/menu_only.img MENU.EXE`.

This keeps placement policy in the target program: inline the widget code, build a library block at a chosen address, or call it from a separate memory page.

For simple text without a widget, use `ui_print_wrapped_z`: `HL` is ASCIIZ text, `A` is the attribute, `D/E` is row/column, `B` is width, and `C` is max rows. Byte `0Ah` inside the string forces a new line. To invert an already drawn one-line region without reprinting text, call `ui_invert_range` with `D/E` as row/column and `B` as width.

## Window

`ui_draw_window` draws a static window: black shadow, gray body fill, the outer frame, and an optional title. `IX` points to the window descriptor:

- `+0` x, `+1` y, `+2` width, `+3` height in cells (`UI_WINDOW_X/Y/W/H`);
- `+4` word title (`UI_WINDOW_TITLE`): pointer to the ASCIIZ title, or `0` for no title;
- `+6` frame style (`UI_WINDOW_FRAME`): `UI_FRAME_DOUBLE` (`0`, double-line frame) or `UI_FRAME_SINGLE` (`1`, single-line frame).

`UI_WINDOW_SIZE` is the descriptor length (7 bytes). The frame byte is mandatory: `ui_draw_window` and `ui_draw_window_frame` always read `+6`, so every descriptor must include it. `UI_FRAME_DOUBLE` is the default double outer frame from the style guide.

```asm
        ld      ix, window_desc
        call    ui_draw_window
; ...
window_desc:
        db      15, 4, 50, 20
        dw      window_title
        db      UI_FRAME_DOUBLE
```

`ui_draw_window_shadow` and `ui_draw_window_frame` are also callable on their own; `ui_draw_window_frame` selects the glyph set from the descriptor's frame style.

## MenuBar

`MenuBar` draws the top menu row and dropdown windows from descriptor tables. Coordinates are explicit, so the module does not require a fixed address and can be used separately from `Dialog`. `ui_menu_bar_run` keeps focus on the top row, `Left`/`Right` move across menu items, `Enter`, `F10`, or mouse click opens the dropdown, `F10` closes an open dropdown, `Up`/`Down` moves inside an open dropdown, and `Esc` closes the dropdown or exits the menu. Menu item shortcuts are searched across all dropdown tables, so `Alt+X` or a shortcut from another opened menu works as an accelerator.

```asm
menu_bar:
        db      0, 0, 80
        dw      menu_items

menu_items:
        db      1, 0, "f", UI_HOTKEY_MOD_NONE
        dw      file_label
        dw      file_popup
        db      14                  ; popup width
        dw      file_hint
        db      UI_MENU_ITEMS_END

file_popup:
        db      0, "x", UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_CANCEL
        dw      exit_label
        dw      exit_hint
        db      0, UI_SCAN_F3, UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_NONE
        dw      diagnostics_label
        dw      diagnostics_hint
        db      UI_MENU_POPUP_END
```

`MenuBar` layout: `x, y, width, menu_items_ptr`.

`MenuBar item` layout: `x, flags, hotkey, hotkey_mods, label_ptr, popup_ptr, popup_width, hint_ptr`.

- `x` is the item column relative to the menu bar origin.
- `flags`: `UI_FLAG_DISABLED` prevents selection.
- `hotkey` is an ASCII shortcut key or scan code.
- `hotkey_mods` uses `UI_HOTKEY_MOD_NONE`, `UI_HOTKEY_MOD_ALT`, `UI_HOTKEY_USE_SCAN`, and `UI_HOTKEY_NO_MNEMONIC`.
- `label_ptr` is an ASCIIZ label; `&` explicitly marks the highlighted hot character. Without `&`, the renderer highlights the first character matching `hotkey`.
- `popup_ptr` points to dropdown items, or `0` when no popup is attached.
- `popup_width` is the dropdown width including the frame.
- `hint_ptr` points to the status-line hint, or `0`.

`Popup item` layout: `flags, hotkey, hotkey_mods, command, label_ptr, hint_ptr`.

- `flags`: `UI_FLAG_SEPARATOR` draws a separator, `UI_FLAG_DISABLED` disables the row.
- `hotkey` is the ASCII key or scan code used while the dropdown is open.
- `hotkey_mods` contains shortcut modifiers/flags. For `Alt+X`, use `hotkey="x"` and `hotkey_mods=UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC`. For `F3`, use `hotkey=UI_SCAN_F3` and `hotkey_mods=UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC`. `UI_SCAN_F*` uses DSS/TASM-style scan codes (`F3 = #3D`), not raw AT scancodes.
- `command` is the byte returned by `ui_menu_bar_run`.
- `label_ptr` is an ASCIIZ label with an optional `&` marker for the visible mnemonic. For shortcuts without highlighted letters (`F3`, `Alt+X`), omit `&` and set `UI_HOTKEY_NO_MNEMONIC`.
- `hint_ptr` points to the status-line hint.

Horizontal and vertical focus colors are separate theme fields: `UI_THEME_MENU_BAR_FOCUS` and `UI_THEME_MENU_POPUP_FOCUS`. Disabled menu rows use `UI_THEME_MENU_DISABLED`.

## GroupBox

`GroupBox` draws a framed area inside a parent window. Coordinates are relative to `UI_WINDOW_X/Y`.

```asm
group_example:
        db      3, 3, 21, 5
        dw      group_title
group_title:
        db      " Options ", 0

        ld      ix, window_desc
        ld      iy, group_example
        call    ui_draw_group_box
```

Format: `x, y, width, height, title_ptr`. Minimum size: `2x2`.

## Separator

`Separator` draws a horizontal line inside a window. Use it to split blocks in dialogs and dropdown menus.

```asm
separator_example:
        db      3, 9, 44

        ld      ix, window_desc
        ld      iy, separator_example
        call    ui_draw_separator
```

Format: `x, y, width`.

Set `width` to `0` for a full-width separator connected to the parent window frame.
In that mode `x` is ignored and `y` is still relative to the parent window.

## CheckBox

`CheckBox` stores its state in `flags`: `UI_FLAG_CHECKED` marks the checked state. Keep the descriptor in RAM if the application calls `ui_toggle_checkbox`.

```asm
check_example:
        db      5, 5, UI_FLAG_CHECKED, "p"
        dw      check_label
check_label:
        db      "&Password mask", 0

        ld      ix, window_desc
        ld      iy, check_example
        call    ui_draw_checkbox
```

Format: `x, y, flags, hotkey, label_ptr`.

## TextField

`TextField` stores editable text in an application-owned ASCIIZ buffer. Keep the descriptor and buffer in RAM. `UI_FLAG_PASSWORD` masks displayed characters with `*`. The focused field blinks the cursor cell while preserving the character under it. `width` is the visible size; `max_len` may be larger, and the field scrolls horizontally to keep the cursor visible.

```asm
text_example:
        db      5, 6, 12, UI_FLAG_PASSWORD, "n"
        dw      text_buffer
        db      24, 0, 0            ; max_len, cursor, scroll
text_buffer:
        db      "demo", 0
        ds      21, 0

        ld      ix, window_desc
        ld      iy, text_example
        call    ui_draw_text_field
```

Format: `x, y, width, flags, hotkey, buffer_ptr, max_len, cursor, scroll`.

## ItemSelector

`ItemSelector` stores the selected index in the descriptor and displays a string from an ASCIIZ pointer table. It is a compact selector without a dropdown popup and is drawn with `<` and `>` side markers. `Space`, `Enter`, hotkey, or mouse click cycles to the next item, `Left` moves backward, and `Right` moves forward.

```asm
item_selector_example:
        db      5, 11, 16, 0, "t"
        dw      item_selector_items
        db      3, 0                 ; count, selected index

item_selector_items:
        dw      item_tasm
        dw      item_fformat
        dw      item_blue
```

Format: `x, y, width, flags, hotkey, items_ptr, count, selected`.

## ComboBox

`ComboBox` uses the same string table shape, but opens a dropdown list with its own frame and background. `Space`, `Enter`, hotkey, or mouse click opens the popup. The right dropdown button uses 3 cells inside the total widget width and is drawn as `[↓]`, so the text area is `width - 3`. Inside the popup, `Up`/`Down`/`Home`/`End` move selection, `Enter` or click commits, and `Esc` or an outside click cancels. When item count exceeds popup height, the right column shows a scrollbar with up/down buttons, patterned track, and a thumb; clicking the buttons scrolls one item.

```asm
combo_example:
        db      26, 11, 16, 0, "d"
        dw      combo_items
        db      3, 0, 3              ; count, selected index, popup height

combo_items:
        dw      item_drive_a
        dw      item_drive_b
        dw      item_ram
```

Format: `x, y, width, flags, hotkey, items_ptr, count, selected, popup_height`.

## ProgressBar

`ProgressBar` is draw-only and can be linked without dialog/menu modules.
The empty part is drawn with a patterned pseudographic cell, and the filled
part uses `ui_theme_progress_fill`.
Determinate mode uses `value/max`; indeterminate mode uses `UI_FLAG_INDETERMINATE`
and stores the animation phase in the descriptor.

```asm
progress_done:
        db      8, 7, 28, 0, 0, 10, 0
progress_busy:
        db      8, 9, 28, UI_FLAG_INDETERMINATE, 0, 0, 0

        ld      ix, window_desc
        ld      iy, progress_done
        call    ui_draw_progress_bar

        ld      iy, progress_busy
        call    ui_progress_bar_tick
        call    ui_draw_progress_bar
```

Format: `x, y, width, flags, value, max, phase`.

## Window Background Save/Restore

By default, windows do not save anything: the application repaints the background after closing. If the build defines `DEFINE UI_USE_DSS_WINDOW_BUFFER 1`, `ui_init` allocates one DSS page and `ui_shutdown` frees it. `ui_dialog_run` automatically saves the dialog area including its shadow before drawing and restores it on exit.

For direct window use, call `ui_window_save_under` and `ui_window_restore_under`. `IX` must point to the window descriptor when saving; restore is LIFO, so the last saved window must be closed first. By default, the stack stores up to `UI_WINDOW_SAVE_DEPTH=4` areas in one DSS page; override the depth before including `window.asm`. If the total saved area exceeds 16 KB, `ui_window_save_under` returns `CF=1`, and the application must repaint the background itself.

## Dialog Navigation

`ui_dialog_run` supports focus for `TextField`, `CheckBox`, `RadioButton`, `ItemSelector`, `ComboBox`, and `Button`. Traversal order is text field table, checkbox table, radio table, item selector table, combo box table, then button table.

- `Tab` moves focus forward.
- `Shift+Tab` or `Alt+Tab` moves focus backward.
- Printable keys edit the focused text field. `Backspace` deletes before cursor, `Delete` deletes under cursor, and `Left`/`Right`/`Home`/`End` move the cursor.
- `Space` edits a focused text field or activates other focused controls. `Enter` activates the focused control. For `ItemSelector`, activation selects the next item; for `ComboBox`, it opens the popup.
- The descriptor hotkey activates a control directly.
- Mouse click focuses and activates the control under the pointer. For `TextField`, the click also moves the cursor to the clicked cell, clamped to the current text length.
- If the build defines `DEFINE UI_ENABLE_HINTS 1` and includes `src/core/hint.asm`, the dialog updates the bottom hint line from the current focus index.

Extended dialog descriptor:

```asm
dialog_example:
        dw      window_desc
        dw      buttons_table
        dw      checks_table
        dw      radios_table
        dw      groups_table
        dw      separators_table
        dw      text_fields_table
        dw      item_selectors_table
        dw      combos_table
        dw      hints_table          ; optional when UI_ENABLE_HINTS=1

hints_table:
        dw      text_field_hint
        dw      checkbox_hint
        dw      first_radio_hint
        dw      second_radio_hint
        dw      item_selector_hint
        dw      combo_hint
        dw      ok_button_hint
        dw      cancel_button_hint
```

Tables end with `UI_*_END`. Use `0` for an absent table. The hint table contains word pointers in the same order as focus traversal.

## Status Hint Line

`ui_set_context_hint` prints an ASCIIZ string on the bottom screen row (`row 31`) using `ui_theme_hint`; `ui_clear_context_hint` clears that row. The module depends only on `src/draw/text.asm` and the theme.

```asm
        include "src/core/hint.asm"

        ld      hl, hint_text
        call    ui_set_context_hint
```

## RadioButton

`RadioButton` uses the same `UI_FLAG_CHECKED` bit. The current implementation provides basic drawing and state setting; group management will be added in the dialog/focus layer.

```asm
radio_example:
        db      28, 5, UI_FLAG_CHECKED, "f"
        dw      radio_label
radio_label:
        db      "&Fast mode", 0

        ld      ix, window_desc
        ld      iy, radio_example
        call    ui_draw_radio_button
```

Format: `x, y, flags, hotkey, label_ptr`.
