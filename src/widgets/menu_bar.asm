; Menu bar and dropdown drawing.

; ui_menu_bar_run
; In:  IX=menu bar descriptor
; Out: A=command from selected popup item, or UI_CMD_NONE on Esc/outside click
; Clobbers: AF, BC, DE, HL, IX, IY
ui_menu_bar_run:
        ld      (ui_menu_bar_ptr), ix
        call    ui_draw_menu_bar
        call    ui_menu_count_items
        ld      (ui_menu_item_count_value), a
        or      a
        jr      nz, .has_items
        ld      a, UI_CMD_NONE
        ret
.has_items:
        xor     a
        ld      (ui_menu_focus_index), a
        ld      (ui_menu_popup_open), a
        call    ui_menu_draw_focus
.loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      z, .key
        cp      UI_EVENT_MOUSE
        jr      z, .mouse
        jr      .loop

.key:
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jr      z, .cancel
        cp      UI_KEY_ENTER
        jr      z, .commit
        cp      UI_KEY_SPACE
        jr      z, .commit
        ld      a, (ui_event_scan)
        cp      UI_SCAN_RIGHT
        jr      z, .next_menu
        cp      4Dh
        jr      z, .next_menu
        cp      UI_SCAN_LEFT
        jr      z, .prev_menu
        cp      4Bh
        jr      z, .prev_menu
        cp      UI_SCAN_DOWN
        jr      z, .next_popup
        cp      50h
        jr      z, .next_popup
        cp      72h
        jr      z, .next_popup
        cp      UI_SCAN_UP
        jr      z, .prev_popup
        cp      48h
        jr      z, .prev_popup
        cp      75h
        jr      z, .prev_popup
        call    ui_menu_popup_hotkey
        jr      nc, .done
        call    ui_menu_top_hotkey
        jr      .loop
.next_menu:
        call    ui_menu_focus_next
        jr      .loop
.prev_menu:
        call    ui_menu_focus_prev
        jr      .loop
.next_popup:
        call    ui_menu_popup_next
        jr      .loop
.prev_popup:
        call    ui_menu_popup_prev
        jr      .loop
.commit:
        ld      a, (ui_menu_popup_open)
        or      a
        jr      nz, .commit_open
        call    ui_menu_open_popup
        jr      .loop
.commit_open:
        call    ui_menu_commit_selected
        jr      c, .loop
.done:
        ret

.mouse:
        call    ui_menu_mouse
        jr      c, .loop
        ret

.cancel:
        ld      a, (ui_menu_popup_open)
        or      a
        jr      z, .cancel_menu
        call    ui_menu_close_popup
        jp      .loop
.cancel_menu:
        call    ui_menu_clear_focus
        ld      a, UI_CMD_NONE
        ret

