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
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_GROUP_Y)
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_GROUP_X)
        ld      e, a
        ld      h, (iy + UI_GROUP_H)
        ld      l, (iy + UI_GROUP_W)
        ld      a, (ui_theme_window)
        ld      b, a
        jp      ui_draw_box_single

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
        ld      a, (ui_theme_window)
        call    ui_print_z
        ret
