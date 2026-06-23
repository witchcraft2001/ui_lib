; Event polling for keyboard and mouse.

ui_event_type:
        db      UI_EVENT_NONE
ui_event_key:
        db      0
ui_event_scan:
        db      0
ui_event_mods:
        db      0
ui_event_mouse_x:
        db      0
ui_event_mouse_y:
        db      0
ui_event_mouse_buttons:
        db      0
ui_event_command:
        db      UI_CMD_NONE
ui_mouse_prev_buttons:
        db      0
ui_idle_hook:
        dw      0
; Optional ~50 Hz tick for animation (e.g. a blinking text cursor). text_field.asm
; points this at ui_cursor_blink when a field is focused; stays 0 otherwise, so
; consumers that omit text_field.asm link cleanly.
ui_cursor_blink_hook:
        dw      0

; ui_poll_event
; Blocks until a keyboard or left-mouse-click event is available.
; Out:
;   ui_event_type = UI_EVENT_KEY or UI_EVENT_MOUSE
;   ui_event_key or ui_event_mouse_x/ui_event_mouse_y filled
; Clobbers: AF, BC, DE, HL
ui_poll_event:
.again:
        call    ui_poll_mouse
        ld      a, (ui_event_type)
        or      a
        ret     nz

        ld      c, Dss.CtrlKey
        rst     10h
        or      a
        jr      nz, .consume_key
        halt
        call    ui_call_idle_hook
        call    ui_call_cursor_blink
        jr      .again
.consume_key:
        ld      c, Dss.ScanKey
        rst     10h
.key:
        ld      (ui_event_key), a
        ld      a, d
        ld      (ui_event_scan), a
        ld      a, b
        ld      (ui_event_mods), a
        ld      a, UI_EVENT_KEY
        ld      (ui_event_type), a
        ret

ui_call_idle_hook:
        ld      hl, (ui_idle_hook)
        ld      a, h
        or      l
        ret     z
        jp      (hl)

ui_call_cursor_blink:
        ld      hl, (ui_cursor_blink_hook)
        ld      a, h
        or      l
        ret     z
        push    ix                              ; the blink uses IX/IY; keep the
        push    iy                              ; caller's intact across the poll
        call    .call_hl
        pop     iy
        pop     ix
        ret
.call_hl:
        jp      (hl)

; ui_event_is_ctrl / ui_event_is_alt / ui_event_is_shift
; Test the modifier state captured for the last key event (ui_event_mods).
; Out: ZF=0 (NZ) if the modifier was held, ZF=1 (Z) otherwise; A=masked bits.
; Clobbers: AF
ui_event_is_ctrl:
        ld      a, (ui_event_mods)
        and     UI_KEYMOD_CTRL_ANY
        ret
ui_event_is_alt:
        ld      a, (ui_event_mods)
        and     UI_KEYMOD_ALT_ANY
        ret
ui_event_is_shift:
        ld      a, (ui_event_mods)
        and     UI_KEYMOD_SHIFT_ANY
        ret

; ui_poll_mouse
; Updates ui_event_mouse_x/y to the current cursor and emits one event on a
; button press transition: UI_EVENT_MOUSE for the left button, UI_EVENT_RMOUSE
; for the right. ui_event_mouse_buttons holds the current mask (bit0 left,
; bit1 right). Widgets that only watch UI_EVENT_MOUSE keep their behaviour.
; Clobbers: AF, BC, DE, HL
ui_poll_mouse:
        xor     a
        ld      (ui_event_type), a

        ld      a, (ui_mouse_available)
        or      a
        ret     z

        ld      a, Bios.Mouse_Read
        ld      c, a
        rst     30h
        ret     c
        push    af                ; A = buttons

        ; Convert pixel X in HL / pixel Y in DE to text cells.
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
        and     03h               ; left|right
        ld      c, a              ; C = current buttons
        ld      (ui_event_mouse_buttons), a
        ld      a, (ui_mouse_prev_buttons)
        ld      b, a              ; B = previous buttons
        ld      a, c
        ld      (ui_mouse_prev_buttons), a

        ld      a, c              ; left press edge?
        and     01h
        jr      z, .right
        ld      a, b
        and     01h
        jr      nz, .right
        ld      a, UI_EVENT_MOUSE
        ld      (ui_event_type), a
        ret
.right:
        ld      a, c              ; right press edge?
        and     02h
        ret     z
        ld      a, b
        and     02h
        ret     nz
        ld      a, UI_EVENT_RMOUSE
        ld      (ui_event_type), a
        ret
