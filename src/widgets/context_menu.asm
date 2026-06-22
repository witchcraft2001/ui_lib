; Context menu: open a dropdown-style popup at an arbitrary screen point and
; return the chosen command. Reuses the MenuBar popup engine (drawing,
; navigation, hotkey/selection state) with a synthetic menu item that points at
; the supplied popup table. Requires menu_bar.asm and window.asm.

; ui_context_menu_run
; In:  HL = popup item table (UI_MENU_POPUP_SIZE entries, UI_MENU_POPUP_END
;           terminated, same layout as a MenuBar dropdown)
;      D  = x, E = y  (preferred top-left corner; clamped to fit the screen)
; Out: A  = the selected item's command, or UI_CMD_NONE if cancelled
; Clobbers: AF, BC, DE, HL, IX, IY
ui_context_menu_run:
        ld      (ui_ctx_item + UI_MENU_ITEM_POPUP), hl
        ld      a, d
        ld      (ui_ctx_x), a
        ld      a, e
        ld      (ui_ctx_y), a
        xor     a
        ld      (ui_ctx_result), a          ; default = UI_CMD_NONE

        call    ui_ctx_calc_width
        ld      (ui_ctx_item + UI_MENU_ITEM_POPUP_W), a

        ld      hl, ui_ctx_item
        ld      (ui_menu_active_item_ptr), hl
        ld      (ui_menu_bar_ptr), hl       ; keep IX valid for shared routines

        ld      iy, ui_ctx_item
        call    ui_menu_popup_count
        ld      a, c
        or      a
        ret     z                           ; empty popup -> NONE
        ld      (ui_menu_popup_h), a
        ld      a, (ui_ctx_item + UI_MENU_ITEM_POPUP_W)
        ld      (ui_menu_popup_w), a
        call    ui_ctx_clamp_pos

        ld      iy, ui_ctx_item
        call    ui_menu_popup_first
        ld      (ui_menu_popup_selected), a
        ld      a, 1
        ld      (ui_menu_popup_open), a

        call    ui_ctx_save_under
        ld      iy, ui_ctx_item
        call    ui_menu_draw_popup_body
        call    ui_menu_update_popup_hint
        call    ui_ctx_loop

        xor     a
        ld      (ui_menu_popup_open), a
        call    ui_ctx_restore_under
        ld      a, (ui_ctx_result)
        ret

; Popup width = widest visible label + 2 (frame).
ui_ctx_calc_width:
        ld      hl, (ui_ctx_item + UI_MENU_ITEM_POPUP)
        ld      c, 0
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        jr      z, .done
        push    hl
        ld      de, UI_MENU_POPUP_LABEL
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        call    ui_ctx_label_width
        pop     hl
        cp      c
        jr      c, .nomax
        ld      c, a
.nomax:
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop
.done:
        ld      a, c
        add     a, 2
        ret

; Visible width of a label (skips a single '&' marker). In: HL=label. Out: A.
ui_ctx_label_width:
        ld      b, 0
.loop:
        ld      a, (hl)
        or      a
        jr      z, .done
        cp      "&"
        jr      z, .amp
        inc     b
        inc     hl
        jr      .loop
.amp:
        inc     hl
        ld      a, (hl)
        or      a
        jr      z, .done
        inc     b
        inc     hl
        jr      .loop
.done:
        ld      a, b
        ret

; Place the popup, clamping so it stays on screen.
ui_ctx_clamp_pos:
        ld      a, (ui_ctx_x)
        ld      b, a
        ld      a, (ui_menu_popup_w)
        add     a, b
        cp      UI_SCREEN_COLS + 1
        jr      c, .x_ok
        ld      a, UI_SCREEN_COLS
        ld      b, a
        ld      a, (ui_menu_popup_w)
        ld      c, a
        ld      a, b
        sub     c
        ld      (ui_menu_popup_x), a
        jr      .y
.x_ok:
        ld      a, (ui_ctx_x)
        ld      (ui_menu_popup_x), a
.y:
        ld      a, (ui_menu_popup_h)
        add     a, 2
        ld      c, a                        ; total height incl. frame
        ld      a, (ui_ctx_y)
        add     a, c
        cp      UI_SCREEN_ROWS + 1
        jr      c, .y_ok
        ld      a, UI_SCREEN_ROWS
        sub     c
        ld      (ui_menu_popup_y), a
        ret
