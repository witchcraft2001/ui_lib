; TextField drawing and simple line editing helpers.

ui_text_field_attr:
        ld      a, (iy + UI_TEXT_FLAGS)
        bit     7, a
        jr      nz, .disabled
        bit     6, a
        jr      nz, .focused
        ld      a, (ui_theme_text_field)
        ret
.focused:
        ld      a, (ui_theme_text_field_focus)
        ret
.disabled:
        ld      a, (ui_theme_disabled)
        ret

; ui_draw_text_field
; In:  IX=parent window descriptor, IY=text field descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_text_field:
        call    ui_text_field_attr
        ld      (ui_text_field_attr_value), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_TEXT_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_TEXT_Y)
        ld      d, a
        ld      h, 1
        ld      l, (iy + UI_TEXT_W)
        ld      a, " "
        push    af
        ld      a, (ui_text_field_attr_value)
        ld      b, a
        pop     af
        push    de
        call    ui_fill_rect
        pop     de

        ld      a, (iy + UI_TEXT_W)
        ld      c, a
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
.print_loop:
        ld      a, c
        or      a
        jr      z, .cursor
        ld      a, (hl)
        or      a
        jr      z, .cursor
        bit     1, (iy + UI_TEXT_FLAGS)
        jr      z, .have_char
        ld      a, "*"
.have_char:
        push    hl
        push    bc
        push    de
        ld      (ui_text_field_char), a
        ld      a, (ui_text_field_attr_value)
        ld      b, a
        ld      a, (ui_text_field_char)
        call    ui_put_cell
        pop     de
        pop     bc
        pop     hl
        inc     hl
        inc     e
        dec     c
        jr      .print_loop
.cursor:
        ld      a, (iy + UI_TEXT_FLAGS)
        bit     6, a
        ret     z
        ld      a, c
        or      a
        ret     z
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, "_"
        call    ui_put_cell
        ret

; ui_text_field_insert_char
; Appends printable A to the editable buffer if there is room.
; In:  A=ASCII, IY=text field descriptor
; Out: CF=1 if handled, CF=0 if there was no room
; Clobbers: AF, BC, DE, HL
ui_text_field_insert_char:
        ld      (ui_text_field_char), a
        call    ui_text_field_len
        ld      b, a
        ld      a, (iy + UI_TEXT_MAXLEN)
        cp      b
        jr      z, .full
        jr      c, .full
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      e, b
        ld      d, 0
        add     hl, de
        ld      a, (ui_text_field_char)
        ld      (hl), a
        inc     hl
        ld      (hl), 0
        inc     b
        ld      a, b
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret
.full:
        or      a
        ret

; ui_text_field_backspace
; Deletes the last character.
; In:  IY=text field descriptor
; Out: CF=1 if handled, CF=0 if buffer was empty
; Clobbers: AF, BC, DE, HL
ui_text_field_backspace:
        call    ui_text_field_len
        or      a
        ret     z
        dec     a
        ld      (iy + UI_TEXT_CURSOR), a
        ld      e, a
        ld      d, 0
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        add     hl, de
        ld      (hl), 0
        scf
        ret

; ui_text_field_len
; In:  IY=text field descriptor
; Out: A=length capped at UI_TEXT_MAXLEN
; Clobbers: AF, BC, HL
ui_text_field_len:
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      b, 0
.loop:
        ld      a, b
        cp      (iy + UI_TEXT_MAXLEN)
        jr      z, .done
        ld      a, (hl)
        or      a
        jr      z, .done
        inc     b
        inc     hl
        jr      .loop
.done:
        ld      a, b
        ret

ui_text_field_attr_value:
        db      0
ui_text_field_char:
        db      0