; ui_draw_menu_bar
; In:  IX=menu bar descriptor
; Out: none
; Clobbers: AF, BC, DE, HL, IY
ui_draw_menu_bar:
        ld      d, (ix + UI_MENU_BAR_Y)
        ld      e, (ix + UI_MENU_BAR_X)
        ld      h, 1
        ld      l, (ix + UI_MENU_BAR_W)
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ld      l, (ix + UI_MENU_BAR_ITEMS)
        ld      h, (ix + UI_MENU_BAR_ITEMS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_MENU_ITEMS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        xor     a
        call    ui_draw_menu_bar_item
        pop     ix
        pop     hl
        ld      de, UI_MENU_ITEM_SIZE
        add     hl, de
        jr      .loop

; ui_draw_menu_dropdown
; In:  IX=menu bar descriptor, IY=menu bar item descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_menu_dropdown:
        call    ui_menu_popup_count
        ld      a, c
        or      a
        ret     z
        ld      (ui_menu_popup_h), a
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        ld      (ui_menu_popup_x), a
        ld      e, a
        ld      a, (ix + UI_MENU_BAR_Y)
        inc     a
        ld      (ui_menu_popup_y), a
        ld      d, a
        ld      a, (ui_menu_popup_h)
        add     a, 2
        ld      h, a
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        ld      (ui_menu_popup_w), a
        ld      l, a
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        call    ui_draw_menu_popup_frame
        xor     a
        ld      (ui_menu_popup_row), a
        ld      l, (iy + UI_MENU_ITEM_POPUP)
        ld      h, (iy + UI_MENU_ITEM_POPUP + 1)
.row:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        ret     z
        push    hl
        bit     2, (hl)
        jr      nz, .separator
        ld      a, (ui_menu_popup_row)
        ld      b, a
        ld      a, (ui_menu_popup_selected)
        cp      b
        jr      z, .focused_row
        ld      a, (ui_theme_window)
        jr      .row_attr
.focused_row:
        ld      a, (ui_theme_button_focus)
.row_attr:
        ld      (ui_menu_attr), a
        call    ui_menu_set_hotkey_attr
        ld      de, UI_MENU_POPUP_LABEL
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     hl
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, (ui_menu_popup_row)
        add     a, b
        ld      d, a
        call    ui_menu_print_label
        jr      .next
.separator:
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, (ui_menu_popup_row)
        add     a, b
        ld      d, a
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        sub     2
        ld      c, a
.sep_loop:
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     e
        dec     c
        jr      nz, .sep_loop
.next:
        pop     hl
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        ld      a, (ui_menu_popup_row)
        inc     a
        ld      (ui_menu_popup_row), a
        jr      .row

; ui_clear_menu_dropdown
; In:  IX=menu bar descriptor, IY=menu bar item descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_clear_menu_dropdown:
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        ld      (ui_menu_popup_x), a
        ld      e, a
        ld      a, (ix + UI_MENU_BAR_Y)
        inc     a
        ld      (ui_menu_popup_y), a
        ld      d, a
        call    ui_menu_popup_count
        ld      a, c
        ld      (ui_menu_popup_h), a
        add     a, 2
        ld      h, a
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        ld      (ui_menu_popup_w), a
        ld      l, a
        jr      ui_clear_menu_dropdown_area

ui_clear_menu_dropdown_state:
        ld      a, (ui_menu_popup_x)
        ld      e, a
        ld      a, (ui_menu_popup_y)
        ld      d, a
        ld      a, (ui_menu_popup_h)
        add     a, 2
        ld      h, a
        ld      a, (ui_menu_popup_w)
        ld      l, a
ui_clear_menu_dropdown_area:
        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ret

; ui_draw_menu_bar_item
; In:  IX=menu bar descriptor, IY=menu item descriptor, A=0 normal / nonzero focused
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_menu_bar_item:
        or      a
        jr      nz, .focused
        ld      a, (ui_theme_window)
        jr      .have_attr
.focused:
        ld      a, (ui_theme_button_focus)
.have_attr:
        ld      (ui_menu_attr), a
        call    ui_menu_set_hotkey_attr
        ld      a, (ix + UI_MENU_BAR_Y)
        ld      d, a
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        ld      e, a
        ld      a, " "
        call    ui_menu_put
        inc     e
        ld      l, (iy + UI_MENU_ITEM_LABEL)
        ld      h, (iy + UI_MENU_ITEM_LABEL + 1)
        call    ui_menu_print_label
        ld      a, " "
        jp      ui_menu_put

ui_menu_popup_count:
        ld      l, (iy + UI_MENU_ITEM_POPUP)
        ld      h, (iy + UI_MENU_ITEM_POPUP + 1)
        ld      c, 0
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        ret     z
        inc     c
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop

ui_menu_count_items:
        ld      l, (ix + UI_MENU_BAR_ITEMS)
        ld      h, (ix + UI_MENU_BAR_ITEMS + 1)
        ld      c, 0
        ld      a, h
        or      l
        jr      z, .done
.loop:
        ld      a, (hl)
        cp      UI_MENU_ITEMS_END
        jr      z, .done
        inc     c
        ld      de, UI_MENU_ITEM_SIZE
        add     hl, de
        jr      .loop
.done:
        ld      a, c
        ret

ui_menu_find_item:
        ld      l, (ix + UI_MENU_BAR_ITEMS)
        ld      h, (ix + UI_MENU_BAR_ITEMS + 1)
        ld      b, a
        ld      a, h
        or      l
        jr      z, .missing
.loop:
        ld      a, (hl)
        cp      UI_MENU_ITEMS_END
        jr      z, .missing
        ld      a, b
        or      a
        jr      z, .found
        dec     b
        ld      de, UI_MENU_ITEM_SIZE
        add     hl, de
        jr      .loop
.found:
        push    hl
        pop     iy
        or      a
        ret
.missing:
        scf
        ret

ui_menu_draw_focus:
        ld      ix, (ui_menu_bar_ptr)
        ld      a, (ui_menu_focus_index)
        call    ui_menu_find_item
        ret     c
        push    iy
        pop     hl
        ld      (ui_menu_active_item_ptr), hl
        ld      a, 1
        jp      ui_draw_menu_bar_item

ui_menu_clear_focus:
        ld      ix, (ui_menu_bar_ptr)
        ld      iy, (ui_menu_active_item_ptr)
        xor     a
        jp      ui_draw_menu_bar_item

ui_menu_open_popup:
        ld      a, (ui_menu_popup_open)
        or      a
        ret     nz
        ld      ix, (ui_menu_bar_ptr)
        ld      iy, (ui_menu_active_item_ptr)
        call    ui_menu_popup_first
        ld      (ui_menu_popup_selected), a
        ld      a, 1
        ld      (ui_menu_popup_open), a
        jp      ui_draw_menu_dropdown

ui_menu_close_popup:
        ld      a, (ui_menu_popup_open)
        or      a
        ret     z
        call    ui_clear_menu_dropdown_state
        xor     a
        ld      (ui_menu_popup_open), a
        ret

ui_menu_focus_next:
        ld      a, (ui_menu_popup_open)
        ld      (ui_menu_keep_popup), a
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, (ui_menu_focus_index)
        inc     a
        ld      b, a
        ld      a, (ui_menu_item_count_value)
        cp      b
        jr      nz, .store
        ld      b, 0
.store:
        ld      a, b
        ld      (ui_menu_focus_index), a
        call    ui_menu_draw_focus
        ld      a, (ui_menu_keep_popup)
        or      a
        ret     z
        jp      ui_menu_open_popup

ui_menu_focus_prev:
        ld      a, (ui_menu_popup_open)
        ld      (ui_menu_keep_popup), a
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, (ui_menu_focus_index)
        or      a
        jr      nz, .dec
        ld      a, (ui_menu_item_count_value)
.dec:
        dec     a
        ld      (ui_menu_focus_index), a
        call    ui_menu_draw_focus
        ld      a, (ui_menu_keep_popup)
        or      a
        ret     z
        jp      ui_menu_open_popup

ui_menu_redraw_popup:
        ld      ix, (ui_menu_bar_ptr)
        ld      iy, (ui_menu_active_item_ptr)
        jp      ui_draw_menu_dropdown

ui_menu_redraw_popup_selection:
        ld      ix, (ui_menu_bar_ptr)
        ld      iy, (ui_menu_active_item_ptr)
        ld      a, (ui_menu_old_popup_selected)
        call    ui_menu_draw_popup_row_by_index
        ld      a, (ui_menu_popup_selected)
        jp      ui_menu_draw_popup_row_by_index

ui_menu_draw_popup_row_by_index:
        ld      (ui_menu_popup_row), a
        call    ui_menu_find_popup_item
        ret     c
        push    hl
        bit     2, (hl)
        jr      nz, .separator
        ld      a, (ui_menu_popup_row)
        ld      b, a
        ld      a, (ui_menu_popup_selected)
        cp      b
        jr      z, .focused_row
        ld      a, (ui_theme_window)
        jr      .row_attr
.focused_row:
        ld      a, (ui_theme_button_focus)
.row_attr:
        ld      (ui_menu_attr), a
        call    ui_menu_set_hotkey_attr
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, (ui_menu_popup_row)
        add     a, b
        ld      d, a
        ld      h, 1
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        sub     2
        ld      l, a
        ld      a, " "
        push    af
        ld      a, (ui_menu_attr)
        ld      b, a
        pop     af
        call    ui_fill_rect
        pop     hl
        ld      de, UI_MENU_POPUP_LABEL
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     hl
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, (ui_menu_popup_row)
        add     a, b
        ld      d, a
        jp      ui_menu_print_label
.separator:
        pop     hl
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      e, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, (ui_menu_popup_row)
        add     a, b
        ld      d, a
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        sub     2
        ld      c, a
.sep_loop:
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     e
        dec     c
        jr      nz, .sep_loop
        ret

ui_menu_popup_first:
        ld      l, (iy + UI_MENU_ITEM_POPUP)
        ld      h, (iy + UI_MENU_ITEM_POPUP + 1)
        ld      c, 0
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        jr      z, .none
        bit     2, (hl)
        jr      z, .found
        inc     c
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop
.found:
        ld      a, c
        ret
.none:
        xor     a
        ret

ui_menu_find_popup_item:
        ld      l, (iy + UI_MENU_ITEM_POPUP)
        ld      h, (iy + UI_MENU_ITEM_POPUP + 1)
        ld      b, a
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        jr      z, .missing
        ld      a, b
        or      a
        ret     z
        dec     b
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop
.missing:
        scf
        ret

ui_menu_popup_next:
        ld      a, (ui_menu_popup_open)
        or      a
        ret     z
        ld      iy, (ui_menu_active_item_ptr)
        call    ui_menu_popup_count
        ld      a, c
        or      a
        ret     z
        ld      b, a
        ld      a, (ui_menu_popup_selected)
.loop:
        inc     a
        cp      b
        jr      nz, .check
        xor     a
.check:
        push    af
        call    ui_menu_find_popup_item
        pop     af
        ret     c
        bit     2, (hl)
        jr      nz, .loop
        ld      b, a
        ld      a, (ui_menu_popup_selected)
        ld      (ui_menu_old_popup_selected), a
        ld      a, b
        ld      (ui_menu_popup_selected), a
        jp      ui_menu_redraw_popup_selection

ui_menu_popup_prev:
        ld      a, (ui_menu_popup_open)
        or      a
        ret     z
        ld      iy, (ui_menu_active_item_ptr)
        call    ui_menu_popup_count
        ld      a, c
        or      a
        ret     z
        ld      b, a
        ld      a, (ui_menu_popup_selected)
.loop:
        or      a
        jr      nz, .dec
        ld      a, b
.dec:
        dec     a
        push    af
        call    ui_menu_find_popup_item
        pop     af
        ret     c
        bit     2, (hl)
        jr      nz, .loop
        ld      b, a
        ld      a, (ui_menu_popup_selected)
        ld      (ui_menu_old_popup_selected), a
        ld      a, b
        ld      (ui_menu_popup_selected), a
        jp      ui_menu_redraw_popup_selection

ui_menu_commit_selected:
        ld      a, (ui_menu_popup_open)
        or      a
        jr      nz, .open
        call    ui_menu_open_popup
        scf
        ret
.open:
        ld      iy, (ui_menu_active_item_ptr)
        ld      a, (ui_menu_popup_selected)
        call    ui_menu_find_popup_item
        ret     c
        bit     2, (hl)
        jr      nz, .ignore
        ld      de, UI_MENU_POPUP_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_menu_command), a
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, (ui_menu_command)
        or      a
        ret
