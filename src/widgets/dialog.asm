; Modal dialog loop with focus navigation.

        IFNDEF UI_ENABLE_HINTS
UI_ENABLE_HINTS equ 0
        ENDIF

ui_dialog_active:
        dw      0
ui_dialog_focus_index:
        db      0
ui_dialog_focus_count:
        db      0
ui_dialog_current_index:
        db      0
ui_dialog_target_index:
        db      0
ui_dialog_handled:
        db      0
ui_dialog_last_focus_index:
        db      0FFh
ui_dialog_old_focus_index:
        db      0FFh
ui_dialog_blink_counter:
        db      16

; ui_dialog_run
; In:  IX=dialog descriptor
; Out: A=command
; Clobbers: AF, BC, DE, HL, IX, IY
ui_dialog_run:
        ld      (ui_dialog_active), ix
        ld      hl, ui_dialog_idle
        ld      (ui_idle_hook), hl
        call    ui_dialog_clear_focus
        call    ui_dialog_draw_all
        call    ui_dialog_count_focus
        ld      (ui_dialog_focus_count), a
        or      a
        jr      z, .loop
        ld      a, 0FFh
        ld      (ui_dialog_last_focus_index), a
        xor     a
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
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
        cp      UI_KEY_TAB
        jr      z, .tab
        cp      UI_KEY_ENTER
        jr      z, .activate
        call    ui_dialog_text_key
        jr      c, .loop
        ld      a, (ui_event_key)
        cp      UI_KEY_SPACE
        jr      z, .activate
        call    ui_dialog_hotkey
        jr      c, .loop
        ld      a, (ui_event_command)
        call    ui_dialog_clear_idle_hook
        ret
.tab:
        call    ui_dialog_tab
        jr      .loop
.activate:
        call    ui_dialog_activate_focused_key
        jr      c, .loop
        ld      a, (ui_event_command)
        call    ui_dialog_clear_idle_hook
        ret

.mouse:
        call    ui_dialog_mouse
        jr      c, .loop
        ld      a, (ui_event_command)
        call    ui_dialog_clear_idle_hook
        ret

.cancel:
        ld      a, UI_CMD_CANCEL
        call    ui_dialog_clear_idle_hook
        ret

ui_dialog_clear_idle_hook:
        push    af
        ld      hl, 0
        ld      (ui_idle_hook), hl
        IF UI_ENABLE_HINTS
        call    ui_clear_context_hint
        ENDIF
        pop     af
        ret

ui_dialog_idle:
        ld      a, (ui_dialog_blink_counter)
        dec     a
        ld      (ui_dialog_blink_counter), a
        ret     nz
        ld      a, 16
        ld      (ui_dialog_blink_counter), a
        ld      a, (ui_text_cursor_visible)
        xor     1
        ld      (ui_text_cursor_visible), a
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        call    ui_dialog_draw_focus_text_field
        ret

ui_dialog_draw_all:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_WINDOW)
        ld      h, (ix + UI_DIALOG_WINDOW + 1)
        push    hl
        pop     ix
        call    ui_draw_window
        call    ui_dialog_draw_groups
        call    ui_dialog_draw_separators
        call    ui_dialog_draw_text_fields
        call    ui_dialog_draw_checks
        call    ui_dialog_draw_radios
        call    ui_dialog_draw_buttons
        ret

ui_dialog_parent_to_ix:
        ld      ix, (ui_dialog_active)
        ld      e, (ix + UI_DIALOG_WINDOW)
        ld      d, (ix + UI_DIALOG_WINDOW + 1)
        push    de
        pop     ix
        ret

