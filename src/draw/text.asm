; Text-mode drawing helpers.

        IFNDEF UI_SAFE_STACK
UI_SAFE_STACK equ 8040h
        ENDIF

; ui_clear_screen
; In:  A=fill char, B=attribute
; Out: none
; Clobbers: AF, BC, DE, HL
ui_clear_screen:
        push    ix
        push    iy
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
        call    ui_call_bios
        ld      a, (ui_fill_attr)
        ld      e, a
        ld      a, (ui_fill_char)
        ld      b, UI_SCREEN_COLS
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     de
        inc     d
        ld      a, (ui_clear_rows)
        dec     a
        ld      (ui_clear_rows), a
        jr      nz, .row
        pop     iy
        pop     ix
        ret

; ui_put_cell
; In:  A=char, B=attribute, D=row, E=column
; Out: none
; Clobbers: AF, BC, HL
ui_put_cell:
        push    de
        push    ix
        push    iy
        ld      (ui_put_char), a
        ld      a, b
        ld      (ui_put_attr), a
        ld      c, Bios.Lp_Set_Place
        call    ui_call_bios
        ld      a, (ui_put_attr)
        ld      e, a
        ld      a, (ui_put_char)
        ld      b, 1
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     iy
        pop     ix
        pop     de
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
        push    ix
        push    iy
        ld      (ui_fill_char), a
        ld      a, b
        ld      (ui_fill_attr), a
        ld      a, e
        ld      (ui_fill_x), a
        ld      a, l
        ld      (ui_fill_w), a
        or      a
        jr      z, .done
        ld      a, h
        ld      (ui_fill_h), a
        or      a
        jr      z, .done
.row:
        push    de
        ld      c, Bios.Lp_Set_Place
        call    ui_call_bios
        ld      a, (ui_fill_attr)
        ld      e, a
        ld      a, (ui_fill_char)
        push    af
        ld      a, (ui_fill_w)
        ld      b, a
        pop     af
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     de
        inc     d
        ld      a, (ui_fill_x)
        ld      e, a
        ld      a, (ui_fill_h)
        dec     a
        ld      (ui_fill_h), a
        jr      nz, .row
.done:
        pop     iy
        pop     ix
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

; ui_call_bios
; Calls Sprinter BIOS with P2 mapped to P1 and a temporary stack.
; This follows the pattern used by texteditor/fformat-style UI code to
; avoid video memory corruption during low-level BIOS text output.
; In:  C=function, other registers as required by BIOS
; Out: BIOS result
ui_call_bios:
        ld      (.a_value), a
        in      a, (EmmWin.P2)
        ld      (.page), a
        in      a, (EmmWin.P1)
        out     (EmmWin.P2), a
        ld      (.sp_save), sp
        ld      sp, UI_SAFE_STACK
        ld      a, 0
.a_value equ $-1
        rst     08h
        ld      sp, 0
.sp_save equ $-2
        push    af
        ld      a, 0
.page   equ $-1
        out     (EmmWin.P2), a
        pop     af
        ret