.ignore:
        scf
        ret

ui_menu_popup_hotkey:
        ld      a, (ui_menu_popup_open)
        or      a
        jr      nz, .open
        scf
        ret
.open:
        ld      iy, (ui_menu_active_item_ptr)
        ld      l, (iy + UI_MENU_ITEM_POPUP)
        ld      h, (iy + UI_MENU_ITEM_POPUP + 1)
        ld      c, 0
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        jr      z, .missing
        bit     2, (hl)
        jr      nz, .next
        inc     hl
        ld      a, (ui_event_key)
        cp      (hl)
        dec     hl
        jr      z, .hit
.next:
        inc     c
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, c
        ld      (ui_menu_popup_selected), a
        jp      ui_menu_commit_selected
.missing:
        scf
        ret

ui_menu_top_hotkey:
        ld      ix, (ui_menu_bar_ptr)
        ld      l, (ix + UI_MENU_BAR_ITEMS)
        ld      h, (ix + UI_MENU_BAR_ITEMS + 1)
        ld      c, 0
.loop:
        ld      a, (hl)
        cp      UI_MENU_ITEMS_END
        ret     z
        ld      de, UI_MENU_ITEM_HOTKEY
        push    hl
        add     hl, de
        ld      a, (ui_event_key)
        cp      (hl)
        pop     hl
        jr      z, .hit
        inc     c
        ld      de, UI_MENU_ITEM_SIZE
        add     hl, de
        jr      .loop
