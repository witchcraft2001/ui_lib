; InputBox: a modal dialog that prompts for a single line of text.
; Reuses the MessageBox word-wrap engine for the prompt, plus the TextField
; and Button widgets. Requires message_box.asm, text_field.asm, window.asm,
; button.asm, button_events.asm and draw/text.asm.

UI_INPUT_FIELD_MIN equ 10               ; field visible width clamp
UI_INPUT_FIELD_MAX equ 40

; ui_input_box
; In:  HL = prompt text ASCIIZ (required)
;      DE = title ASCIIZ, or 0 for no title
;      BC = text buffer (caller-owned ASCIIZ: holds the initial value, receives
;           the edited value; needs maxlen+1 bytes)
;      A  = maximum length (buffer capacity, excluding the terminator)
; Out: A  = UI_MSG_RESULT_OK or UI_MSG_RESULT_CANCEL
; Clobbers: AF, BC, DE, HL, IX, IY
ui_input_box:
        ld      (ui_in_prompt), hl
        ld      (ui_in_title), de
        ld      (ui_in_buffer), bc
        ld      (ui_in_maxlen), a

        ; OK / Cancel buttons
        ld      iy, ui_in_buttons
        ld      hl, ui_in_lbl_ok
        ld      (iy + UI_BUTTON_LABEL), l
        ld      (iy + UI_BUTTON_LABEL + 1), h
        ld      (iy + UI_BUTTON_COMMAND), UI_MSG_RESULT_OK
        ld      (iy + UI_BUTTON_HOTKEY), "o"
        ld      (iy + UI_BUTTON_FLAGS), 0
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        ld      hl, ui_in_lbl_cancel
        ld      (iy + UI_BUTTON_LABEL), l
        ld      (iy + UI_BUTTON_LABEL + 1), h
        ld      (iy + UI_BUTTON_COMMAND), UI_MSG_RESULT_CANCEL
        ld      (iy + UI_BUTTON_HOTKEY), "c"
        ld      (iy + UI_BUTTON_FLAGS), 0

        ; measure the prompt
        ld      a, UI_MSG_WRAP_W
        ld      (ui_msg_wrap_w), a
        ld      hl, (ui_in_prompt)
        ld      (ui_msg_cursor), hl
        call    ui_msg_measure
        ld      a, (ui_msg_nlines)
        ld      (ui_in_plines), a
        ld      a, (ui_msg_maxlen)
        ld      (ui_in_pmax), a

        call    ui_input_layout

        ; build the field descriptor
        ld      iy, ui_in_field
        ld      (iy + UI_TEXT_X), 2
        ld      a, (ui_in_window + UI_WINDOW_H)
        sub     5
        ld      (iy + UI_TEXT_Y), a
        ld      a, (ui_in_field_w)
        ld      (iy + UI_TEXT_W), a
        ld      (iy + UI_TEXT_FLAGS), UI_FLAG_FOCUSED
        ld      (iy + UI_TEXT_HOTKEY), 0
        ld      hl, (ui_in_buffer)
        ld      (iy + UI_TEXT_BUFFER), l
        ld      (iy + UI_TEXT_BUFFER + 1), h
        ld      a, (ui_in_maxlen)
        ld      (iy + UI_TEXT_MAXLEN), a
        ld      (iy + UI_TEXT_CURSOR), 0
        ld      (iy + UI_TEXT_SCROLL), 0
        call    ui_text_field_cursor_end    ; cursor after the initial text

        xor     a
        ld      (ui_in_focus), a            ; field focused
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_in_blink), a

        call    ui_input_save_under
        call    ui_input_draw_all

        ld      hl, ui_input_idle           ; cursor blink while idle
        ld      (ui_idle_hook), hl
        call    ui_input_loop
        ld      (ui_in_result), a
        ld      hl, 0
        ld      (ui_idle_hook), hl

        call    ui_input_restore_under
        ld      a, (ui_in_result)
        ret

