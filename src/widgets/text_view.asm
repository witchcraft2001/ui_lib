; TextView: a read-only, vertically scrollable text viewer. The text is
; word-wrapped to the inner width; a vertical ScrollBar is always shown in the
; last inner column. Requires message_box.asm (word-wrap engine), scrollbar.asm
; and draw/text.asm.
;
; The scroll bar column is always reserved, so the wrap width is constant and
; the wrapped line count is well defined (no measure/draw circularity).

ui_tv_x:
        db      0
ui_tv_y:
        db      0
ui_tv_visible:
        db      0
ui_tv_total:
        db      0
ui_tv_row:
        db      0
; Byte offset of the first visible (TOP) line. Forward moves advance it
; incrementally; backward moves re-anchor it from the start of the text. This
; keeps scrolling off the O(total) per-step reparse without a full line index.
ui_tv_top_ptr:
        dw      0

; ui_draw_text_view
; In:  IX = parent window descriptor, IY = textview descriptor
; Clobbers: AF, BC, DE, HL
ui_draw_text_view:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_TEXTVIEW_X)
        ld      (ui_tv_x), a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_TEXTVIEW_Y)
        ld      (ui_tv_y), a
        ld      a, (iy + UI_TEXTVIEW_H)
        sub     2
        ld      (ui_tv_visible), a
        call    ui_tv_count_total
        call    ui_tv_clamp_top
        call    ui_tv_reanchor              ; top_ptr for the initial TOP
        call    ui_tv_draw_frame
        call    ui_tv_redraw_visible
        jp      ui_tv_draw_scroll

; Point the wrap engine at the text with the constant content width.
ui_tv_set_wrap:
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     3                           ; frame (2) + scroll bar column (1)
        ld      (ui_msg_wrap_w), a
        ld      l, (iy + UI_TEXTVIEW_TEXT)
        ld      h, (iy + UI_TEXTVIEW_TEXT + 1)
        ld      (ui_msg_cursor), hl
        ret

; Count all wrapped lines (8-bit, capped at 255) into ui_tv_total.
ui_tv_count_total:
        call    ui_tv_set_wrap
        xor     a
        ld      (ui_tv_total), a
.loop:
        call    ui_msg_next_line
        push    af
        ld      a, (ui_tv_total)
        inc     a
        jr      z, .cap
        ld      (ui_tv_total), a
        pop     af
        jr      c, .done
        jr      .loop
.cap:
        ld      a, 255
        ld      (ui_tv_total), a
        pop     af
.done:
        ret

; Point the wrap engine at the first visible line via ui_tv_top_ptr (no parse).
ui_tv_cursor_from_top:
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     3
        ld      (ui_msg_wrap_w), a
        ld      de, (ui_tv_top_ptr)
        ld      (ui_msg_cursor), de
        ret

; Re-anchor ui_tv_top_ptr by parsing from the start of the text to line TOP.
; Cost O(TOP) - used only for backward moves.
ui_tv_reanchor:
        call    ui_tv_set_wrap
        ld      a, (iy + UI_TEXTVIEW_TOP)
        or      a
        jr      z, .done
        ld      b, a
.loop:
        push    bc
        call    ui_msg_next_line
        pop     bc
        djnz    .loop
.done:
        ld      de, (ui_msg_cursor)
        ld      (ui_tv_top_ptr), de
        ret

; Advance ui_tv_top_ptr forward by B lines. Cost O(B).
ui_tv_advance_top:
        ld      a, b
        or      a
        ret     z
.loop:
        push    bc
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     3
        ld      (ui_msg_wrap_w), a
        ld      de, (ui_tv_top_ptr)
        ld      (ui_msg_cursor), de
        call    ui_msg_next_line
        ld      de, (ui_msg_cursor)
        ld      (ui_tv_top_ptr), de
        pop     bc
        djnz    .loop
        ret

; Move TOP to line A, keeping ui_tv_top_ptr in sync (forward = advance,
; backward = re-anchor).
ui_tv_seek:
        ld      c, a                        ; new TOP
        ld      a, (iy + UI_TEXTVIEW_TOP)
        cp      c
        ret     z
        jr      nc, .back
        ld      a, c                        ; forward: advance (new-cur) lines
        sub     (iy + UI_TEXTVIEW_TOP)
        ld      b, a
        ld      a, c
        ld      (iy + UI_TEXTVIEW_TOP), a
        jp      ui_tv_advance_top
.back:
        ld      a, c
        ld      (iy + UI_TEXTVIEW_TOP), a
        jp      ui_tv_reanchor

ui_tv_max_top:
        ld      a, (ui_tv_total)
        ld      b, a
        ld      a, (ui_tv_visible)
        ld      c, a
        ld      a, b
        sub     c
        ret     nc
        xor     a
        ret

ui_tv_clamp_top:
        call    ui_tv_max_top
        ld      b, a
        ld      a, (iy + UI_TEXTVIEW_TOP)
        cp      b
        ret     c
        ret     z
        ld      a, b
        ld      (iy + UI_TEXTVIEW_TOP), a
        ret