ui_dialog_draw_groups:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_GROUPS)
        ld      h, (ix + UI_DIALOG_GROUPS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_GROUPS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_group_box
        pop     ix
        pop     hl
        ld      de, UI_GROUP_SIZE
        add     hl, de
        jr      .loop

ui_dialog_draw_separators:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_SEPARATORS)
        ld      h, (ix + UI_DIALOG_SEPARATORS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_SEPARATORS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_separator
        pop     ix
        pop     hl
        ld      de, UI_SEPARATOR_SIZE
        add     hl, de
        jr      .loop

ui_dialog_draw_text_fields:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_text_field
        pop     ix
        pop     hl
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop

ui_dialog_draw_checks:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_checkbox
        pop     ix
        pop     hl
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop

ui_dialog_draw_radios:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_radio_button
        pop     ix
        pop     hl
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop

ui_dialog_draw_buttons:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        ret     z
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_draw_button
        pop     ix
        pop     hl
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop

ui_dialog_count_focus:
        ld      b, 0
        call    ui_dialog_count_text_fields
        call    ui_dialog_count_checks
        call    ui_dialog_count_radios
        call    ui_dialog_count_buttons
        ld      a, b
        ret

ui_dialog_count_text_fields:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        inc     b
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop

ui_dialog_count_checks:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        inc     b
.next:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop

ui_dialog_count_radios:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        inc     b
.next:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop

ui_dialog_count_buttons:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        inc     b
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop

ui_dialog_clear_focus:
        call    ui_dialog_clear_text_fields
        call    ui_dialog_clear_checks
        call    ui_dialog_clear_radios
        call    ui_dialog_clear_buttons
        ret

ui_dialog_clear_text_fields:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        res     6, (hl)
        pop     hl
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop

ui_dialog_clear_checks:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        res     6, (hl)
        pop     hl
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop

ui_dialog_clear_radios:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        res     6, (hl)
        pop     hl
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop

ui_dialog_clear_buttons:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        res     6, (hl)
        res     5, (hl)
        pop     hl
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop

ui_dialog_set_focus:
        ld      a, (ui_dialog_last_focus_index)
        ld      b, a
        ld      a, (ui_dialog_focus_index)
        cp      b
        ret     z
        push    af
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_dialog_blink_counter), a
        call    ui_dialog_clear_focus
        ld      a, (ui_dialog_last_focus_index)
        cp      0FFh
        jr      z, .skip_old_draw
        call    ui_dialog_draw_focus_index
.skip_old_draw:
        pop     af
        push    af
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        call    ui_dialog_set_focus_text_field
        jr      nc, .draw_new
        call    ui_dialog_set_focus_check
        jr      nc, .draw_new
        call    ui_dialog_set_focus_radio
        jr      nc, .draw_new
        call    ui_dialog_set_focus_button
.draw_new:
        pop     af
        ld      (ui_dialog_last_focus_index), a
        call    ui_dialog_draw_focus_index
        IF UI_ENABLE_HINTS
        call    ui_dialog_update_hint
        ENDIF
        ret

; ui_dialog_change_focus_to_current
; Mouse button hits already know the requested global focus index in
; ui_dialog_current_index. Use the current focus as the old element and redraw
; only the old and new widgets.
ui_dialog_change_focus_to_current:
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_old_focus_index), a
        ld      b, a
        ld      a, (ui_dialog_current_index)
        ld      (ui_dialog_focus_index), a
        cp      b
        ret     z
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_dialog_blink_counter), a
        call    ui_dialog_clear_focus
        ld      a, (ui_dialog_old_focus_index)
        call    ui_dialog_draw_focus_index
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        call    ui_dialog_set_focus_text_field
        jr      nc, .draw_new
        call    ui_dialog_set_focus_check
        jr      nc, .draw_new
        call    ui_dialog_set_focus_radio
        jr      nc, .draw_new
        call    ui_dialog_set_focus_button
.draw_new:
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_last_focus_index), a
        call    ui_dialog_draw_focus_index
        IF UI_ENABLE_HINTS
        call    ui_dialog_update_hint
        ENDIF
        ret

        IF UI_ENABLE_HINTS
