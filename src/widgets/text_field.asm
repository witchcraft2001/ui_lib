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

; ui_text_field_invert_attr
; Inverse of a text attribute for the cursor cell: swap the 3-bit INK and PAPER
; fields, leaving bit 3 (bright) and bit 7 (flash) untouched -- exactly like
; texteditor's PutCursor. A full nibble swap would move bright into the flash bit
; and make the BIOS hardware-flash the glyph (the "disappearing symbol").
; In:  A = attribute
; Out: A = inverted attribute
; Clobbers: AF, BC
ui_text_field_invert_attr:
        ld      b, a
        and     7
        rlca
        rlca
        rlca
        rlca
        ld      c, a
        ld      a, b
        and     %01110000
        rrca
        rrca
        rrca
        rrca
        or      c
        ld      c, a
        ld      a, b
        and     %10001000
        or      c
        ret

; ui_draw_text_field
; In:  IX=parent window descriptor, IY=text field descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_text_field:
        bit     6, (iy + UI_TEXT_FLAGS)         ; focused -> drive the blink here
        jr      z, .no_blink
        ld      (ui_cursor_field), iy
        ld      (ui_cursor_window), ix
        ld      hl, ui_cursor_blink
        ld      (ui_cursor_blink_hook), hl
        ld      a, 1                            ; solid on a fresh/refresh draw
        ld      (ui_text_cursor_visible), a
        xor     a
        ld      (ui_cursor_phase), a
.no_blink:
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
        ld      a, (ui_text_field_attr_value)   ; cursor cell = inverse colour
        call    ui_text_field_invert_attr
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

; ui_cursor_blink
; Called ~50 Hz from the event loop (via ui_cursor_blink_hook). Counts frames and
; flips the cursor between normal and inverse on the focused field. Self-stops if
; the field is no longer focused. Clobbers AF, BC, DE, HL, IX, IY.
ui_cursor_blink:
        ld      hl, (ui_cursor_field)
        ld      a, h
        or      l
        ret     z                               ; no field registered
        push    hl
        pop     iy
        bit     6, (iy + UI_TEXT_FLAGS)
        jr      z, .stop                        ; field lost focus -> stop
        ld      a, (ui_text_cursor_visible)     ; cursor disabled by the app?
        or      a
        ret     z
        ld      a, (ui_cursor_phase)
        inc     a
        ld      (ui_cursor_phase), a
        cp      13                              ; ~0.26 s at 50 Hz
        ret     c
        xor     a
        ld      (ui_cursor_phase), a
        ld      ix, (ui_cursor_window)
        jp      ui_text_field_toggle_cursor_cell
.stop:
        ld      hl, 0
        ld      (ui_cursor_field), hl
        ret

; Flip the cursor cell of IX/IY between normal and inverse. Reads only the cell's
; current attribute (Dss.RdChar), swaps its INK/PAPER nibbles, and writes back
; ONLY the attribute (Bios.Lp_Print_Atr) — the character glyph is never touched,
; so it cannot vanish; only the cell colour toggles. This mirrors texteditor.
ui_text_field_toggle_cursor_cell:
        call    ui_text_field_clamp_cursor
        call    ui_text_field_update_scroll
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_TEXT_Y)
        ld      d, a                            ; D = row
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_TEXT_X)
        ld      b, a
        ld      a, (ui_text_field_cursor_screen)
        add     a, b
        ld      e, a                            ; E = column
        di                                      ; texteditor: BIOS/DSS calls here
        push    de                              ; borrow WIN2 + a shared SafeStack;
        ld      c, Dss.RdChar                   ; B = current attribute
        call    ui_call_dss                     ; an interrupt re-entering them would
        ld      a, b                            ; corrupt the cell, so block them
        call    ui_text_field_invert_attr
        ld      (.attr), a
        pop     de
        ld      c, Bios.Lp_Set_Place            ; position at the cursor cell
        call    ui_call_bios
        ld      a, (.attr)
        ld      e, a                            ; E = inverted attribute
        ld      b, 1                            ; one cell, glyph untouched
        ld      c, Bios.Lp_Print_Atr
        call    ui_call_bios
        ei
        ret
.attr:
        db      0

ui_cursor_field:
        dw      0
ui_cursor_window:
        dw      0
ui_cursor_phase:
        db      0
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