; Redraw all visible text lines in place (no frame, no full clear).
ui_tv_redraw_visible:
        call    ui_tv_cursor_from_top
        xor     a
        ld      (ui_tv_row), a
.loop:
        ld      a, (ui_tv_row)
        ld      b, a
        ld      a, (ui_tv_visible)
        cp      b
        ret     z
        ld      a, (iy + UI_TEXTVIEW_TOP)
        add     a, b
        ld      c, a
        ld      a, (ui_tv_total)
        cp      c
        jr      z, .blank
        jr      c, .blank
        call    ui_msg_next_line
        call    ui_tv_draw_line
        jr      .next
.blank:
        call    ui_tv_blank_line
.next:
        ld      a, (ui_tv_row)
        inc     a
        ld      (ui_tv_row), a
        jr      .loop

; Draw the current ui_msg_line_start/len at screen row ui_tv_row, padded.
ui_tv_draw_line:
        ld      a, (ui_tv_y)
        inc     a
        ld      b, a
        ld      a, (ui_tv_row)
        add     a, b
        ld      d, a
        ld      a, (ui_tv_x)
        inc     a
        ld      e, a
        ld      hl, (ui_msg_line_start)
        ld      a, (ui_msg_line_len)
        ld      b, a
        jp      ui_tv_print_field

ui_tv_blank_line:
        ld      a, (ui_tv_y)
        inc     a
        ld      b, a
        ld      a, (ui_tv_row)
        add     a, b
        ld      d, a
        ld      a, (ui_tv_x)
        inc     a
        ld      e, a
        ld      hl, ui_tv_x                  ; unused: 0 chars shown
        ld      b, 0
        jp      ui_tv_print_field

; Print B characters from HL, then pad with spaces to the content width
; (W-3), at D=row, E=col, using UI_THEME_WINDOW. Sets the cursor once.
ui_tv_print_field:
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     3
        ld      (.w), a
        ld      a, b
        ld      (.shown), a
        push    ix
        push    iy
        ld      c, Bios.Lp_Set_Place
        call    ui_call_bios
.loop:
        ld      a, (.w)
        or      a
        jr      z, .done
        dec     a
        ld      (.w), a
        ld      a, (.shown)
        or      a
        jr      z, .pad
        dec     a
        ld      (.shown), a
        ld      a, (hl)
        inc     hl
        jr      .emit
.pad:
        ld      a, " "
.emit:
        push    hl
        ld      c, a
        ld      a, (ui_theme_window)
        ld      e, a
        ld      a, c
        ld      b, 1
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     hl
        jr      .loop
.done:
        pop     iy
        pop     ix
        ret
.w:
        db      0
.shown:
        db      0

; Draw just one screen row (ui_tv_row = A), used after a DSS scroll.
ui_tv_draw_one:
        ld      (ui_tv_row), a
        ld      b, a
        ld      a, (iy + UI_TEXTVIEW_TOP)
        add     a, b
        ld      c, a
        ld      a, (ui_tv_total)
        cp      c
        jp      z, ui_tv_blank_line
        jp      c, ui_tv_blank_line
        call    ui_tv_cursor_from_top       ; parse forward from the first line
        ld      a, (ui_tv_row)
        or      a
        jr      z, .draw
        ld      b, a
.skip:
        push    bc
        call    ui_msg_next_line
        pop     bc
        djnz    .skip
.draw:
        call    ui_msg_next_line
        jp      ui_tv_draw_line

; DSS scroll of the text area (scroll bar column untouched). In: B = direction.
ui_tv_scroll_dss:
        ld      a, b
        ld      (.dir), a
        ld      a, (ui_tv_y)
        inc     a
        ld      d, a
        ld      a, (ui_tv_x)
        inc     a
        ld      e, a
        ld      a, (ui_tv_visible)
        ld      h, a
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     3
        ld      l, a
        ld      a, (.dir)
        ld      b, a
        push    ix
        push    iy
        xor     a
        ld      c, Dss.Scroll
        call    ui_call_dss
        pop     iy
        pop     ix
        ret
.dir:
        db      0