.y_ok:
        ld      a, (ui_ctx_y)
        ld      (ui_menu_popup_y), a
        ret

; Modal loop with continuous mouse tracking. The menu stays open after the
; opening click (its release is ignored): the highlight follows the cursor as
; it moves over items, clicking an item commits it, clicking outside dismisses
; the menu, and the keyboard works in parallel. Result -> ui_ctx_result.
ui_ctx_loop:
        call    ui_ctx_read_mouse           ; seed previous button / position
        jr      c, .no_seed
        ld      (ui_ctx_prevbtn), a
        ld      a, (ui_event_mouse_x)
        ld      (ui_ctx_lastx), a
        ld      a, (ui_event_mouse_y)
        ld      (ui_ctx_lasty), a
        jr      .loop
.no_seed:
        xor     a
        ld      (ui_ctx_prevbtn), a
.loop:
        call    ui_ctx_read_mouse
        jp      c, .keyboard                ; no mouse -> keyboard only
        and     03h
        ld      (ui_ctx_curbtn), a

        ; hover-highlight only when the cursor actually moved
        ld      a, (ui_event_mouse_x)
        ld      hl, ui_ctx_lastx
        cp      (hl)
        jr      nz, .moved
        ld      a, (ui_event_mouse_y)
        ld      hl, ui_ctx_lasty
        cp      (hl)
        jr      z, .edge
.moved:
        ld      a, (ui_event_mouse_x)
        ld      (ui_ctx_lastx), a
        ld      a, (ui_event_mouse_y)
        ld      (ui_ctx_lasty), a
        call    ui_ctx_hit_row
        jr      c, .edge
        ld      a, (ui_menu_popup_selected)
        cp      c
        jr      z, .edge
        ld      (ui_menu_old_popup_selected), a
        ld      a, c
        ld      (ui_menu_popup_selected), a
        call    ui_menu_redraw_popup_selection
.edge:
        ld      a, (ui_ctx_prevbtn)         ; press edge: was up, now down
        or      a
        jr      nz, .store                  ; was already down (incl. the opening
                                            ; click) -> ignore until released
        ld      a, (ui_ctx_curbtn)
        or      a
        jr      z, .store
        call    ui_ctx_hit_row
        jp      nc, .commit_row             ; clicked an item
        or      a
        jr      z, .cancel                  ; clicked outside -> dismiss
        ; clicked a separator/disabled row -> stay open
.store:
        ld      a, (ui_ctx_curbtn)
        ld      (ui_ctx_prevbtn), a
.keyboard:
        ld      c, Dss.CtrlKey
        rst     10h
        or      a
        jr      z, .idle
        ld      c, Dss.ScanKey
        rst     10h
        ld      (ui_event_key), a
        ld      a, d
        ld      (ui_event_scan), a
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jr      z, .cancel
        cp      UI_KEY_ENTER
        jr      z, .commit_sel
        cp      UI_KEY_SPACE
        jr      z, .commit_sel
        ld      a, (ui_event_scan)
        cp      UI_SCAN_UP
        jr      z, .up
        cp      48h
        jr      z, .up
        cp      75h
        jr      z, .up
        cp      UI_SCAN_DOWN
        jr      z, .down
        cp      50h
        jr      z, .down
        cp      72h
        jr      z, .down
        ld      a, (ui_event_key)
        call    ui_ctx_find_hotkey
        jp      nc, .commit_sel
.idle:
        halt
        jp      .loop
.up:
        call    ui_menu_popup_prev
        jp      .loop
.down:
        call    ui_menu_popup_next
        jp      .loop
.commit_row:
        ld      a, c
        ld      (ui_menu_popup_selected), a
.commit_sel:
        ld      iy, ui_ctx_item
        ld      a, (ui_menu_popup_selected)
        call    ui_menu_find_popup_item
        jr      c, .idle
        bit     2, (hl)
        jr      nz, .idle
        bit     7, (hl)
        jr      nz, .idle
        ld      de, UI_MENU_POPUP_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_ctx_result), a
        ret
.cancel:
        xor     a
        ld      (ui_ctx_result), a
        ret

; Match the key against item hotkeys. Out: CF=0 and selection set on a match.
ui_ctx_find_hotkey:
        ld      (ui_ctx_keytmp), a
        ld      hl, (ui_ctx_item + UI_MENU_ITEM_POPUP)
        ld      c, 0
