; ListBox: framed, scrollable, single-select list.
; Reuses the ScrollBar widget for the right-hand column and mirrors the
; ComboBox popup engine: only changed rows are repainted, and viewport
; shifts of one row use DSS Scroll instead of redrawing the whole list.
; Requires src/widgets/scrollbar.asm.

ui_lb_x:
        db      0
ui_lb_y:
        db      0
ui_lb_visible:
        db      0
ui_lb_rowi:
        db      0
ui_lb_rowattr:
        db      0
ui_lb_old_top:
        db      0
ui_lb_old_selected:
        db      0
ui_lb_saved_top:
        db      0
ui_lb_saved_selected:
        db      0

; ui_list_box_item
; In:  A = item index, IY = listbox descriptor
; Out: HL = pointer to item ASCIIZ
; Clobbers: AF, DE, HL
ui_list_box_item:
        ld      l, (iy + UI_LISTBOX_ITEMS)
        ld      h, (iy + UI_LISTBOX_ITEMS + 1)
        add     a, a
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        ret

; ui_draw_list_box
; Full draw: frame, all visible rows, scroll bar.
; In:  IX = parent window descriptor, IY = listbox descriptor
; Clobbers: AF, BC, DE, HL
ui_draw_list_box:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_LISTBOX_X)
        ld      (ui_lb_x), a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_LISTBOX_Y)
        ld      (ui_lb_y), a
        ld      a, (iy + UI_LISTBOX_H)
        sub     2
        ld      (ui_lb_visible), a
        call    ui_list_box_clamp
        call    ui_list_box_draw_frame
        ld      a, 0
        ld      (ui_lb_rowi), a
.row_loop:
        ld      a, (ui_lb_rowi)
        ld      b, a
        ld      a, (ui_lb_visible)
        cp      b
        jr      z, .rows_done
        call    ui_list_box_draw_row_at
        ld      a, (ui_lb_rowi)
        inc     a
        ld      (ui_lb_rowi), a
        jr      .row_loop
.rows_done:
        jp      ui_list_box_draw_scroll

; Clamp SELECTED into range and adjust TOP so SELECTED stays visible.
ui_list_box_clamp:
        ld      a, (iy + UI_LISTBOX_COUNT)
        or      a
        ret     z
        ld      b, a
        ld      a, (iy + UI_LISTBOX_SELECTED)
        cp      b
        jr      c, .sel_ok
        ld      a, b
        dec     a
        ld      (iy + UI_LISTBOX_SELECTED), a
.sel_ok:
        call    ui_list_box_make_visible
        jp      ui_list_box_clamp_top

; Adjust TOP so the SELECTED item is inside the viewport.
ui_list_box_make_visible:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        ld      b, a
        ld      a, (iy + UI_LISTBOX_TOP)
        cp      b
        jr      c, .check_bottom
        jr      z, .check_bottom
        ld      a, b                        ; selected < top -> top = selected
        ld      (iy + UI_LISTBOX_TOP), a
        jp      ui_list_box_clamp_top
.check_bottom:
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      c, a
        ld      a, b
        sub     c                           ; selected - top
        ld      c, a
        ld      a, (ui_lb_visible)
        cp      c
        jr      z, .scroll_down
        jp      nc, ui_list_box_clamp_top   ; already visible
.scroll_down:
        ld      a, b                        ; top = selected - visible + 1
        ld      c, a
        ld      a, (ui_lb_visible)
        ld      b, a
        ld      a, c
        sub     b
        inc     a
        ld      (iy + UI_LISTBOX_TOP), a
        jp      nc, ui_list_box_clamp_top
        xor     a
        ld      (iy + UI_LISTBOX_TOP), a
        ret

ui_list_box_clamp_top:
        ld      a, (iy + UI_LISTBOX_COUNT)
        ld      b, a
        ld      a, (ui_lb_visible)
        ld      c, a
        ld      a, b
        sub     c                           ; max_top = count - visible
        jr      nc, .have_max
        xor     a
