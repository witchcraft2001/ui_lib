# Widgets

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

`TextField` stores editable text in an application-owned ASCIIZ buffer. Keep the descriptor and buffer in RAM. `UI_FLAG_PASSWORD` masks displayed characters with `*`. The focused field blinks the cursor cell while preserving the character under it.

```asm
text_example:
        db      5, 6, 12, UI_FLAG_PASSWORD, "n"
        dw      text_buffer
        db      12, 0
text_buffer:
        db      "demo", 0
        ds      9, 0

        ld      ix, window_desc
        ld      iy, text_example
        call    ui_draw_text_field
```

Format: `x, y, width, flags, hotkey, buffer_ptr, max_len, cursor`.

## Dialog Navigation

`ui_dialog_run` supports focus for `TextField`, `CheckBox`, `RadioButton`, and `Button`. Traversal order is text field table, checkbox table, radio table, then button table.

- `Tab` moves focus forward.
- `Shift+Tab` or `Alt+Tab` moves focus backward.
- Printable keys edit the focused text field. `Backspace` deletes before cursor, `Delete` deletes under cursor, and `Left`/`Right`/`Home`/`End` move the cursor.
- `Space` edits a focused text field or activates other focused controls. `Enter` activates the focused control.
- The descriptor hotkey activates a control directly.
- Mouse click focuses and activates the control under the pointer.

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
```

Tables end with `UI_*_END`. Use `0` for an absent table.

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
