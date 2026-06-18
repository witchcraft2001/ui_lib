; Horizontal separator drawing.

; ui_draw_separator
; In:  IX=parent window descriptor, IY=separator descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_separator:
        ld      a, (iy + UI_SEPARATOR_W)
        or      a
        jr      z, ui_draw_full_width_separator
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

; Draw a separator connected to the parent window frame.
; UI_SEPARATOR_W=0 means: ignore UI_SEPARATOR_X and span from the left border
; to the right border. This matches the common BP/TASM dialog separator style.
ui_draw_full_width_separator:
        ld      a, (ix + UI_WINDOW_W)
        cp      3
        ret     c
        ld      c, a
        ld      a, (ix + UI_WINDOW_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SEPARATOR_Y)
        ld      d, a

        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C7h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc

        ld      a, c
        sub     2
        ld      c, a
.middle:
        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C4h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .middle

        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0B6h
        call    ui_put_cell
        ret
