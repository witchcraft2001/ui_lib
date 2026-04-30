; Horizontal separator drawing.

; ui_draw_separator
; In:  IX=parent window descriptor, IY=separator descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_separator:
        ld      a, (iy + UI_SEPARATOR_W)
        or      a
        ret     z
        ld      c, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_SEPARATOR_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SEPARATOR_Y)
        ld      d, a
.loop:
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     e
        dec     c
        jr      nz, .loop
        ret