.loop:
        ld      a, (hl)
        cp      UI_MENU_POPUP_END
        jr      z, .none
        bit     2, (hl)
        jr      nz, .next
        bit     7, (hl)
        jr      nz, .next
        push    hl
        ld      de, UI_MENU_POPUP_HOTKEY
        add     hl, de
        ld      a, (hl)
        pop     hl
        or      a
        jr      z, .next
        ld      b, a
        ld      a, (ui_ctx_keytmp)
        call    ui_menu_fold_ascii
        ld      d, a
        ld      a, b
        call    ui_menu_fold_ascii
        cp      d
        jr      nz, .next
        ld      a, c
        ld      (ui_menu_popup_selected), a
        or      a
        ret
.next:
        inc     c
        ld      de, UI_MENU_POPUP_SIZE
        add     hl, de
        jr      .loop
.none:
        scf
        ret

; Read the mouse. Out: A = buttons (bit0 left, bit1 right) and ui_event_mouse_x/y
; in cells, CF=0; CF=1 if the mouse is unavailable.
ui_ctx_read_mouse:
        ld      a, (ui_mouse_available)
        or      a
        jr      z, .fail
        ld      a, Bios.Mouse_Read
        ld      c, a
        rst     30h
        ret     c
        push    af
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a, l
        ld      (ui_event_mouse_x), a
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        ld      a, e
        ld      (ui_event_mouse_y), a
        pop     af
        and     03h
        ret
.fail:
        scf
        ret

; Hit-test the popup against the current cursor cell.
; Out: CF=0 and C = row index on a selectable row; CF=1 with A=0 outside,
;      A=1 on a separator/disabled row. (find_popup_item keeps C.)
ui_ctx_hit_row:
        ld      a, (ui_event_mouse_x)
        ld      c, a
        ld      a, (ui_menu_popup_x)
        inc     a
        ld      b, a
        ld      a, c
        cp      b
        jr      c, .outside
        ld      a, (ui_menu_popup_w)
        ld      b, a
        ld      a, (ui_menu_popup_x)
        add     a, b
        dec     a
        ld      b, a
        ld      a, c
        cp      b
        jr      nc, .outside
        ld      a, (ui_event_mouse_y)
        ld      c, a
        ld      a, (ui_menu_popup_y)
        inc     a
        ld      b, a
        ld      a, c
        cp      b
        jr      c, .outside
        sub     b
        ld      c, a                        ; C = row index
        ld      a, (ui_menu_popup_h)
        cp      c
        jr      c, .outside
        jr      z, .outside
        ld      a, c
        ld      iy, ui_ctx_item
        call    ui_menu_find_popup_item
        jr      c, .dead
        bit     2, (hl)
        jr      nz, .dead
        bit     7, (hl)
        jr      nz, .dead
        or      a
        ret
.dead:
        ld      a, 1
        scf
        ret
.outside:
        xor     a
        scf
        ret

; Background save/restore for the popup rectangle (reuses the menu scratch).
ui_ctx_save_under:
        xor     a
        ld      (ui_menu_popup_saved), a
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      a, (ui_menu_popup_x)
        ld      (ui_menu_popup_save_desc + UI_WINDOW_X), a
        ld      a, (ui_menu_popup_y)
        ld      (ui_menu_popup_save_desc + UI_WINDOW_Y), a
        ld      a, (ui_menu_popup_w)
        ld      (ui_menu_popup_save_desc + UI_WINDOW_W), a
        ld      a, (ui_menu_popup_h)
        add     a, 2
        ld      (ui_menu_popup_save_desc + UI_WINDOW_H), a
        ld      ix, ui_menu_popup_save_desc
        call    ui_window_save_under
        ret     c
        ld      a, 1
        ld      (ui_menu_popup_saved), a
        ENDIF
        ret

ui_ctx_restore_under:
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      a, (ui_menu_popup_saved)
        or      a
        ret     z
        xor     a
        ld      (ui_menu_popup_saved), a
        call    ui_window_restore_under
        ENDIF
        ret

ui_ctx_x:
        db      0
ui_ctx_y:
        db      0
ui_ctx_result:
        db      0
ui_ctx_keytmp:
        db      0
ui_ctx_prevbtn:
        db      0
ui_ctx_curbtn:
        db      0
ui_ctx_lastx:
        db      0
ui_ctx_lasty:
        db      0
ui_ctx_item:
        ds      UI_MENU_ITEM_SIZE, 0