.hit:
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, c
        ld      (ui_menu_focus_index), a
        call    ui_menu_draw_focus
        jp      ui_menu_open_popup

ui_menu_mouse:
        ld      ix, (ui_menu_bar_ptr)
        ld      a, (ui_event_mouse_y)
        cp      (ix + UI_MENU_BAR_Y)
        jr      z, ui_menu_mouse_bar
        ld      a, (ui_menu_popup_open)
        or      a
        jr      z, .outside
        ld      iy, (ui_menu_active_item_ptr)
        ld      a, (ui_event_mouse_x)
        ld      b, a
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        cp      b
        jr      nc, .outside
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        ld      c, a
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        add     a, c
        cp      b
        jr      c, .outside
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ix + UI_MENU_BAR_Y)
        inc     a
        cp      b
        jr      nc, .outside
        push    bc
        call    ui_menu_popup_count
        pop     bc
        ld      a, (ix + UI_MENU_BAR_Y)
        inc     a
        add     a, c
        inc     a
        cp      b
        jr      c, .outside
        ld      a, b
        sub     (ix + UI_MENU_BAR_Y)
        sub     2
        ld      (ui_menu_popup_selected), a
        call    ui_menu_commit_selected
        ret     nc
        scf
        ret
.outside:
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, UI_CMD_NONE
        or      a
        ret

