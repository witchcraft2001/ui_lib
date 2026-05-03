; ComboBox drawing and dropdown popup selection.

UI_COMBO_SCROLL_UP_CHAR     equ     1Eh
UI_COMBO_SCROLL_DOWN_CHAR   equ     1Fh
UI_COMBO_SCROLL_TRACK_CHAR  equ     0B1h
UI_COMBO_SCROLL_THUMB_CHAR  equ     0DBh
UI_COMBO_MOUSE_SCROLL_UP    equ     0FEh
UI_COMBO_MOUSE_SCROLL_DOWN  equ     0FDh
UI_COMBO_MOUSE_NO_ACTION    equ     0FCh

; ui_draw_combo_box
; In:  IX=parent window descriptor, IY=combo descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_combo_box:
        call    ui_combo_clamp_selected
        call    ui_combo_attr
        ld      (ui_combo_attr_value), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_COMBO_X)
        ld      (ui_combo_base_x), a
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_COMBO_Y)
        ld      (ui_combo_base_y), a
        ld      d, a
        ld      a, (iy + UI_COMBO_W)
        ld      (ui_combo_width), a
        or      a
        ret     z
        ld      h, 1
        ld      l, a
        ld      a, " "
        push    af
        ld      a, (ui_combo_attr_value)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ld      a, (ui_combo_width)
        cp      4
        jr      c, .skip_text
        sub     3
        ld      (ui_combo_text_width), a
        ld      a, (iy + UI_COMBO_COUNT)
        or      a
        jr      z, .skip_text
        call    ui_combo_selected_item
        ld      a, (ui_combo_base_x)
        ld      e, a
        ld      a, (ui_combo_base_y)
        ld      d, a
        call    ui_combo_print_text
.skip_text:
        jp      ui_combo_draw_drop_button

; ui_combo_select_popup
; Opens dropdown popup and updates selected item on commit.
; In:  IX=parent window descriptor, IY=combo descriptor
; Out: CF=0 committed, CF=1 cancelled/no items
; Clobbers: AF, BC, DE, HL
ui_combo_select_popup:
        ld      a, (iy + UI_COMBO_FLAGS)
        bit     7, a
        jp      nz, .cancel_no_clear
        ld      a, (iy + UI_COMBO_COUNT)
        or      a
        jp      z, .cancel_no_clear
        call    ui_combo_clamp_selected
        ld      a, (iy + UI_COMBO_SELECTED)
        ld      (ui_combo_popup_selected), a
        xor     a
        ld      (ui_combo_popup_top), a
        call    ui_combo_popup_height
        call    ui_combo_popup_make_visible
        call    ui_draw_combo_popup
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
        jp      z, .cancel
        cp      UI_KEY_ENTER
        jp      z, .commit
        cp      UI_KEY_SPACE
        jp      z, .commit
        ld      a, (ui_event_scan)
        cp      UI_SCAN_UP
        jr      z, .up
        cp      UI_SCAN_DOWN
        jr      z, .down
        cp      UI_SCAN_HOME
        jr      z, .home
        cp      UI_SCAN_END
        jr      z, .end
        jr      .loop
.up:
        ld      a, (ui_combo_popup_selected)
        or      a
        jp      z, .loop
.up_move:
        call    ui_combo_popup_save_move_state
        ld      a, (ui_combo_popup_selected)
        dec     a
        ld      (ui_combo_popup_selected), a
        call    ui_combo_popup_make_visible
        call    ui_combo_popup_refresh_after_move
        jp      .loop
.down:
        ld      a, (ui_combo_popup_selected)
        inc     a
        ld      b, a
        ld      a, (iy + UI_COMBO_COUNT)
        cp      b
        jp      z, .loop
        jp      c, .loop
        call    ui_combo_popup_save_move_state
        ld      a, b
        ld      (ui_combo_popup_selected), a
        call    ui_combo_popup_make_visible
        call    ui_combo_popup_refresh_after_move
        jp      .loop
.home:
        ld      a, (ui_combo_popup_selected)
        or      a
        jp      z, .loop
.home_move:
        call    ui_combo_popup_save_move_state
        xor     a
        ld      (ui_combo_popup_selected), a
        ld      (ui_combo_popup_top), a
        call    ui_combo_popup_refresh_after_move
        jp      .loop
.end:
        ld      a, (iy + UI_COMBO_COUNT)
        dec     a
        ld      b, a
        ld      a, (ui_combo_popup_selected)
        cp      b
        jp      z, .loop
