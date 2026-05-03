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

; ui_poll_mouse
; Creates one event on left button transition from released to pressed.
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
        ld      b, a
        and     01h               ; only left mouse button activates UI
        jr      z, .released

        ld      a, (ui_mouse_prev_buttons)
        and     01h
        ret     nz
        ld      a, b
        ld      (ui_mouse_prev_buttons), a
        ld      (ui_event_mouse_buttons), a

        ; Convert pixel X in HL to text column.
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a, l
        ld      (ui_event_mouse_x), a

        ; Convert pixel Y in DE to text row.
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        ld      a, e
        ld      (ui_event_mouse_y), a

        ld      a, UI_EVENT_MOUSE
        ld      (ui_event_type), a
        ret

.released:
        xor     a
        ld      (ui_mouse_prev_buttons), a
        ld      (ui_event_mouse_buttons), a
        ret
