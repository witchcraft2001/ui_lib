; Horizontal separator drawing.

; ui_draw_separator
; In:  IX=parent window descriptor, IY=separator descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_separator:
        ld      a, (iy + UI_SEPARATOR_W)
        or      a
        jr      z, ui_draw_full_width_separator
        ld      l, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_SEPARATOR_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SEPARATOR_Y)
        ld      d, a
        ld      h, 1
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        jp      ui_fill_rect

; Draw a separator connected to the parent window frame.
; UI_SEPARATOR_W=0 means: ignore UI_SEPARATOR_X and span from the left border
; to the right border. This matches the common BP/TASM dialog separator style.
ui_draw_full_width_separator:
        ld      a, (ix + UI_WINDOW_W)
        cp      3
        ret     c
        sub     2
        ld      (ui_sep_mid_w), a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SEPARATOR_Y)
        ld      d, a
        ld      e, (ix + UI_WINDOW_X)

        ; left junction
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C7h
        call    ui_put_cell

        ; middle as one horizontal run
        inc     e
        ld      a, (ui_sep_mid_w)
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C4h
        call    ui_fill_rect

        ; right junction
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SEPARATOR_Y)
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        inc     a
        ld      hl, ui_sep_mid_w
        add     a, (hl)
        ld      e, a
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0B6h
        call    ui_put_cell
        ret

ui_sep_mid_w:
        db      0