.end_move:
        call    ui_combo_popup_save_move_state
        ld      a, b
        ld      (ui_combo_popup_selected), a
        call    ui_combo_popup_make_visible
        call    ui_combo_popup_refresh_after_move
        jp      .loop
.mouse:
        call    ui_combo_popup_mouse_hit
        jr      c, .cancel
        cp      UI_COMBO_MOUSE_SCROLL_UP
        jp      z, .up
        cp      UI_COMBO_MOUSE_SCROLL_DOWN
        jp      z, .down
        cp      UI_COMBO_MOUSE_NO_ACTION
        jp      z, .loop
        ld      (ui_combo_popup_selected), a
        jr      .commit
.commit:
        ld      a, (ui_combo_popup_selected)
        ld      (iy + UI_COMBO_SELECTED), a
        call    ui_clear_combo_popup
        or      a
        ret
.cancel:
        call    ui_clear_combo_popup
.cancel_no_clear:
        scf
        ret

ui_combo_attr:
        ld      a, (iy + UI_COMBO_FLAGS)
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

ui_combo_put:
        push    af
        ld      a, (ui_combo_attr_value)
        ld      b, a
        pop     af
        call    ui_put_cell
        ret

ui_combo_clamp_selected:
        ld      a, (iy + UI_COMBO_COUNT)
        or      a
        jr      z, .zero
        ld      b, a
        ld      a, (iy + UI_COMBO_SELECTED)
        cp      b
        ret     c
.zero:
        xor     a
        ld      (iy + UI_COMBO_SELECTED), a
        ret

ui_combo_selected_item:
        ld      a, (iy + UI_COMBO_SELECTED)
        jr      ui_combo_item_by_index

ui_combo_popup_item:
        ld      a, (ui_combo_popup_top)
        ld      b, a
        ld      a, (ui_combo_popup_row)
        add     a, b

ui_combo_item_by_index:
        ld      l, (iy + UI_COMBO_ITEMS)
        ld      h, (iy + UI_COMBO_ITEMS + 1)
        add     a, a
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     hl
        ret

ui_combo_print_text:
        ld      a, (ui_combo_text_width)
        or      a
        ret     z
        ld      b, a
.loop:
        ld      a, (hl)
        or      a
        ret     z
        push    bc
        push    hl
        push    de
        call    ui_combo_put
        pop     de
        pop     hl
        pop     bc
        inc     hl
        inc     e
        djnz    .loop
        ret

ui_combo_draw_drop_button:
        ld      a, (ui_combo_width)
        cp      3
        ret     c
        ld      a, (ui_combo_base_x)
        add     a, (iy + UI_COMBO_W)
        sub     3
        ld      e, a
        ld      a, (ui_combo_base_y)
        ld      d, a
        ld      a, "["
        call    ui_combo_put
        inc     e
        ld      a, 1Fh
        call    ui_combo_put
        inc     e
        ld      a, "]"
        jp      ui_combo_put

ui_combo_popup_height:
        ld      a, (iy + UI_COMBO_POPUP_H)
        or      a
        jr      nz, .have
        ld      a, 4
.have:
        ld      b, a
        ld      a, (iy + UI_COMBO_COUNT)
        cp      b
        jr      nc, .store_b
        ld      b, a
.store_b:
        ld      a, b
        ld      (ui_combo_popup_h), a
        ret

ui_combo_popup_make_visible:
        ld      a, (ui_combo_popup_selected)
        ld      b, a
        ld      a, (ui_combo_popup_top)
        cp      b
        jr      c, .check_bottom
        jr      z, .check_bottom
        ld      a, b
        ld      (ui_combo_popup_top), a
        jp      ui_combo_popup_clamp_top
.check_bottom:
        ld      a, (ui_combo_popup_top)
        ld      c, a
        ld      a, (ui_combo_popup_h)
        ld      e, a
        ld      a, b
        sub     c
        ld      c, a
        ld      a, e
        cp      c
        jr      z, .scroll_down
        jp      nc, ui_combo_popup_clamp_top
.scroll_down:
        ld      a, b
        ld      c, a
        ld      a, (ui_combo_popup_h)
        ld      b, a
        ld      a, c
        sub     b
        inc     a
        ld      (ui_combo_popup_top), a
        jr      nc, ui_combo_popup_clamp_top
        xor     a
        ld      (ui_combo_popup_top), a
        ret