ui_dialog_update_hint:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_HINTS)
        ld      h, (ix + UI_DIALOG_HINTS + 1)
        ld      a, h
        or      l
        jr      z, .clear
        ld      a, (ui_dialog_focus_index)
        add     a, a
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     hl
        jp      ui_set_context_hint
.clear:
        jp      ui_clear_context_hint
        ENDIF

ui_dialog_draw_focus_index:
        cp      0FFh
        ret     z
        ld      (ui_dialog_target_index), a
        call    ui_dialog_draw_focus_text_field
        ret     nc
        call    ui_dialog_draw_focus_check
        ret     nc
        call    ui_dialog_draw_focus_radio
        ret     nc
        jp      ui_dialog_draw_focus_button

ui_dialog_focus_match:
        ld      a, (ui_dialog_target_index)
        or      a
        jr      z, .hit
        dec     a
        ld      (ui_dialog_target_index), a
        scf
        ret
.hit:
        or      a
        ret

ui_dialog_set_focus_text_field:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        scf
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        set     6, (hl)
        pop     hl
        or      a
        ret

ui_dialog_set_focus_check:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        scf
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        set     6, (hl)
        pop     hl
        or      a
        ret

ui_dialog_set_focus_radio:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        scf
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        set     6, (hl)
        pop     hl
        or      a
        ret

ui_dialog_set_focus_button:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        set     6, (hl)
        pop     hl
        or      a
        ret

ui_dialog_draw_focus_text_field:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        scf
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        push    hl
        pop     iy
        call    ui_draw_text_field
        pop     hl
        or      a
        ret

ui_dialog_draw_focus_check:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        scf
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        push    hl
        pop     iy
        call    ui_draw_checkbox
        pop     hl
        or      a
        ret

ui_dialog_draw_focus_radio:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        scf
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        push    hl
        pop     iy
        call    ui_draw_radio_button
        pop     hl
        or      a
        ret

ui_dialog_draw_focus_button:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        push    hl
        pop     iy
        call    ui_draw_button
        pop     hl
        or      a
        ret

ui_dialog_tab:
        ld      a, (ui_dialog_focus_count)
        or      a
        ret     z
        ld      a, (ui_event_mods)
        and     0D0h              ; Shift L/R or Alt in DSS keyboard state
        jr      nz, .prev
.next:
        ld      a, (ui_dialog_focus_index)
        inc     a
        ld      b, a
        ld      a, (ui_dialog_focus_count)
        cp      b
        jr      nz, .store_next
        ld      b, 0
.store_next:
        ld      a, b
        ld      (ui_dialog_focus_index), a
        jp      ui_dialog_set_focus
.prev:
        ld      a, (ui_dialog_focus_index)
        or      a
        jr      nz, .dec
        ld      a, (ui_dialog_focus_count)
.dec:
        dec     a
        ld      (ui_dialog_focus_index), a
        jp      ui_dialog_set_focus

ui_dialog_text_key:
        ld      a, (ui_event_scan)
        cp      UI_SCAN_LEFT
        jr      z, .editable
        cp      UI_SCAN_RIGHT
        jr      z, .editable
        cp      UI_SCAN_HOME
        jr      z, .editable
        cp      UI_SCAN_END
        jr      z, .editable
        cp      UI_SCAN_DELETE
        jr      z, .editable
        ld      a, (ui_event_key)
        cp      08h
        jr      z, .editable
        cp      7Fh
        jr      z, .editable
        cp      20h
        jp      c, .not_handled
        cp      7Fh
        jp      nc, .not_handled
.editable:
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        jr      z, .not_handled
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        jr      z, .not_handled
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        push    hl
        push    hl
        pop     iy
        ld      a, (ui_event_scan)
        cp      UI_SCAN_LEFT
        jr      z, .left
        cp      UI_SCAN_RIGHT
        jr      z, .right
        cp      UI_SCAN_HOME
        jr      z, .home
        cp      UI_SCAN_END
        jr      z, .end
        cp      UI_SCAN_DELETE
        jr      z, .delete
        ld      a, (ui_event_key)
        cp      08h
        jr      z, .backspace
        cp      7Fh
        jr      z, .backspace
        call    ui_text_field_insert_char
        jr      .redraw