; Compute window geometry and button positions.
ui_input_layout:
        ; button row width
        ld      iy, ui_in_buttons
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        call    ui_button_visible_width
        ld      a, b
        ld      c, a                        ; OK width
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        call    ui_button_visible_width
        ld      a, b
        add     a, c
        add     a, 2                        ; gap
        ld      (ui_in_btn_w), a

        ; field visible width = clamp(maxlen, MIN, MAX)
        ld      a, (ui_in_maxlen)
        cp      UI_INPUT_FIELD_MIN
        jr      nc, .fmin_ok
        ld      a, UI_INPUT_FIELD_MIN
.fmin_ok:
        cp      UI_INPUT_FIELD_MAX + 1
        jr      c, .fmax_ok
        ld      a, UI_INPUT_FIELD_MAX
.fmax_ok:
        ld      (ui_in_field_w), a

        ; content width = max(pmax, field_w, btn_w, MIN)
        ld      a, (ui_in_pmax)
        ld      c, a
        ld      a, (ui_in_field_w)
        cp      c
        jr      c, .c1
        ld      c, a
.c1:
        ld      a, (ui_in_btn_w)
        cp      c
        jr      c, .c2
        ld      c, a
.c2:
        ld      a, UI_MSG_MIN_W
        cp      c
        jr      c, .c3
        ld      c, a
.c3:
        ld      a, c
        add     a, 4
        ld      (ui_in_window + UI_WINDOW_W), a
        ld      a, (ui_in_plines)
        add     a, 8                        ; frame+pads+gaps+field+buttons
        ld      (ui_in_window + UI_WINDOW_H), a

        ld      a, UI_SCREEN_COLS
        ld      hl, ui_in_window + UI_WINDOW_W
        sub     (hl)
        srl     a
        ld      (ui_in_window + UI_WINDOW_X), a
        ld      a, UI_SCREEN_ROWS
        ld      hl, ui_in_window + UI_WINDOW_H
        sub     (hl)
        srl     a
        ld      (ui_in_window + UI_WINDOW_Y), a

        ld      hl, (ui_in_title)
        ld      a, l
        ld      (ui_in_window + UI_WINDOW_TITLE), a
        ld      a, h
        ld      (ui_in_window + UI_WINDOW_TITLE + 1), a
        ld      a, UI_FRAME_DOUBLE
        ld      (ui_in_window + UI_WINDOW_FRAME), a

        ; button row Y (relative) and centred start X
        ld      a, (ui_in_window + UI_WINDOW_H)
        sub     3
        ld      e, a                        ; button Y
        ld      a, (ui_in_window + UI_WINDOW_W)
        ld      hl, ui_in_btn_w
        sub     (hl)
        srl     a
        ld      c, a                        ; running X
        ld      iy, ui_in_buttons
        ld      b, 2
.pos:
        ld      a, c
        ld      (iy + UI_BUTTON_X), a
        ld      a, e
        ld      (iy + UI_BUTTON_Y), a
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        push    bc
        push    de
        call    ui_button_visible_width
        ld      a, b
        pop     de
        pop     bc
        add     a, c
        add     a, 2
        ld      c, a
        push    de
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     de
        djnz    .pos
        ret

ui_input_draw_all:
        ld      ix, ui_in_window
        call    ui_draw_window

        ; prompt text
        ld      a, (ui_in_window + UI_WINDOW_W)
        sub     4
        ld      (ui_msg_wrap_w), a
        ld      hl, (ui_in_prompt)
        ld      (ui_msg_cursor), hl
        ld      a, (ui_in_window + UI_WINDOW_Y)
        add     a, 2
        ld      d, a
        ld      a, (ui_in_window + UI_WINDOW_X)
        add     a, 2
        ld      e, a
        ld      a, (ui_theme_window)
        call    ui_msg_draw_text

        ; field and buttons
        ld      ix, ui_in_window
        ld      iy, ui_in_field
        call    ui_draw_text_field
        call    ui_input_draw_buttons
        ret

ui_input_draw_buttons:
        ld      ix, ui_in_window
        ld      iy, ui_in_buttons
        call    ui_draw_button
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        jp      ui_draw_button