ui_combo_popup_clamp_top:
        ld      a, (iy + UI_COMBO_COUNT)
        ld      b, a
        ld      a, (ui_combo_popup_h)
        ld      c, a
        ld      a, b
        sub     c
        jr      nc, .have_max
        xor     a
.have_max:
        ld      b, a
        ld      a, (ui_combo_popup_top)
        cp      b
        ret     c
        ret     z
        ld      a, b
        ld      (ui_combo_popup_top), a
        ret

ui_combo_popup_save_move_state:
        ld      a, (ui_combo_popup_selected)
        ld      (ui_combo_popup_old_selected), a
        ld      a, (ui_combo_popup_top)
        ld      (ui_combo_popup_old_top), a
        ret

ui_combo_popup_refresh_after_move:
        ld      a, (ui_combo_popup_old_top)
        ld      b, a
        ld      a, (ui_combo_popup_top)
        cp      b
        jr      z, .same_top
        ld      c, a
        ld      a, b
        inc     a
        cp      c
        jr      z, .scroll_up
        ld      a, c
        inc     a
        cp      b
        jr      z, .scroll_down
        jp      ui_draw_combo_popup
.scroll_up:
        call    ui_combo_popup_unfocus_old
        call    ui_combo_scroll_rows_up
        ld      a, (ui_combo_popup_h)
        dec     a
        ld      (ui_combo_popup_row), a
        call    ui_draw_combo_popup_row
        jp      ui_combo_redraw_scroll_column
.scroll_down:
        call    ui_combo_popup_unfocus_old
        call    ui_combo_scroll_rows_down
        xor     a
        ld      (ui_combo_popup_row), a
        call    ui_draw_combo_popup_row
        jp      ui_combo_redraw_scroll_column
.same_top:
        ld      a, (ui_combo_popup_old_selected)
        ld      b, a
        ld      a, (ui_combo_popup_top)
        ld      c, a
        ld      a, b
        sub     c
        ld      (ui_combo_popup_row), a
        call    ui_draw_combo_popup_row
        ld      a, (ui_combo_popup_selected)
        ld      b, a
        ld      a, (ui_combo_popup_top)
        ld      c, a
        ld      a, b
        sub     c
        ld      (ui_combo_popup_row), a
        call    ui_draw_combo_popup_row
        jp      ui_combo_redraw_scroll_column

ui_combo_popup_unfocus_old:
        ld      a, (ui_combo_popup_old_selected)
        ld      b, a
        ld      a, (ui_combo_popup_old_top)
        ld      c, a
        ld      a, b
        sub     c
        ret     c
        ld      b, a
        ld      a, (ui_combo_popup_h)
        cp      b
        ret     c
        ret     z
        ld      a, (ui_combo_popup_selected)
        ld      (ui_combo_popup_saved_selected), a
        ld      a, (ui_combo_popup_top)
        ld      (ui_combo_popup_saved_top), a
        ld      a, (ui_combo_popup_old_top)
        ld      (ui_combo_popup_top), a
        ld      a, 0FFh             ; force normal row colors before scrolling
        ld      (ui_combo_popup_selected), a
        ld      a, b
        ld      (ui_combo_popup_row), a
        call    ui_draw_combo_popup_row
        ld      a, (ui_combo_popup_saved_selected)
        ld      (ui_combo_popup_selected), a
        ld      a, (ui_combo_popup_saved_top)
        ld      (ui_combo_popup_top), a
        ret

ui_combo_scroll_rows_up:
        ld      b, 1                ; DSS direction 1: scroll up
        jr      ui_combo_scroll_rows

ui_combo_scroll_rows_down:
        ld      b, 2                ; DSS direction 2: scroll down

ui_combo_scroll_rows:
        ld      a, (ui_combo_popup_y)
        inc     a
        ld      d, a
        ld      a, (ui_combo_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_combo_popup_h)
        ld      h, a
        ld      a, (iy + UI_COMBO_W)
        sub     2
        ld      l, a
        push    ix
        push    iy
        xor     a                 ; clear vacated line after DSS scroll
        ld      c, Dss.Scroll
        call    ui_call_dss
        pop     iy
        pop     ix
        ret

ui_draw_combo_popup:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_COMBO_X)
        ld      (ui_combo_popup_x), a
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_COMBO_Y)
        inc     a
        ld      (ui_combo_popup_y), a
        ld      d, a
        ld      a, (ui_combo_popup_h)
        add     a, 2
        ld      h, a
        ld      l, (iy + UI_COMBO_W)
        ld      a, " "
        push    af
        ld      a, (ui_theme_text_field)
        ld      b, a
        pop     af
        call    ui_fill_rect
        call    ui_draw_combo_popup_frame
        call    ui_combo_redraw_scroll_column
        xor     a
        ld      (ui_combo_popup_row), a
