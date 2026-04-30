; Minimal button-only modal dialog loop.

; ui_dialog_run
; In:  IX=dialog descriptor
; Out: A=command
; Clobbers: AF, BC, DE, HL, IX, IY
ui_dialog_run:
        ld      l, (ix + UI_DIALOG_WINDOW)
        ld      h, (ix + UI_DIALOG_WINDOW + 1)
        push    ix
        push    hl
        pop     ix
        call    ui_draw_window
        pop     ix
        call    ui_dialog_draw_buttons
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
        call    ui_dialog_key_buttons
        jr      c, .loop
        ld      a, (ui_event_command)
        ret

.mouse:
        call    ui_dialog_mouse_buttons
        jr      c, .loop
        ld      a, (ui_event_command)
        ret

.cancel:
        ld      a, UI_CMD_CANCEL
        ret

ui_dialog_draw_buttons:
        push    ix
        ld      e, (ix + UI_DIALOG_WINDOW)
        ld      d, (ix + UI_DIALOG_WINDOW + 1)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        push    de
        pop     ix
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        jr      z, .done
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
.done:
        pop     ix
        ret

ui_dialog_key_buttons:
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        jr      z, .miss
        push    hl
        push    hl
        pop     iy
        ld      a, (ui_event_key)
        call    ui_button_accepts_key
        pop     hl
        jr      nc, .hit
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      de, UI_BUTTON_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_event_command), a
        or      a
        ret
.miss:
        scf
        ret

ui_dialog_mouse_buttons:
        push    ix
        ld      e, (ix + UI_DIALOG_WINDOW)
        ld      d, (ix + UI_DIALOG_WINDOW + 1)
        ld      l, (ix + UI_DIALOG_BUTTONS)
        ld      h, (ix + UI_DIALOG_BUTTONS + 1)
        push    de
        pop     ix
.loop:
        ld      a, (hl)
        cp      UI_BUTTONS_END
        jr      z, .miss
        push    hl
        push    hl
        pop     iy
        ld      a, (ui_event_mouse_x)
        push    af
        ld      a, (ui_event_mouse_y)
        ld      b, a
        pop     af
        call    ui_button_hit_test
        pop     hl
        jr      nc, .hit
        ld      de, UI_BUTTON_SIZE
        add     hl, de
        jr      .loop
.hit:
        ld      de, UI_BUTTON_COMMAND
        add     hl, de
        ld      a, (hl)
        ld      (ui_event_command), a
        pop     ix
        or      a
        ret
.miss:
        pop     ix
        scf
        ret