ui_menu_mouse_bar:
        ld      a, (ui_event_mouse_x)
        ld      (ui_menu_mouse_x), a
        ld      l, (ix + UI_MENU_BAR_ITEMS)
        ld      h, (ix + UI_MENU_BAR_ITEMS + 1)
        xor     a
        ld      (ui_menu_candidate_index), a
.loop:
        ld      a, (hl)
        cp      UI_MENU_ITEMS_END
        jr      z, .ignore
        push    hl
        push    hl
        pop     iy
        ld      a, (ix + UI_MENU_BAR_X)
        add     a, (iy + UI_MENU_ITEM_X)
        ld      (ui_menu_item_left), a
        ld      b, a
        ld      a, (ui_menu_mouse_x)
        cp      b
        jr      c, .next_pop
        ld      l, (iy + UI_MENU_ITEM_LABEL)
        ld      h, (iy + UI_MENU_ITEM_LABEL + 1)
        call    ui_menu_visible_width
        ld      a, (ui_menu_item_left)
        add     a, d
        add     a, 2
        ld      (ui_menu_item_right), a
        ld      b, a
        ld      a, (ui_menu_mouse_x)
        cp      b
        jr      c, .hit
.next_pop:
        pop     hl
        ld      a, (ui_menu_candidate_index)
        inc     a
        ld      (ui_menu_candidate_index), a
        ld      de, UI_MENU_ITEM_SIZE
        add     hl, de
        jr      .loop