; Apply focus index A (0=field, 1=OK, 2=Cancel) and redraw everything.
ui_input_set_focus:
        ld      (ui_in_focus), a
        ld      iy, ui_in_field
        res     6, (iy + UI_TEXT_FLAGS)
        ld      iy, ui_in_buttons
        res     6, (iy + UI_BUTTON_FLAGS)
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        res     6, (iy + UI_BUTTON_FLAGS)
        ld      a, (ui_in_focus)
        or      a
        jr      nz, .button
        ld      iy, ui_in_field
        set     6, (iy + UI_TEXT_FLAGS)
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_in_blink), a
        jr      .redraw
.button:
        ld      a, (ui_in_focus)
        dec     a
        call    ui_input_button_ptr
        set     6, (iy + UI_BUTTON_FLAGS)
.redraw:
        ld      ix, ui_in_window
        ld      iy, ui_in_field
        call    ui_draw_text_field
        jp      ui_input_draw_buttons

; In: A = button index (0/1). Out: IY = &ui_in_buttons[A].
ui_input_button_ptr:
        ld      iy, ui_in_buttons
        or      a
        ret     z
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        ret

; Cursor blink while the field is focused and idle.
ui_input_idle:
        ld      a, (ui_in_focus)
        or      a
        ret     nz
        ld      a, (ui_in_blink)
        dec     a
        ld      (ui_in_blink), a
        ret     nz
        ld      a, 16
        ld      (ui_in_blink), a
        ld      a, (ui_text_cursor_visible)
        xor     1
        ld      (ui_text_cursor_visible), a
        ld      ix, ui_in_window
        ld      iy, ui_in_field
        jp      ui_draw_text_field

; Modal loop. Out: A = result.
ui_input_loop:
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
        cp      UI_KEY_TAB
        jp      z, .tab
        ld      a, (ui_in_focus)
        or      a
        jr      nz, .button_focus
        ; field focused
        ld      a, (ui_event_key)
        cp      UI_KEY_ENTER
        jp      z, .accept_ok
        call    ui_input_edit_field
        jp      .loop
.button_focus:
        ld      a, (ui_event_key)
        cp      UI_KEY_ENTER
        jr      z, .activate
        cp      UI_KEY_SPACE
        jr      z, .activate
        ld      a, (ui_event_scan)
        cp      UI_SCAN_LEFT
        jp      z, .tabprev
        cp      UI_SCAN_RIGHT
        jp      z, .tab
        ld      a, (ui_event_key)
        call    ui_input_try_hotkey
        jp      nc, .done
        jp      .loop
.activate:
        ld      a, (ui_in_focus)
        dec     a
        call    ui_input_button_ptr
        ld      ix, ui_in_window
        call    ui_button_press_key_feedback
        ld      a, (iy + UI_BUTTON_COMMAND)
        jr      .done
.accept_ok:
        ld      a, UI_MSG_RESULT_OK
        jr      .done
.cancel:
        ld      a, UI_MSG_RESULT_CANCEL
        jr      .done
.tab:
        ld      a, (ui_in_focus)
        inc     a
        cp      3
        jr      c, .tab_set
        xor     a
.tab_set:
        call    ui_input_set_focus
        jp      .loop
.tabprev:
        ld      a, (ui_in_focus)
        or      a
        jr      nz, .tp_dec
        ld      a, 3
.tp_dec:
        dec     a
        call    ui_input_set_focus
        jp      .loop
.mouse:
        call    ui_input_mouse
        jp      nc, .done
        jp      .loop
.done:
        ret

; Edit the field from the current key event, then redraw it.
ui_input_edit_field:
        ld      iy, ui_in_field
        ld      a, (ui_event_scan)
        cp      UI_SCAN_LEFT
        jr      z, .l
        cp      UI_SCAN_RIGHT
        jr      z, .r
        cp      UI_SCAN_HOME
        jr      z, .h
        cp      UI_SCAN_END
        jr      z, .e
        cp      UI_SCAN_DELETE
        jr      z, .del
        ld      a, (ui_event_key)
        cp      08h
        jr      z, .bs
        cp      7Fh
        jr      z, .bs
        cp      " "
        ret     c
        cp      7Fh
        ret     nc
        call    ui_text_field_insert_char
        jr      .redraw