.left:
        call    ui_text_field_cursor_left
        jr      .redraw
.right:
        call    ui_text_field_cursor_right
        jr      .redraw
.home:
        call    ui_text_field_cursor_home
        jr      .redraw
.end:
        call    ui_text_field_cursor_end
        jr      .redraw
.delete:
        call    ui_text_field_delete_at_cursor
        jr      .redraw
.backspace:
        call    ui_text_field_backspace
.redraw:
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_dialog_blink_counter), a
        call    ui_dialog_parent_to_ix
        pop     hl
        push    hl
        push    hl
        pop     iy
        call    ui_draw_text_field
        pop     hl
        scf
        ret
.not_handled:
        or      a
        ret

ui_dialog_activate_focused_key:
        xor     a
        ld      (ui_dialog_handled), a
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        call    ui_dialog_activate_text_field
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        call    ui_dialog_activate_check
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        call    ui_dialog_activate_radio
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        call    ui_dialog_activate_button_key
        ret
.handled:
        scf
        ret

ui_dialog_activate_text_field:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        scf
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, 1
        ld      (ui_dialog_handled), a
        scf
        ret

ui_dialog_activate_check:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        scf
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, 1
        ld      (ui_dialog_handled), a
        push    hl
        push    hl
        pop     iy
        call    ui_toggle_checkbox
        call    ui_dialog_parent_to_ix
        pop     hl
        push    hl
        push    hl
        pop     iy
        call    ui_draw_checkbox
        pop     hl
        scf
        ret

ui_dialog_activate_radio:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        scf
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, 1
        ld      (ui_dialog_handled), a
        push    hl
        call    ui_dialog_clear_radio_checks
        pop     hl
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        set     0, (hl)
        pop     hl
        call    ui_dialog_draw_radios
        scf
        ret

ui_dialog_clear_radio_checks:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        res     0, (hl)
        pop     hl
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop

ui_dialog_activate_button_key:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        call    ui_dialog_parent_to_ix
        push    hl
        push    hl
        pop     iy
        call    ui_button_press_key_feedback
        pop     hl
        ld      de, UI_BUTTON_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_event_command), a
        or      a
        ret

ui_dialog_hotkey:
        xor     a
        ld      (ui_dialog_handled), a
        call    ui_dialog_hotkey_text_field
        push    af
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_hotkey_check
        push    af
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_hotkey_radio
        push    af
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_hotkey_button
        ret
.handled:
        pop     af
        scf
        ret

ui_dialog_key_match:
        cp      (hl)
        jr      z, .hit
        or      20h
        cp      (hl)
        jr      z, .hit
        and     0DFh
        cp      (hl)
        jr      z, .hit
        scf
        ret
.hit:
        or      a
        ret

ui_dialog_hotkey_text_field:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        ld      b, 0
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        scf
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        push    hl
        ld      de, UI_TEXT_HOTKEY
        add     hl, de
        ld      a, (hl)
        or      a
        jr      z, .empty_key
        ld      a, (ui_event_key)
        call    ui_dialog_key_match
        jr      .tested
.empty_key:
        scf
.tested:
        pop     hl
        jr      nc, .hit
        inc     b
.next:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, b
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        ld      a, 1
        ld      (ui_dialog_handled), a
        scf
        ret

ui_dialog_hotkey_check:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        ld      b, 0
        call    ui_dialog_count_text_fields
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        scf
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        push    hl
        ld      de, UI_CHECK_HOTKEY
        add     hl, de
        ld      a, (ui_event_key)
        call    ui_dialog_key_match
        pop     hl
        jr      nc, .hit
        inc     b