.have_max:
        ld      b, a
        ld      a, (iy + UI_LISTBOX_TOP)
        cp      b
        ret     c
        ret     z
        ld      a, b
        ld      (iy + UI_LISTBOX_TOP), a
        ret

; Save SELECTED/TOP before a move so refresh can compute the delta.
ui_list_box_save_move:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        ld      (ui_lb_old_selected), a
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      (ui_lb_old_top), a
        ret

; Repaint only what changed after a selection move.
ui_list_box_refresh_after_move:
        ld      a, (ui_lb_old_top)
        ld      b, a
        ld      a, (iy + UI_LISTBOX_TOP)
        cp      b
        jr      z, .same_top
        ld      c, a                        ; new top
        ld      a, b
        inc     a
        cp      c
        jr      z, .scroll_up               ; new top = old + 1
        ld      a, c
        inc     a
        cp      b
        jr      z, .scroll_down             ; old top = new + 1
        jp      ui_draw_list_box            ; jumped further -> full redraw
.scroll_up:
        call    ui_list_box_unfocus_old
        ld      b, 1
        call    ui_list_box_scroll
        ld      a, (ui_lb_visible)
        dec     a
        ld      (ui_lb_rowi), a
        call    ui_list_box_draw_row_at
        jp      ui_list_box_draw_scroll
.scroll_down:
        call    ui_list_box_unfocus_old
        ld      b, 2
        call    ui_list_box_scroll
        xor     a
        ld      (ui_lb_rowi), a
        call    ui_list_box_draw_row_at
        jp      ui_list_box_draw_scroll
.same_top:
        ld      a, (ui_lb_old_selected)
        call    ui_list_box_draw_row_for_index
        ld      a, (iy + UI_LISTBOX_SELECTED)
        call    ui_list_box_draw_row_for_index
        jp      ui_list_box_draw_scroll

; Draw the row that currently shows item index A (no-op if off-screen).
ui_list_box_draw_row_for_index:
        ld      b, a
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      c, a
        ld      a, b
        sub     c
        ret     c                           ; above viewport
        ld      c, a
        ld      a, (ui_lb_visible)
        cp      c
        ret     c
        ret     z                           ; below viewport
        ld      a, c
        ld      (ui_lb_rowi), a
        jp      ui_list_box_draw_row_at

; Repaint the old selected row in normal colours before a DSS scroll so the
; highlight is not carried into the scrolled region.
ui_list_box_unfocus_old:
        ld      a, (ui_lb_old_selected)
        ld      b, a
        ld      a, (ui_lb_old_top)
        ld      c, a
        ld      a, b
        sub     c
        ret     c
        ld      c, a
        ld      a, (ui_lb_visible)
        cp      c
        ret     c
        ret     z
        ld      a, (iy + UI_LISTBOX_SELECTED)
        ld      (ui_lb_saved_selected), a
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      (ui_lb_saved_top), a
        ld      a, (ui_lb_old_top)
        ld      (iy + UI_LISTBOX_TOP), a
        ld      a, 0FFh
        ld      (iy + UI_LISTBOX_SELECTED), a
        ld      a, c
        ld      (ui_lb_rowi), a
        call    ui_list_box_draw_row_at
        ld      a, (ui_lb_saved_selected)
        ld      (iy + UI_LISTBOX_SELECTED), a
        ld      a, (ui_lb_saved_top)
        ld      (iy + UI_LISTBOX_TOP), a
        ret

; DSS scroll of the item text area by one row (the scroll bar column is left
; untouched). In: B = direction (1 up, 2 down).
ui_list_box_scroll:
        ld      a, b
        ld      (.dir), a
        ld      a, (ui_lb_y)
        inc     a
        ld      d, a
        ld      a, (ui_lb_x)
        inc     a
        ld      e, a
        ld      a, (ui_lb_visible)
        ld      h, a
        call    ui_lb_content_width
        ld      l, a
        ld      a, (.dir)
        ld      b, a
        push    ix
        push    iy
        xor     a                           ; blank the vacated line
        ld      c, Dss.Scroll
        call    ui_call_dss
        pop     iy
        pop     ix
        ret
.dir:
        db      0

