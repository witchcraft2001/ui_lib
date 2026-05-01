# Theme

The library stores the active palette in the runtime `ui_theme` table. `ui_init` loads the default theme automatically, and applications can replace it with `ui_set_theme`.

Include order:

```asm
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
```

Example:

```asm
my_theme:
        db      17h     ; desktop
        db      1Fh     ; window
        db      1Eh     ; window title
        db      1Ch     ; hotkey
        db      70h     ; button
        db      4Fh     ; focused button
        db      18h     ; disabled
        db      08h     ; window shadow
        db      1Eh     ; hint/status line
        db      10h     ; button shadow
        db      2Eh     ; button hotkey
        db      2Eh     ; focused button hotkey
        db      17h     ; text field, TASM-like blue input
        db      1Fh     ; focused text field
        db      2Fh     ; focused horizontal menu item
        db      0Fh     ; focused dropdown menu item
        db      78h     ; disabled menu item

        ld      hl, my_theme
        call    ui_set_theme
```

The table has `UI_THEME_SIZE` bytes. Fields are also available through `UI_THEME_*` offsets and active variables such as `ui_theme_desktop`, `ui_theme_window`, `ui_theme_button`, `ui_theme_button_focus`, `ui_theme_menu_bar_focus`, `ui_theme_menu_popup_focus`, `ui_theme_menu_disabled`, and others.
