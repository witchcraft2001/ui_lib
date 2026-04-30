; Text-mode drawing helpers.

; ui_clear_screen
; In:  A=fill char, B=attribute
; Out: none
; Clobbers: C, DE, HL
ui_clear_screen:
        ld      de, 0000h
        ld      hl, UI_SCREEN_ROWS * 256 + UI_SCREEN_COLS
        ld      c, DSS_CLEAR
        rst     10h
        ret

; ui_put_cell
; In:  A=char, B=attribute, D=row, E=column
; Out: none
; Clobbers: C
ui_put_cell:
        ld      c, DSS_WRCHAR
        rst     10h
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
        ld      a, (ui_print_attr)
        ld      b, a
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop

ui_print_attr:
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
        ld      a, h
        or      a
        ret     z
.row:
        push    hl
        push    de
        ld      a, l
        or      a
        jr      z, .row_done
        ld      c, a
.col:
        ld      a, (ui_fill_char)
        push    af
        ld      a, (ui_fill_attr)
        ld      b, a
        pop     af
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     e
        dec     c
        jr      nz, .col
.row_done:
        pop     de
        pop     hl
        inc     d
        ld      a, (ui_fill_x)
        ld      e, a
        dec     h
        jr      nz, .row
        ret

ui_fill_char:
        db      0
ui_fill_attr:
        db      0
ui_fill_x:
        db      0
