; Window drawing. The first implementation draws a BP7-like text frame.

; ui_draw_window
; In:  IX=window descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_window:
        call    ui_draw_window_shadow
        ld      e, (ix + UI_WINDOW_X)
        ld      d, (ix + UI_WINDOW_Y)
        ld      l, (ix + UI_WINDOW_W)
        ld      h, (ix + UI_WINDOW_H)
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        call    ui_draw_window_frame
        call    ui_draw_window_title
        ret

ui_draw_window_shadow:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (ix + UI_WINDOW_W)
        cp      UI_SCREEN_COLS
        jr      nc, .bottom
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        inc     a
        cp      UI_SCREEN_ROWS
        jr      nc, .bottom
        ld      d, a
        ld      h, (ix + UI_WINDOW_H)
        ld      l, 2
        ld      a, " "
        push    af
        ld      a, (ui_theme_shadow)
        ld      b, a
        pop     af
        call    ui_fill_rect
.bottom:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (ix + UI_WINDOW_H)
        cp      UI_SCREEN_ROWS
        ret     nc
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        inc     a
        inc     a
        cp      UI_SCREEN_COLS
        ret     nc
        ld      e, a
        ld      h, 1
        ld      l, (ix + UI_WINDOW_W)
        ld      a, " "
        push    af
        ld      a, (ui_theme_shadow)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ret

ui_draw_window_frame:
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C9h
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0CDh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .top

        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BBh
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_H)
        sub     2
        ld      c, a
.sides:
        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BAh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ix + UI_WINDOW_W)
        dec     a
        add     a, e
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BAh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C8h
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0CDh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .bottom

        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BCh
        call    ui_put_cell
        ret

ui_draw_window_title:
        ld      l, (ix + UI_WINDOW_TITLE)
        ld      h, (ix + UI_WINDOW_TITLE + 1)
        ld      a, h
        or      l
        ret     z
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        inc     e
        inc     e
        ld      a, (ui_theme_window_title)
        call    ui_print_z
        ret