; Width available for item text: inner width, minus the scroll bar column
; when the list overflows (so rows never paint under the scroll bar).
; Out: A = content width
ui_lb_content_width:
        ld      a, (ui_lb_visible)
        ld      b, a
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      b
        ld      a, (iy + UI_LISTBOX_W)
        sub     2
        ret     c                           ; count < visible -> no scroll bar
        ret     z                           ; count == visible -> no scroll bar
        dec     a                           ; reserve scroll bar column
        ret

; Draw one item row by screen offset (ui_lb_rowi).
ui_list_box_draw_row_at:
        ld      a, (ui_lb_rowi)
        ld      b, a
        ld      a, (ui_lb_visible)
        cp      b
        ret     c
        ret     z
        ld      a, (iy + UI_LISTBOX_TOP)
        add     a, b
        ld      c, a                        ; item index for this row
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      c
        jr      z, .blank
        jr      c, .blank
        ld      a, (iy + UI_LISTBOX_SELECTED)
        cp      c
        jr      z, .focused
        ld      a, (ui_theme_text_field)
        jr      .have_attr
.focused:
        ld      a, (ui_theme_menu_popup_focus)
.have_attr:
        ld      (ui_lb_rowattr), a
        call    ui_list_box_row_origin      ; D=row, E=col
        call    ui_lb_content_width
        ld      l, a
        ld      h, 1
        ld      a, (ui_lb_rowattr)
        ld      b, a
        ld      a, " "
        call    ui_fill_rect                ; clobbers BC: recompute the index next
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      b, a
        ld      a, (ui_lb_rowi)
        add     a, b
        call    ui_list_box_item            ; HL = string
        call    ui_list_box_row_origin
        call    ui_lb_content_width
        ld      b, a
        ld      a, (ui_lb_rowattr)
        jp      ui_lb_print_field
.blank:
        ld      a, (ui_theme_text_field)
        ld      (ui_lb_rowattr), a
        call    ui_list_box_row_origin
        call    ui_lb_content_width
        ld      l, a
        ld      h, 1
        ld      a, (ui_lb_rowattr)
        ld      b, a
        ld      a, " "
        jp      ui_fill_rect

; D = screen row, E = first text column for the current ui_lb_rowi.
ui_list_box_row_origin:
        ld      a, (ui_lb_y)
        inc     a
        ld      d, a
        ld      a, (ui_lb_rowi)
        add     a, d
        ld      d, a
        ld      a, (ui_lb_x)
        inc     a
        ld      e, a
        ret

; Print HL truncated/padded to a fixed field width.
; In: HL = ASCIIZ, D = row, E = col, A = attribute, B = width
; Clobbers: AF, BC, DE, HL
ui_lb_print_field:
        ld      (.attr), a
        ld      a, b
        ld      (.w), a
.loop:
        ld      a, (.w)
        or      a
        ret     z
        dec     a
        ld      (.w), a
        ld      a, (hl)
        or      a
        jr      nz, .havechar
        ld      a, " "
        jr      .emit
.havechar:
        inc     hl
.emit:
        push    hl
        push    de
        ld      c, a
        ld      a, (.attr)
        ld      b, a
        ld      a, c
        call    ui_put_cell
        pop     de
        pop     hl
        inc     e
        jr      .loop
.attr:
        db      0
.w:
        db      0