; Draw the single-line frame and clear the interior.
ui_tv_draw_frame:
        ld      a, (ui_tv_y)
        ld      d, a
        ld      a, (ui_tv_x)
        ld      e, a
        ld      h, (iy + UI_TEXTVIEW_H)
        ld      l, (iy + UI_TEXTVIEW_W)
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, " "
        call    ui_fill_rect

        ld      a, (ui_tv_y)
        ld      d, a
        ld      a, (ui_tv_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0DAh
        call    ui_put_cell
        ld      a, (ui_tv_y)
        ld      d, a
        ld      a, (ui_tv_x)
        inc     a
        ld      e, a
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        call    ui_fill_rect
        ld      a, (ui_tv_y)
        ld      d, a
        ld      a, (ui_tv_x)
        add     a, (iy + UI_TEXTVIEW_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BFh
        call    ui_put_cell

        ld      a, (iy + UI_TEXTVIEW_H)
        sub     2
        ld      c, a
        ld      a, (ui_tv_y)
        ld      d, a
.sides:
        inc     d
        ld      a, (ui_tv_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      a, (ui_tv_x)
        add     a, (iy + UI_TEXTVIEW_W)
        dec     a
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

        ld      a, (ui_tv_y)
        add     a, (iy + UI_TEXTVIEW_H)
        dec     a
        ld      d, a
        ld      a, (ui_tv_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C0h
        call    ui_put_cell
        ld      a, (ui_tv_y)
        add     a, (iy + UI_TEXTVIEW_H)
        dec     a
        ld      d, a
        ld      a, (ui_tv_x)
        inc     a
        ld      e, a
        ld      a, (iy + UI_TEXTVIEW_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        call    ui_fill_rect
        ld      a, (ui_tv_y)
        add     a, (iy + UI_TEXTVIEW_H)
        dec     a
        ld      d, a
        ld      a, (ui_tv_x)
        add     a, (iy + UI_TEXTVIEW_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0D9h
        jp      ui_put_cell

; Draw the scroll bar over the last inner column.
ui_tv_draw_scroll:
        ld      a, (ui_tv_total)
        ld      (ui_scroll_total), a
        ld      a, (ui_tv_visible)
        ld      (ui_scroll_visible), a
        ld      a, (iy + UI_TEXTVIEW_TOP)
        ld      (ui_scroll_top), a
        ld      a, (ui_tv_x)
        add     a, (iy + UI_TEXTVIEW_W)
        sub     2
        ld      e, a
        ld      a, (ui_tv_y)
        inc     a
        ld      d, a
        ld      a, (ui_tv_visible)
        ld      b, a
        jp      ui_draw_vscrollbar

; ui_text_view_run
; Draw the view and run a modal scroll loop until Esc/Enter.
; In:  IX = parent window descriptor, IY = textview descriptor
; Clobbers: AF, BC, DE, HL
ui_text_view_run:
        call    ui_draw_text_view
.loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      z, .key
        cp      UI_EVENT_MOUSE
        jp      z, .mouse
        jr      .loop
.key:
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        ret     z
        cp      UI_KEY_ENTER
        ret     z
        ld      a, (ui_event_scan)
        cp      UI_SCAN_DOWN
        jr      z, .down
        cp      UI_SCAN_UP
        jr      z, .up
        cp      UI_SCAN_PGDN
        jp      z, .pgdn
        cp      UI_SCAN_PGUP
        jp      z, .pgup
        cp      UI_SCAN_HOME
        jp      z, .home
        cp      UI_SCAN_END
        jp      z, .end
        jr      .loop
.down:
        call    ui_tv_max_top
        ld      b, a
        ld      a, (iy + UI_TEXTVIEW_TOP)
        cp      b
        jr      z, .loop
        jr      nc, .loop
        inc     a
        call    ui_tv_seek
        ld      b, 1
        call    ui_tv_scroll_dss
        ld      a, (ui_tv_visible)
        dec     a
        call    ui_tv_draw_one
        call    ui_tv_draw_scroll
        jr      .loop
.up:
        ld      a, (iy + UI_TEXTVIEW_TOP)
        or      a
        jr      z, .loop
        dec     a
        call    ui_tv_seek
        ld      b, 2
        call    ui_tv_scroll_dss
        xor     a
        call    ui_tv_draw_one
        call    ui_tv_draw_scroll
        jr      .loop
.pgdn:
        call    ui_tv_max_top
        ld      c, a
        ld      a, (iy + UI_TEXTVIEW_TOP)
        cp      c
        jp      z, .loop
        ld      a, (iy + UI_TEXTVIEW_TOP)
        ld      hl, ui_tv_visible
        add     a, (hl)
        jr      c, .pgdn_clamp
        cp      c
        jr      c, .pgdn_set
        jr      z, .pgdn_set
.pgdn_clamp:
        ld      a, c
.pgdn_set:
        call    ui_tv_seek
        jr      .refresh
.pgup:
        ld      a, (iy + UI_TEXTVIEW_TOP)
        or      a
        jp      z, .loop
        ld      hl, ui_tv_visible
        sub     (hl)
        jr      nc, .pgup_set
        xor     a
.pgup_set:
        call    ui_tv_seek
        jr      .refresh
.home:
        xor     a
        call    ui_tv_seek
        jr      .refresh
.end:
        call    ui_tv_max_top
        call    ui_tv_seek
.refresh:
        call    ui_tv_redraw_visible
        call    ui_tv_draw_scroll
        jp      .loop
.mouse:
        ld      a, (ui_tv_x)
        add     a, (iy + UI_TEXTVIEW_W)
        sub     2
        ld      e, a
        ld      a, (ui_tv_y)
        inc     a
        ld      d, a
        ld      a, (ui_tv_visible)
        ld      b, a
        call    ui_scrollbar_hit
        cp      UI_SCROLL_HIT_UP
        jp      z, .up
        cp      UI_SCROLL_HIT_DOWN
        jp      z, .down
        jp      .loop
