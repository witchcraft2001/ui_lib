; Vertical scroll bar: up/down arrows, patterned track and a thumb.
; Reusable as a standalone dialog widget and by ListBox.
;
; Scroll state is passed through three module variables so the drawing core
; can be driven either from a descriptor or directly by another widget.

ui_scroll_total:
        db      0
ui_scroll_visible:
        db      0
ui_scroll_top:
        db      0

; ui_draw_scrollbar
; Draw a scroll bar from its descriptor.
; In:  IX = parent window descriptor, IY = scrollbar descriptor
; Clobbers: AF, BC, DE, HL
ui_draw_scrollbar:
        ld      a, (iy + UI_SCROLLBAR_TOTAL)
        ld      (ui_scroll_total), a
        ld      a, (iy + UI_SCROLLBAR_VISIBLE)
        ld      (ui_scroll_visible), a
        ld      a, (iy + UI_SCROLLBAR_TOP)
        ld      (ui_scroll_top), a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_SCROLLBAR_Y)
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_SCROLLBAR_X)
        ld      e, a
        ld      b, (iy + UI_SCROLLBAR_H)
        ; fall through

; ui_draw_vscrollbar
; Draw a scroll bar at absolute coordinates.
; In:  D = top row, E = column, B = height (>=3 to show a track)
;      ui_scroll_total/visible/top set by the caller
; Clobbers: AF, BC, DE, HL
ui_draw_vscrollbar:
        ld      a, d
        ld      (.row), a
        ld      a, e
        ld      (.col), a
        ld      a, b
        ld      (.height), a

        ; up arrow at the top cell
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_SCROLL_UP_CHAR
        call    ui_put_cell

        ; down arrow at the bottom cell
        ld      a, (.row)
        ld      b, a
        ld      a, (.height)
        dec     a
        add     a, b
        ld      d, a
        ld      a, (.col)
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_SCROLL_DOWN_CHAR
        call    ui_put_cell

        ; track cells between the arrows
        ld      a, (.height)
        sub     2
        ret     c
        ret     z
        ld      (.track), a

        ; patterned track fill (one column, .track rows)
        ld      a, (.row)
        inc     a
        ld      d, a
        ld      a, (.col)
        ld      e, a
        ld      a, (.track)
        ld      h, a
        ld      l, 1
        ld      a, (ui_theme_text_field)
        ld      b, a
        ld      a, UI_SCROLL_TRACK_CHAR
        call    ui_fill_rect

        ; thumb cell over the track
        ld      a, (.track)
        call    ui_scrollbar_thumb_offset
        ld      c, a
        ld      a, (.row)
        inc     a
        add     a, c
        ld      d, a
        ld      a, (.col)
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_SCROLL_THUMB_CHAR
        jp      ui_put_cell
.row:
        db      0
.col:
        db      0
.height:
        db      0
.track:
        db      0

; ui_scrollbar_thumb_offset
; Map the scroll position onto the track.
; In:  A = track cell count, ui_scroll_total/visible/top
; Out: A = thumb offset in [0 .. track-1]
; Clobbers: AF, BC, DE, HL
ui_scrollbar_thumb_offset:
        dec     a
        ld      (.range), a         ; range = track - 1
        ld      a, (ui_scroll_total)
        ld      b, a
        ld      a, (ui_scroll_visible)
        ld      c, a
        ld      a, b
        sub     c                   ; max_top = total - visible
        jr      c, .zero
        jr      z, .zero
        ld      (.maxtop), a

        ; HL = top * range
        ld      a, (ui_scroll_top)
        ld      e, a
        ld      d, 0
        ld      hl, 0
        ld      a, (.range)
.mul:
        or      a
        jr      z, .div
        add     hl, de
        dec     a
        jr      .mul
.div:
        ; A = HL / maxtop
        ld      a, (.maxtop)
        ld      e, a
        ld      d, 0
        ld      c, 0
.divloop:
        ld      a, h
        or      a
        jr      nz, .sub
        ld      a, l
        cp      e
        jr      c, .divdone
.sub:
        or      a
        sbc     hl, de
        inc     c
        jr      .divloop
.divdone:
        ld      a, (.range)         ; clamp quotient to range
        cp      c
        jr      nc, .ok
        ld      c, a
.ok:
        ld      a, c
        ret
.zero:
        xor     a
        ret
.range:
        db      0
.maxtop:
        db      0

; ui_scrollbar_hit
; Hit-test the last mouse event against a scroll bar.
; In:  D = top row, E = column, B = height; ui_event_mouse_x/y
; Out: A = UI_SCROLL_HIT_NONE/UP/DOWN/TRACK
; Clobbers: AF, BC
ui_scrollbar_hit:
        ld      a, (ui_event_mouse_x)
        cp      e
        jr      nz, .none
        ld      a, d
        add     a, b
        dec     a
        ld      c, a                ; C = bottom row
        ld      a, (ui_event_mouse_y)
        cp      d
        jr      z, .up
        cp      c
        jr      z, .down
        cp      d
        jr      c, .none            ; above the top
        cp      c
        jr      nc, .none           ; below the bottom
        ld      a, UI_SCROLL_HIT_TRACK
        ret
.up:
        ld      a, UI_SCROLL_HIT_UP
        ret
.down:
        ld      a, UI_SCROLL_HIT_DOWN
        ret
.none:
        ld      a, UI_SCROLL_HIT_NONE
        ret