.row_loop:
        ld      a, (ui_combo_popup_row)
        ld      b, a
        ld      a, (ui_combo_popup_h)
        cp      b
        ret     z
        call    ui_draw_combo_popup_row
        ld      a, (ui_combo_popup_row)
        inc     a
        ld      (ui_combo_popup_row), a
        jr      .row_loop

ui_draw_combo_popup_row:
        ld      a, (ui_combo_popup_row)
        ld      b, a
        ld      a, (ui_combo_popup_h)
        cp      b
        ret     c
        ret     z
        ld      a, (ui_combo_popup_top)
        add     a, b
        ld      c, a
        ld      a, (ui_combo_popup_selected)
        cp      c
        jr      z, .focused
        ld      a, (ui_theme_text_field)
        jr      .have_attr
.focused:
        ld      a, (ui_theme_text_field_focus)
.have_attr:
        ld      (ui_combo_attr_value), a
        ld      a, (ui_combo_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_combo_popup_y)
        ld      d, a
        inc     d
        ld      a, (ui_combo_popup_row)
        add     a, d
        ld      d, a
        ld      h, 1
        ld      l, (iy + UI_COMBO_W)
        dec     l
        dec     l
        ld      a, " "
        push    af
        ld      a, (ui_combo_attr_value)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ld      a, (iy + UI_COMBO_W)
        sub     2
        ld      (ui_combo_text_width), a
        call    ui_combo_popup_item
        ld      a, (ui_combo_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_combo_popup_y)
        ld      d, a
        inc     d
        ld      a, (ui_combo_popup_row)
        add     a, d
        ld      d, a
        call    ui_combo_print_text
        ret

ui_combo_popup_mouse_hit:
        ld      a, (ui_event_mouse_x)
        ld      b, a
        ld      a, (ui_combo_popup_x)
        cp      b
        jr      z, .x_ok
        jr      nc, .miss
.x_ok:
        ld      a, b
        ld      c, a
        ld      a, (ui_combo_popup_x)
        cp      c
        jr      z, .miss
        ld      a, (ui_combo_popup_x)
        add     a, (iy + UI_COMBO_W)
        dec     a
        cp      b
        jr      c, .miss
        jr      z, .scrollbar
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_combo_popup_y)
        cp      b
        jr      z, .y_ok
        jr      nc, .miss
.y_ok:
        ld      a, b
        ld      c, a
        ld      a, (ui_combo_popup_y)
        cp      c
        jr      z, .miss
        ld      a, c
        ld      c, a
        ld      a, (ui_combo_popup_y)
        ld      e, a
        ld      a, c
        sub     e
        dec     a
        ld      b, a
        ld      a, (ui_combo_popup_h)
        cp      b
        jr      c, .miss
        jr      z, .miss
        ld      a, (ui_combo_popup_top)
        add     a, b
        or      a
        ret
.scrollbar:
        ld      a, (ui_combo_popup_h)
        cp      3
        jr      c, .miss
        ld      b, a
        ld      a, (iy + UI_COMBO_COUNT)
        cp      b
        jr      z, .miss
        jr      c, .miss
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_combo_popup_y)
        cp      b
        jr      nc, .miss
        ld      c, a
        ld      a, b
        sub     c
        ld      b, a
        ld      a, (ui_combo_popup_h)
        cp      b
        jr      c, .miss
        ld      a, b
        cp      1
        jr      z, .scroll_up_hit
        ld      a, (ui_combo_popup_h)
        cp      b
        jr      z, .scroll_down_hit
        ld      a, UI_COMBO_MOUSE_NO_ACTION
        or      a
        ret
.scroll_up_hit:
        ld      a, UI_COMBO_MOUSE_SCROLL_UP
        or      a
        ret
.scroll_down_hit:
        ld      a, UI_COMBO_MOUSE_SCROLL_DOWN
        or      a
        ret
.miss:
        scf
        ret