; Draw the single-line frame and clear the interior.
ui_list_box_draw_frame:
        ld      a, (ui_lb_y)
        ld      d, a
        ld      a, (ui_lb_x)
        ld      e, a
        ld      h, (iy + UI_LISTBOX_H)
        ld      l, (iy + UI_LISTBOX_W)
        ld      a, (ui_theme_text_field)
        ld      b, a
        ld      a, " "
        call    ui_fill_rect

        ld      a, (ui_lb_y)
        ld      d, a
        ld      a, (ui_lb_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0DAh
        call    ui_put_cell
        ld      a, (ui_lb_y)
        ld      d, a
        ld      a, (ui_lb_x)
        inc     a
        ld      e, a
        ld      a, (iy + UI_LISTBOX_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        call    ui_fill_rect
        ld      a, (ui_lb_y)
        ld      d, a
        ld      a, (ui_lb_x)
        add     a, (iy + UI_LISTBOX_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0BFh
        call    ui_put_cell

        ld      a, (iy + UI_LISTBOX_H)
        sub     2
        ld      c, a
        ld      a, (ui_lb_y)
        ld      d, a
.sides:
        inc     d
        ld      a, (ui_lb_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0B3h
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      a, (ui_lb_x)
        add     a, (iy + UI_LISTBOX_W)
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

        ld      a, (ui_lb_y)
        add     a, (iy + UI_LISTBOX_H)
        dec     a
        ld      d, a
        ld      a, (ui_lb_x)
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C0h
        call    ui_put_cell
        ld      a, (ui_lb_y)
        add     a, (iy + UI_LISTBOX_H)
        dec     a
        ld      d, a
        ld      a, (ui_lb_x)
        inc     a
        ld      e, a
        ld      a, (iy + UI_LISTBOX_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0C4h
        call    ui_fill_rect
        ld      a, (ui_lb_y)
        add     a, (iy + UI_LISTBOX_H)
        dec     a
        ld      d, a
        ld      a, (ui_lb_x)
        add     a, (iy + UI_LISTBOX_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, 0D9h
        jp      ui_put_cell

; Draw the scroll bar over the last inner column when the list overflows.
ui_list_box_draw_scroll:
        ld      a, (ui_lb_visible)
        ld      b, a
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      b
        ret     c
        ret     z
        ld      (ui_scroll_total), a
        ld      a, (ui_lb_visible)
        ld      (ui_scroll_visible), a
        ld      a, (iy + UI_LISTBOX_TOP)
        ld      (ui_scroll_top), a
        ld      a, (ui_lb_x)
        add     a, (iy + UI_LISTBOX_W)
        sub     2
        ld      e, a
        ld      a, (ui_lb_y)
        inc     a
        ld      d, a
        ld      a, (ui_lb_visible)
        ld      b, a
        jp      ui_draw_vscrollbar

; Hit-test the last mouse event.
; Out: NC, A = item index | UI_LIST_MOUSE_SCROLL_UP/DOWN/NO_ACTION ; CF = miss
; Clobbers: AF, BC, DE
ui_list_box_mouse_hit:
        ld      a, (ui_event_mouse_y)
        ld      c, a
        ld      a, (ui_lb_y)
        inc     a
        ld      b, a
        ld      a, c
        cp      b
        jr      c, .miss                    ; above the items
        sub     b
        ld      d, a                        ; D = row offset
        ld      a, (ui_lb_visible)
        cp      d
        jr      c, .miss
        jr      z, .miss                    ; below the items
        ld      a, (ui_event_mouse_x)
        ld      c, a
        ld      a, (ui_lb_x)
        inc     a
        ld      b, a
        ld      a, c
        cp      b
        jr      c, .miss                    ; on the left frame
        ld      a, (ui_lb_x)
        add     a, (iy + UI_LISTBOX_W)
        dec     a
        dec     a
        ld      e, a                        ; last inner column
        ld      a, c
        cp      e
        jr      z, .scrollcol
        jr      nc, .miss                   ; right frame or beyond
.item:
        ld      a, (iy + UI_LISTBOX_TOP)
        add     a, d
        ld      c, a
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      c
        jr      c, .miss
        jr      z, .miss
        ld      a, c
        or      a
        ret
.scrollcol:
        ld      a, (ui_lb_visible)
        ld      b, a
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      b
        jr      c, .item                    ; no scrollbar -> normal item cell
        jr      z, .item
        ld      a, d
        or      a
        jr      z, .sb_up
        ld      a, (ui_lb_visible)
        dec     a
        cp      d
        jr      z, .sb_down
        ld      a, UI_LIST_MOUSE_NO_ACTION
        or      a
        ret
.sb_up:
        ld      a, UI_LIST_MOUSE_SCROLL_UP
        or      a
        ret
.sb_down:
        ld      a, UI_LIST_MOUSE_SCROLL_DOWN
        or      a
        ret
.miss:
        scf
        ret

; ui_list_box_run
; Draw the list and run the modal selection loop (one-shot convenience).
; In:  IX = parent window descriptor, IY = listbox descriptor
; Out: NC and A = selected index on Enter/click; CF and A = UI_CMD_CANCEL on Esc
; Clobbers: AF, BC, DE, HL
ui_list_box_run:
        call    ui_draw_list_box
        ; fall through into the event loop

; ui_list_box_loop
; Event loop only; the list must already be drawn (ui_draw_list_box or a prior
; ui_list_box_run). Re-enter this after handling a commit to keep working on
; the same on-screen list without repainting it.
; In:  IY = listbox descriptor
; Out: NC and A = selected index on Enter/click; CF and A = UI_CMD_CANCEL on Esc
; Clobbers: AF, BC, DE, HL
ui_list_box_loop:
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
        cp      UI_KEY_ENTER
        jp      z, .accept
        cp      UI_KEY_SPACE
        jp      z, .accept
        cp      UI_KEY_ESCAPE
        jp      z, .cancel
        ld      a, (ui_event_scan)
        cp      UI_SCAN_DOWN
        jr      z, .down
        cp      50h
        jr      z, .down
        cp      72h
        jr      z, .down
        cp      UI_SCAN_UP
        jr      z, .up
        cp      48h
        jr      z, .up
        cp      75h
        jr      z, .up
        cp      UI_SCAN_HOME
        jp      z, .home
        cp      UI_SCAN_END
        jp      z, .end
        jr      .loop
.down:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        inc     a
        ld      b, a
        ld      a, (iy + UI_LISTBOX_COUNT)
        cp      b
        jp      z, .loop
        jp      c, .loop
        call    ui_list_box_save_move
        ld      a, b
        ld      (iy + UI_LISTBOX_SELECTED), a
        call    ui_list_box_make_visible
        call    ui_list_box_refresh_after_move
        jp      .loop
.up:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        or      a
        jp      z, .loop
        dec     a
        ld      b, a
        call    ui_list_box_save_move
        ld      a, b
        ld      (iy + UI_LISTBOX_SELECTED), a
        call    ui_list_box_make_visible
        call    ui_list_box_refresh_after_move
        jp      .loop
.home:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        or      a
        jp      z, .loop
        call    ui_list_box_save_move
        xor     a
        ld      (iy + UI_LISTBOX_SELECTED), a
        ld      (iy + UI_LISTBOX_TOP), a
        call    ui_list_box_refresh_after_move
        jp      .loop
.end:
        ld      a, (iy + UI_LISTBOX_COUNT)
        dec     a
        ld      b, a
        ld      a, (iy + UI_LISTBOX_SELECTED)
        cp      b
        jp      z, .loop
        call    ui_list_box_save_move
        ld      a, b
        ld      (iy + UI_LISTBOX_SELECTED), a
        call    ui_list_box_make_visible
        call    ui_list_box_refresh_after_move
        jp      .loop
.mouse:
        call    ui_list_box_mouse_hit
        jp      c, .loop
        cp      UI_LIST_MOUSE_SCROLL_UP
        jr      z, .up
        cp      UI_LIST_MOUSE_SCROLL_DOWN
        jr      z, .down
        cp      UI_LIST_MOUSE_NO_ACTION
        jp      z, .loop
        ; A = item index. Click on the current selection commits; otherwise
        ; move the selection with a partial redraw and stay in the loop.
        ld      b, a
        ld      a, (iy + UI_LISTBOX_SELECTED)
        cp      b
        jr      z, .accept
        call    ui_list_box_save_move
        ld      a, b
        ld      (iy + UI_LISTBOX_SELECTED), a
        call    ui_list_box_make_visible
        call    ui_list_box_refresh_after_move
        jp      .loop
.accept:
        ld      a, (iy + UI_LISTBOX_SELECTED)
        or      a                           ; CF = 0 (success)
        ret
.cancel:
        ld      a, UI_CMD_CANCEL
        scf
        ret
