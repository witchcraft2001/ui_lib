; Runtime theme storage and helpers.

; ui_apply_default_theme
; In:  none
; Out: none
; Clobbers: AF, BC, DE, HL
ui_apply_default_theme:
        ld      hl, ui_default_theme

; ui_set_theme
; In:  HL=theme table, UI_THEME_SIZE bytes
; Out: none
; Clobbers: AF, B, DE, HL
ui_set_theme:
        ld      de, ui_theme
        ld      b, UI_THEME_SIZE
.loop:
        ld      a, (hl)
        ld      (de), a
        inc     hl
        inc     de
        djnz    .loop
        ret

ui_default_theme:
        db      UI_COLOR_DESKTOP
        db      UI_COLOR_WINDOW
        db      UI_COLOR_WINDOW_TITLE
        db      UI_COLOR_HOTKEY
        db      UI_COLOR_BUTTON
        db      UI_COLOR_BUTTON_FOCUS
        db      UI_COLOR_DISABLED
        db      UI_COLOR_SHADOW
        db      UI_COLOR_HINT
        db      UI_COLOR_BUTTON_SHADOW

ui_theme:
ui_theme_desktop:
        db      UI_COLOR_DESKTOP
ui_theme_window:
        db      UI_COLOR_WINDOW
ui_theme_window_title:
        db      UI_COLOR_WINDOW_TITLE
ui_theme_hotkey:
        db      UI_COLOR_HOTKEY
ui_theme_button:
        db      UI_COLOR_BUTTON
ui_theme_button_focus:
        db      UI_COLOR_BUTTON_FOCUS
ui_theme_disabled:
        db      UI_COLOR_DISABLED
ui_theme_shadow:
        db      UI_COLOR_SHADOW
ui_theme_hint:
        db      UI_COLOR_HINT
ui_theme_button_shadow:
        db      UI_COLOR_BUTTON_SHADOW