.l:
        call    ui_text_field_cursor_left
        jr      .redraw
.r:
        call    ui_text_field_cursor_right
        jr      .redraw
.h:
        call    ui_text_field_cursor_home
        jr      .redraw
.e:
        call    ui_text_field_cursor_end
        jr      .redraw
.del:
        call    ui_text_field_delete_at_cursor
        jr      .redraw
.bs:
        call    ui_text_field_backspace
.redraw:
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      a, 16
        ld      (ui_in_blink), a
        ld      ix, ui_in_window
        ld      iy, ui_in_field
        jp      ui_draw_text_field

; Try a button hotkey (A=key). Out: CF=0 and A=result if activated.
ui_input_try_hotkey:
        ld      (ui_in_key_tmp), a
        ld      ix, ui_in_window
        ld      iy, ui_in_buttons
        ld      b, 2
.bl:
        ld      a, (ui_in_key_tmp)
        push    bc
        call    ui_button_accepts_key
        pop     bc
        jr      nc, .hit
        push    bc
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     bc
        djnz    .bl
        scf
        ret
.hit:
        call    ui_button_press_key_feedback
        ld      a, (iy + UI_BUTTON_COMMAND)
        or      a
        ret

; Mouse: click a button to activate, or the field to focus it.
; Out: CF=0 and A=result if a button committed.
ui_input_mouse:
        ld      ix, ui_in_window
        ld      iy, ui_in_buttons
        ld      b, 2
.bl:
        push    bc
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_event_mouse_x)
        call    ui_button_hit_test
        pop     bc
        jr      nc, .hit
        push    bc
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     bc
        djnz    .bl
        ; not a button: if the field row was clicked, focus the field
        ld      a, (ui_in_window + UI_WINDOW_Y)
        ld      hl, ui_in_field
        ld      de, UI_TEXT_Y
        add     hl, de
        add     a, (hl)
        ld      b, a
        ld      a, (ui_event_mouse_y)
        cp      b
        jr      nz, .miss
        xor     a
        call    ui_input_set_focus
.miss:
        scf
        ret
.hit:
        call    ui_button_press_mouse_feedback
        jr      c, .cancel
        ld      a, (iy + UI_BUTTON_COMMAND)
        or      a
        ret
.cancel:
        scf
        ret

ui_input_save_under:
        xor     a
        ld      (ui_in_saved_under), a
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      ix, ui_in_window
        call    ui_window_save_under
        ret     c
        ld      a, 1
        ld      (ui_in_saved_under), a
        ENDIF
        ret

ui_input_restore_under:
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      a, (ui_in_saved_under)
        or      a
        ret     z
        xor     a
        ld      (ui_in_saved_under), a
        call    ui_window_restore_under
        ENDIF
        ret

; --- data --------------------------------------------------------------------

ui_in_prompt:
        dw      0
ui_in_title:
        dw      0
ui_in_buffer:
        dw      0
ui_in_maxlen:
        db      0
ui_in_plines:
        db      0
ui_in_pmax:
        db      0
ui_in_field_w:
        db      0
ui_in_btn_w:
        db      0
ui_in_focus:
        db      0
ui_in_blink:
        db      0
ui_in_result:
        db      0
ui_in_key_tmp:
        db      0
ui_in_saved_under:
        db      0

ui_in_window:
        db      0, 0, 0, 0
        dw      0
        db      0

ui_in_field:
        ds      UI_TEXT_SIZE, 0

ui_in_buttons:
        ds      2 * UI_BUTTON_SIZE, 0

ui_in_lbl_ok:
        db      " &OK ", 0
ui_in_lbl_cancel:
        db      " &Cancel ", 0
