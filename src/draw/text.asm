; Text-mode drawing helpers.

; ui_clear_screen
; In:  A=fill char, B=attribute
; Out: none
; Clobbers: AF, BC, DE, HL
ui_clear_screen:
        ld      (ui_fill_char), a
        ld      a, b
        ld      (ui_fill_attr), a
        ld      d, 0
        ld      e, 0
        ld      a, UI_SCREEN_ROWS
        ld      (ui_clear_rows), a
.row:
        push    de
        ld      c, Bios.Lp_Set_Place
        rst     08h
        ld      a, (ui_fill_attr)
        ld      e, a
        ld      a, (ui_fill_char)
        ld      b, UI_SCREEN_COLS
        ld      c, Bios.Lp_Print_All
        rst     08h
        pop     de
        inc     d
        ld      a, (ui_clear_rows)
        dec     a
        ld      (ui_clear_rows), a
        jr      nz, .row
        ret

; ui_put_cell
; In:  A=char, B=attribute, D=row, E=column
; Out: none
; Clobbers: AF, BC, HL
ui_put_cell:
        ld      (ui_put_char), a
        ld      a, b
        ld      (ui_put_attr), a
        ld      c, Bios.Lp_Set_Place
        rst     08h
        ld      a, (ui_put_attr)
        ld      e, a
        ld      a, (ui_put_char)
        ld      b, 1
        ld      c, Bios.Lp_Print_All
        rst     08h
        ret

; ui_print_z
; In:  HL=ASCIIZ text, A=attribute, D=row, E=column
; Out: none
; Clobbers: AF, BC, DE, HL
ui_print_z:
        ld      (ui_print_attr), a
.loop:
        ld      a, (hl)
        or      a
        ret     z
        push    hl
        push    de
        ld      (ui_print_char), a
        ld      a, (ui_print_attr)
        ld      b, a
        ld      a, (ui_print_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop

ui_print_attr:
        db      0
ui_print_char:
        db      0

; ui_fill_rect
; In:  A=char, B=attribute, D=row, E=column, H=height, L=width
; Out: none
; Clobbers: AF, BC, DE, HL
ui_fill_rect:
        ld      (ui_fill_char), a
        ld      a, b
        ld      (ui_fill_attr), a
        ld      a, e
        ld      (ui_fill_x), a
        ld      a, l
        ld      (ui_fill_w), a
        or      a
        ret     z
        ld      a, h
        ld      (ui_fill_h), a
        or      a
        ret     z
.row:
        push    de
        ld      c, Bios.Lp_Set_Place
        rst     08h
        ld      a, (ui_fill_attr)
        ld      e, a
        ld      a, (ui_fill_char)
        push    af
        ld      a, (ui_fill_w)
        ld      b, a
        pop     af
        ld      c, Bios.Lp_Print_All
        rst     08h
        pop     de
        inc     d
        ld      a, (ui_fill_x)
        ld      e, a
        ld      a, (ui_fill_h)
        dec     a
        ld      (ui_fill_h), a
        jr      nz, .row
        ret

ui_fill_char:
        db      0
ui_fill_attr:
        db      0
ui_fill_x:
        db      0
ui_fill_w:
        db      0
ui_fill_h:
        db      0
ui_clear_rows:
        db      0
ui_put_char:
        db      0
ui_put_attr:
        db      0