ui_draw_combo_popup_frame:
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, (ui_combo_popup_y)
        ld      d, a
        ld      a, (ui_combo_popup_x)
        ld      e, a
        ld      a, 0DAh
        push    de
        call    ui_put_cell
        pop     de
        ld      a, (iy + UI_COMBO_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, (ui_theme_text_field_focus)
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
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0BFh
        call    ui_put_cell

        ld      a, (ui_combo_popup_h)
        ld      c, a
.sides:
        ld      a, (ui_combo_popup_y)
        ld      d, a
        ld      a, (ui_combo_popup_h)
        sub     c
        inc     a
        add     a, d
        ld      d, a
        ld      a, (ui_combo_popup_x)
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      e, (iy + UI_COMBO_W)
        dec     e
        ld      a, (ui_combo_popup_x)
        add     a, e
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        ld      a, (ui_combo_popup_y)
        ld      d, a
        ld      a, (ui_combo_popup_h)
        inc     a
        add     a, d
        ld      d, a
        ld      a, (ui_combo_popup_x)
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0C0h
        push    de
        call    ui_put_cell
        pop     de
        ld      a, (iy + UI_COMBO_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, (ui_theme_text_field_focus)
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
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0D9h
        jp      ui_put_cell

ui_draw_combo_scroll:
        ld      a, (ui_combo_popup_h)
        cp      3
        ret     c
        ld      b, a
        ld      a, (iy + UI_COMBO_COUNT)
        cp      b
        ret     z
        ret     c
        ld      hl, 0
        ld      a, (ui_combo_popup_selected)
        ld      b, a
        ld      a, (ui_combo_popup_h)
        sub     2
        ld      e, a
        ld      d, 0
.mul_loop:
        ld      a, b
        or      a
        jr      z, .mul_done
        add     hl, de
        dec     b
        jr      .mul_loop
.mul_done:
        ld      a, (iy + UI_COMBO_COUNT)
        ld      e, a
        ld      d, 0
        xor     a
.div_loop:
        ld      b, a
        ld      a, h
        or      a
        jr      nz, .subtract
        ld      a, l
        cp      e
        jr      c, .div_done
.subtract:
        or      a
        sbc     hl, de
        ld      a, b
        inc     a
        jr      .div_loop
.div_done:
        ld      a, b
        ld      c, a
        ld      a, (ui_combo_popup_h)
        sub     2
        cp      c
        jr      c, .last
        jr      nz, .have_row
.last:
        ld      a, (ui_combo_popup_h)
        sub     3
        ld      c, a
.have_row:
        ld      a, (ui_combo_popup_y)
        add     a, 2
        add     a, c
        ld      d, a
        ld      a, (ui_combo_popup_x)
        add     a, (iy + UI_COMBO_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_COMBO_SCROLL_THUMB_CHAR
        jp      ui_put_cell

ui_combo_redraw_scroll_column:
        ld      a, (ui_combo_popup_h)
        cp      3
        ret     c
        ld      b, a
        ld      a, (iy + UI_COMBO_COUNT)
        cp      b
        ret     z
        ret     c
        ld      a, (ui_combo_popup_x)
        add     a, (iy + UI_COMBO_W)
        dec     a
        ld      e, a
        ld      a, (ui_combo_popup_y)
        inc     a
        ld      d, a
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_COMBO_SCROLL_UP_CHAR
        push    de
        call    ui_put_cell
        pop     de
        ld      a, (ui_combo_popup_h)
        sub     2
        ld      c, a
        inc     d
.loop:
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_COMBO_SCROLL_TRACK_CHAR
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     d
        dec     c
        jr      nz, .loop
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, UI_COMBO_SCROLL_DOWN_CHAR
        call    ui_put_cell
        jp      ui_draw_combo_scroll

ui_clear_combo_popup:
        ld      a, (ui_combo_popup_x)
        ld      e, a
        ld      a, (ui_combo_popup_y)
        ld      d, a
        ld      a, (ui_combo_popup_h)
        add     a, 2
        ld      h, a
        ld      l, (iy + UI_COMBO_W)
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ret

ui_combo_attr_value:
        db      0
ui_combo_base_x:
        db      0
ui_combo_base_y:
        db      0
ui_combo_width:
        db      0
ui_combo_text_width:
        db      0
ui_combo_popup_x:
        db      0
ui_combo_popup_y:
        db      0
ui_combo_popup_h:
        db      0
ui_combo_popup_top:
        db      0
ui_combo_popup_selected:
        db      0
ui_combo_popup_old_selected:
        db      0
ui_combo_popup_old_top:
        db      0
ui_combo_popup_saved_selected:
        db      0
ui_combo_popup_saved_top:
        db      0
ui_combo_popup_row:
        db      0