.next:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, b
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        jp      ui_dialog_activate_focused_key

ui_dialog_hotkey_radio:
        ld      b, 0
        call    ui_dialog_count_text_fields
        call    ui_dialog_count_checks
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        scf
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        push    hl
        ld      de, UI_RADIO_HOTKEY
        add     hl, de
        ld      a, (ui_event_key)
        call    ui_dialog_key_match
        pop     hl
        jr      nc, .hit
        inc     b
.next:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, b
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        jp      ui_dialog_activate_focused_key

ui_dialog_hotkey_button:
        ld      b, 0
        call    ui_dialog_count_text_fields
        call    ui_dialog_count_checks
        call    ui_dialog_count_radios
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        push    hl
        ld      de, UI_BUTTON_HOTKEY
        add     hl, de
        ld      a, (ui_event_key)
        call    ui_dialog_key_match
        pop     hl
        jr      nc, .hit
        inc     b
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, b
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        jp      ui_dialog_activate_focused_key

ui_dialog_mouse:
        xor     a
        ld      (ui_dialog_handled), a
        xor     a
        ld      (ui_dialog_current_index), a
        call    ui_dialog_mouse_text_fields
        push    af                       ; preserve CF from sub-call
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_mouse_checks
        push    af                       ; preserve CF from sub-call
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_mouse_radios
        push    af
        ld      a, (ui_dialog_handled)
        or      a
        jr      nz, .handled
        pop     af
        ret     nc
        call    ui_dialog_mouse_buttons
        ret
.handled:
        pop     af                       ; discard preserved flags
        scf
        ret

ui_dialog_mouse_text_fields:
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_TEXT_FIELDS)
        ld      h, (ix + UI_DIALOG_TEXT_FIELDS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_TEXT_FIELDS_END
        scf
        ret     z
        push    hl
        ld      de, UI_TEXT_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .skip
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_dialog_text_field_hit_test
        pop     ix
        pop     hl
        jr      nc, .hit
        ld      a, (ui_dialog_current_index)
        inc     a
        ld      (ui_dialog_current_index), a
.skip:
        ld      de, UI_TEXT_SIZE
        add     hl, de
        jr      .loop
.hit:
        call    ui_dialog_change_focus_to_current
        ld      a, 1
        ld      (ui_dialog_handled), a
        scf
        ret

ui_dialog_mouse_checks:
        ld      b, 0
        call    ui_dialog_count_text_fields
        ld      a, b
        ld      (ui_dialog_current_index), a
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_CHECKS)
        ld      h, (ix + UI_DIALOG_CHECKS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_CHECKS_END
        scf
        ret     z
        push    hl
        ld      de, UI_CHECK_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .skip
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_dialog_checkbox_hit_test
        pop     ix
        pop     hl
        jr      nc, .hit
        ld      a, (ui_dialog_current_index)
        inc     a
        ld      (ui_dialog_current_index), a
.skip:
        ld      de, UI_CHECK_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, (ui_dialog_current_index)
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        jp      ui_dialog_activate_focused_key

ui_dialog_mouse_radios:
        ld      b, 0
        call    ui_dialog_count_text_fields
        call    ui_dialog_count_checks
        ld      a, b
        ld      (ui_dialog_current_index), a
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_RADIOS)
        ld      h, (ix + UI_DIALOG_RADIOS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_RADIOS_END
        scf
        ret     z
        push    hl
        ld      de, UI_RADIO_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .skip
        push    hl
        push    ix
        push    hl
        pop     iy
        call    ui_dialog_radio_hit_test
        pop     ix
        pop     hl
        jr      nc, .hit
        ld      a, (ui_dialog_current_index)
        inc     a
        ld      (ui_dialog_current_index), a
.skip:
        ld      de, UI_RADIO_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      a, (ui_dialog_current_index)
        ld      (ui_dialog_focus_index), a
        call    ui_dialog_set_focus
        jp      ui_dialog_activate_focused_key

ui_dialog_mouse_buttons:
        ld      b, 0
        call    ui_dialog_count_text_fields
        call    ui_dialog_count_checks
        call    ui_dialog_count_radios
        ld      a, b
        ld      (ui_dialog_current_index), a
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
        call    ui_dialog_parent_to_ix
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .skip
        push    hl
        push    ix
        push    hl
        pop     iy
        ld      a, (ui_event_mouse_x)
        push    af
        ld      a, (ui_event_mouse_y)
        ld      b, a
        pop     af
        call    ui_button_hit_test
        pop     ix
        pop     hl
        jr      nc, .hit
        ld      a, (ui_dialog_current_index)
        inc     a
        ld      (ui_dialog_current_index), a
.skip:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        call    ui_dialog_change_focus_to_current
        call    ui_dialog_activate_button_mouse
        ret

ui_dialog_activate_button_mouse:
        ld      a, (ui_dialog_focus_index)
        ld      (ui_dialog_target_index), a
        ld      b, 0
        call    ui_dialog_count_checks
        call    ui_dialog_count_radios
        ld      a, (ui_dialog_target_index)
        sub     b
        ld      (ui_dialog_target_index), a
        ld      ix, (ui_dialog_active)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        ld      a, h
        or      l
        scf
        ret     z
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        scf
        ret     z
        push    hl
        ld      de, UI_BUTTON_FLAGS
        add     hl, de
        bit     7, (hl)
        pop     hl
        jr      nz, .next
        call    ui_dialog_focus_match
        jr      nc, .hit
.next:
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        call    ui_dialog_parent_to_ix
        push    hl
        push    hl
        pop     iy
        call    ui_button_press_mouse_feedback
        pop     hl
        ret     c
        ld      de, UI_BUTTON_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_event_command), a
        or      a
        ret

