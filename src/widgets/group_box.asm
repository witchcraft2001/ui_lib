; Group box drawing.

; ui_draw_group_box
; In:  IX=parent window descriptor, IY=group box descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_group_box:
        ld      a, (iy + UI_GROUP_W)
        cp      2
        ret     c
        ld      a, (iy + UI_GROUP_H)
        cp      2
        ret     c
        call    ui_draw_group_frame
        call    ui_draw_group_title
        ret

ui_draw_group_frame:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_GROUP_Y)
        ld      d, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0DAh
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (iy + UI_GROUP_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
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
        ld      a, 0BFh
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (iy + UI_GROUP_H)
        sub     2
        ld      c, a
.sides:
        inc     d
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc

        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        ld      e, a
        ld      a, (iy + UI_GROUP_W)
        dec     a
        add     a, e
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        inc     d
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C0h
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (iy + UI_GROUP_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
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
        ld      a, 0D9h
        call    ui_put_cell
        ret

ui_draw_group_title:
        ld      l, (iy + UI_GROUP_TITLE)
        ld      h, (iy + UI_GROUP_TITLE + 1)
        ld      a, h
        or      l
        ret     z
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_GROUP_Y)
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        inc     a
        inc     a
        ld      e, a
        ld      a, (ui_theme_window_title)
        call    ui_print_z
        ret