.hit:
        pop     hl
        call    ui_menu_close_popup
        call    ui_menu_clear_focus
        ld      a, (ui_menu_candidate_index)
        ld      (ui_menu_focus_index), a
        call    ui_menu_draw_focus
        call    ui_menu_open_popup
.ignore:
        scf
        ret

ui_menu_visible_width:
        ld      d, 0
.loop:
        ld      a, (hl)
        or      a
        ret     z
        cp      "&"
        jr      z, .skip_marker
        inc     d
        inc     hl
        jr      .loop
.skip_marker:
        inc     hl
        ld      a, (hl)
        or      a
        ret     z
        inc     d
        inc     hl
        jr      .loop

ui_draw_menu_popup_frame:
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, (ui_menu_popup_y)
        ld      d, a
        ld      a, (ui_menu_popup_x)
        ld      e, a
        ld      a, 0DAh
        push    de
        call    ui_put_cell
        pop     de
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, (ui_theme_window)
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
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BFh
        call    ui_put_cell

        ld      a, (ui_menu_popup_h)
        ld      c, a
.sides:
        ld      a, (ui_menu_popup_y)
        ld      d, a
        ld      a, (ui_menu_popup_h)
        sub     c
        inc     a
        add     a, d
        ld      d, a
        ld      a, (ui_menu_popup_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      e, (iy + UI_MENU_ITEM_POPUP_W)
        dec     e
        ld      a, (ui_menu_popup_x)
        add     a, e
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

        ld      a, (ui_menu_popup_y)
        ld      d, a
        ld      a, (ui_menu_popup_h)
        inc     a
        add     a, d
        ld      d, a
        ld      a, (ui_menu_popup_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C0h
        push    de
        call    ui_put_cell
        pop     de
        ld      a, (iy + UI_MENU_ITEM_POPUP_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, (ui_theme_window)
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
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0D9h
        jp      ui_put_cell

ui_menu_print_label:
        ld      a, (hl)
        or      a
        ret     z
        cp      "&"
        jr      nz, .normal
        inc     hl
        ld      a, (hl)
        or      a
        ret     z
        push    hl
        push    de
        ld      (ui_menu_char), a
        ld      a, (ui_menu_hotkey_attr)
        ld      b, a
        ld      a, (ui_menu_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      ui_menu_print_label
.normal:
        push    hl
        push    de
        call    ui_menu_put
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      ui_menu_print_label

ui_menu_put:
        push    af
        ld      a, (ui_menu_attr)
        ld      b, a
        pop     af
        call    ui_put_cell
        ret

ui_menu_set_hotkey_attr:
        ld      a, (ui_menu_attr)
        and     0F0h
        or      0Eh
        ld      (ui_menu_hotkey_attr), a
        ret

ui_menu_attr:
        db      0
ui_menu_hotkey_attr:
        db      0
ui_menu_char:
        db      0
ui_menu_popup_x:
        db      0
ui_menu_popup_y:
        db      0
ui_menu_popup_w:
        db      0
ui_menu_popup_h:
        db      0
ui_menu_popup_row:
        db      0
ui_menu_bar_ptr:
        dw      0
ui_menu_active_item_ptr:
        dw      0
ui_menu_focus_index:
        db      0
ui_menu_item_count_value:
        db      0
ui_menu_popup_selected:
        db      0
ui_menu_old_popup_selected:
        db      0
ui_menu_popup_open:
        db      0
ui_menu_keep_popup:
        db      0
ui_menu_mouse_x:
        db      0
ui_menu_candidate_index:
        db      0
ui_menu_item_left:
        db      0
ui_menu_item_right:
        db      0
ui_menu_command:
        db      UI_CMD_NONE
