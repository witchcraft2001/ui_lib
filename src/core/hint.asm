; Context hint/status line helpers.

ui_hint_text_ptr:
        dw      0
ui_hint_attr:
        db      0
ui_hint_cols_left:
        db      0

; ui_clear_context_hint
; In:  none
; Out: none
; Clobbers: AF, BC, DE, HL
ui_clear_context_hint:
        ld      a, " "
        push    af
        ld      a, (ui_theme_hint)
        ld      b, a
        pop     af
        ld      d, UI_HINT_LINE_ROW
        ld      e, 0
        ld      h, 1
        ld      l, UI_SCREEN_COLS
        jp      ui_fill_rect

; ui_set_context_hint
; In:  HL=ASCIIZ hint text, or 0 to clear
; Out: none
; Clobbers: AF, BC, DE, HL
ui_set_context_hint:
        ld      (ui_hint_text_ptr), hl
        call    ui_clear_context_hint
        ld      hl, (ui_hint_text_ptr)
        ld      a, h
        or      l
        ret     z
        ld      a, (ui_theme_hint)
        ld      (ui_hint_attr), a
        ld      a, UI_SCREEN_COLS - 2
        ld      (ui_hint_cols_left), a
        ld      d, UI_HINT_LINE_ROW
        ld      e, 1
.loop:
        ld      a, (ui_hint_cols_left)
        or      a
        ret     z
        ld      a, (hl)
        or      a
        ret     z
        push    hl
        push    de
        ld      a, (ui_hint_attr)
        ld      b, a
        ld      a, (hl)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        ld      a, (ui_hint_cols_left)
        dec     a
        ld      (ui_hint_cols_left), a
        jr      .loop
