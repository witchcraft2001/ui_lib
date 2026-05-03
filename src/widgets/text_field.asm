; TextField drawing and single-line editing helpers.

ui_text_cursor_visible:
        db      1

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
        call    ui_text_field_clamp_cursor
        call    ui_text_field_update_scroll
        call    ui_text_field_attr
        ld      (ui_text_field_attr_value), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_TEXT_X)
        ld      (ui_text_field_base_x), a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_TEXT_Y)
        ld      (ui_text_field_base_y), a
        xor     a
        ld      (ui_text_field_pos), a
.loop:
        ld      a, (ui_text_field_pos)
        cp      (iy + UI_TEXT_W)
        ret     nc
        call    ui_text_field_char_at_pos
        ld      (ui_text_field_char), a
        ld      a, (iy + UI_TEXT_FLAGS)
        bit     6, a
        jr      z, .put
        ld      a, (ui_text_cursor_visible)
        or      a
        jr      z, .put
        ld      a, (ui_text_field_pos)
        ld      b, a
        ld      a, (ui_text_field_cursor_screen)
        cp      b
        jr      nz, .put
        ld      a, (ui_theme_window_title)
        ld      (ui_text_field_attr_value), a
.put:
        ld      a, (ui_text_field_base_y)
        ld      d, a
        ld      a, (ui_text_field_base_x)
        ld      e, a
        ld      a, (ui_text_field_pos)
        add     a, e
        ld      e, a
        ld      a, (ui_text_field_attr_value)
        ld      b, a
        ld      a, (ui_text_field_char)
        call    ui_put_cell
        call    ui_text_field_attr
        ld      (ui_text_field_attr_value), a
        ld      a, (ui_text_field_pos)
        inc     a
        ld      (ui_text_field_pos), a
        jr      .loop

ui_text_field_char_at_pos:
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      a, (ui_text_field_pos)
        ld      b, a
        ld      a, (iy + UI_TEXT_SCROLL)
        add     a, b
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      a, (hl)
        or      a
        jr      z, .space
        bit     1, (iy + UI_TEXT_FLAGS)
        ret     z
        ld      a, "*"
        ret
.space:
        ld      a, " "
        ret

; ui_text_field_update_scroll
; Keeps the cursor visible inside the fixed-width field.
; In:  IY=text field descriptor
; Out: none
; Clobbers: AF, BC
ui_text_field_update_scroll:
        ld      a, (iy + UI_TEXT_W)
        or      a
        jr      z, .zero
        ld      b, a
        ld      a, (iy + UI_TEXT_CURSOR)
        ld      c, a
        ld      a, (iy + UI_TEXT_SCROLL)
        cp      c
        jr      z, .check_right
        jr      nc, .scroll_left
.check_right:
        add     a, b
        ld      b, a
        ld      a, c
        cp      b
        jr      c, .store_cursor
        ld      a, (iy + UI_TEXT_W)
        ld      b, a
        ld      a, c
        sub     b
        inc     a
        jr      .store
.scroll_left:
        ld      a, c
        jr      .store
.zero:
        xor     a
.store:
        ld      (iy + UI_TEXT_SCROLL), a
.store_cursor:
        ld      a, (iy + UI_TEXT_SCROLL)
        ld      b, a
        ld      a, (iy + UI_TEXT_CURSOR)
        sub     b
        ld      (ui_text_field_cursor_screen), a
        ret

; ui_text_field_insert_char
; Inserts printable A at cursor if there is room.
; In:  A=ASCII, IY=text field descriptor
; Out: CF=1 if handled, CF=0 if there was no room
; Clobbers: AF, BC, DE, HL
ui_text_field_insert_char:
        ld      (ui_text_field_char), a
        call    ui_text_field_clamp_cursor
        ld      (ui_text_field_len_value), a
        ld      b, a
        ld      a, (iy + UI_TEXT_MAXLEN)
        cp      b
        jr      z, .full
        jr      c, .full

        ld      a, (iy + UI_TEXT_CURSOR)
        ld      (ui_text_field_cursor_value), a
        ld      a, (ui_text_field_len_value)
        ld      c, a
        sub     (iy + UI_TEXT_CURSOR)
        inc     a                  ; include the trailing zero byte
        ld      b, a

        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      e, c
        ld      d, 0
        add     hl, de             ; HL = buffer + len
        push    hl
        pop     de
        inc     de                 ; DE = buffer + len + 1
.shift_right:
        ld      a, (hl)
        ld      (de), a
        dec     hl
        dec     de
        djnz    .shift_right

        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      a, (ui_text_field_cursor_value)
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      a, (ui_text_field_char)
        ld      (hl), a
        ld      a, (iy + UI_TEXT_CURSOR)
        inc     a
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret
.full:
        or      a
        ret

; ui_text_field_backspace
; Deletes the character before cursor.
; In:  IY=text field descriptor
; Out: CF=1 if handled, CF=0 if cursor was at start
; Clobbers: AF, BC, DE, HL
ui_text_field_backspace:
        call    ui_text_field_clamp_cursor
        ld      a, (iy + UI_TEXT_CURSOR)
        or      a
        ret     z
        dec     a
        ld      (iy + UI_TEXT_CURSOR), a
        jp      ui_text_field_delete_at_cursor

; ui_text_field_delete_at_cursor
; Deletes the character under cursor.
; In:  IY=text field descriptor
; Out: CF=1 if handled, CF=0 if cursor was at end
; Clobbers: AF, BC, DE, HL
ui_text_field_delete_at_cursor:
        call    ui_text_field_clamp_cursor
        ld      (ui_text_field_len_value), a
        ld      b, a
        ld      a, (iy + UI_TEXT_CURSOR)
        cp      b
        ret     nc
        ld      l, (iy + UI_TEXT_BUFFER)
        ld      h, (iy + UI_TEXT_BUFFER + 1)
        ld      e, a
        ld      d, 0
        add     hl, de             ; HL = destination
        push    hl
        pop     de
        inc     hl                 ; HL = source
        ld      a, (ui_text_field_len_value)
        sub     (iy + UI_TEXT_CURSOR)
        ld      b, a
.shift_left:
        ld      a, (hl)
        ld      (de), a
        inc     hl
        inc     de
        djnz    .shift_left
        scf
        ret

ui_text_field_cursor_left:
        ld      a, (iy + UI_TEXT_CURSOR)
        or      a
        ret     z
        dec     a
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret

ui_text_field_cursor_right:
        call    ui_text_field_clamp_cursor
        ld      b, a
        ld      a, (iy + UI_TEXT_CURSOR)
        cp      b
        ret     nc
        inc     a
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret

ui_text_field_cursor_home:
        xor     a
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret

ui_text_field_cursor_end:
        call    ui_text_field_len
        ld      (iy + UI_TEXT_CURSOR), a
        scf
        ret

; ui_text_field_clamp_cursor
; In:  IY=text field descriptor
; Out: A=length
; Clobbers: AF, BC, HL
ui_text_field_clamp_cursor:
        call    ui_text_field_len
        ld      b, a
        ld      a, (iy + UI_TEXT_CURSOR)
        cp      b
        jr      c, .done
        jr      z, .done
        ld      a, b
        ld      (iy + UI_TEXT_CURSOR), a
.done:
        ld      a, b
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
ui_text_field_base_x:
        db      0
ui_text_field_base_y:
        db      0
ui_text_field_pos:
        db      0
ui_text_field_len_value:
        db      0
ui_text_field_cursor_value:
        db      0
ui_text_field_cursor_screen:
        db      0