ui_dialog_text_field_hit_test:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_TEXT_Y)
        ld      b, a
        ld      a, (ui_event_mouse_y)
        cp      b
        jr      nz, .miss
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_TEXT_X)
        ld      d, a
        ld      a, (ui_event_mouse_x)
        cp      d
        jr      c, .miss
        ld      a, d
        add     a, (iy + UI_TEXT_W)
        ld      e, a
        ld      a, (ui_event_mouse_x)
        cp      e
        jr      nc, .miss
        or      a
        ret
.miss:
        scf
        ret

ui_dialog_checkbox_hit_test:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_CHECK_Y)
        ld      b, a
        ld      a, (ui_event_mouse_y)
        cp      b
        jr      nz, .miss
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_CHECK_X)
        ld      d, a
        ld      a, (ui_event_mouse_x)
        cp      d
        jr      c, .miss
        ld      l, (iy + UI_CHECK_LABEL)
        ld      h, (iy + UI_CHECK_LABEL + 1)
        call    ui_button_visible_width
        ld      a, d
        add     a, b
        add     a, 4
        ld      e, a
        ld      a, (ui_event_mouse_x)
        cp      e
        jr      nc, .miss
        or      a
        ret
.miss:
        scf
        ret

ui_dialog_radio_hit_test:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_RADIO_Y)
        ld      b, a
        ld      a, (ui_event_mouse_y)
        cp      b
        jr      nz, .miss
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_RADIO_X)
        ld      d, a
        ld      a, (ui_event_mouse_x)
        cp      d
        jr      c, .miss
        ld      l, (iy + UI_RADIO_LABEL)
        ld      h, (iy + UI_RADIO_LABEL + 1)
        call    ui_button_visible_width
        ld      a, d
        add     a, b
        add     a, 4
        ld      e, a
        ld      a, (ui_event_mouse_x)
        cp      e
        jr      nc, .miss
        or      a
        ret
.miss:
        scf
        ret
