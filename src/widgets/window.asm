; Window drawing. The first implementation draws a BP7-like text frame.

; ui_draw_window
; In:  IX=window descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_window:
        ld      e, (ix + UI_WINDOW_X)
        ld      d, (ix + UI_WINDOW_Y)
        ld      l, (ix + UI_WINDOW_W)
        ld      h, (ix + UI_WINDOW_H)
        ld      a, " "
        ld      b, UI_COLOR_WINDOW
        call    ui_fill_rect
        call    ui_draw_window_frame
        call    ui_draw_window_title
        ret

ui_draw_window_frame:
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        ld      a, 0C9h
        ld      b, UI_COLOR_WINDOW
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, 0CDh
        ld      b, UI_COLOR_WINDOW
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .top

        inc     e
        ld      a, 0BBh
        ld      b, UI_COLOR_WINDOW
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_H)
        sub     2
        ld      c, a
.sides:
        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, 0BAh
        ld      b, UI_COLOR_WINDOW
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
        ld      a, 0BAh
        ld      b, UI_COLOR_WINDOW
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, 0C8h
        ld      b, UI_COLOR_WINDOW
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, 0CDh
        ld      b, UI_COLOR_WINDOW
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .bottom

        inc     e
        ld      a, 0BCh
        ld      b, UI_COLOR_WINDOW
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
        ld      a, UI_COLOR_WINDOW_TITLE
        call    ui_print_z
        ret
