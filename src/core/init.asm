; Core initialization and shutdown.

        IFNDEF UI_USE_DSS_WINDOW_BUFFER
UI_USE_DSS_WINDOW_BUFFER equ 0
        ENDIF

        IFNDEF UI_SET_TEXT_MODE
UI_SET_TEXT_MODE equ 1
        ENDIF

ui_context:
ui_window_block_id:
        db      0
ui_flags:
        db      0
ui_mouse_available:
        db      0

; ui_init
; In:  none
; Out: CF=0 on success, CF=1 on allocation error
; Clobbers: AF, BC
ui_init:
        call    ui_apply_default_theme

        IF UI_SET_TEXT_MODE
        ld      a, 03h             ; text mode 80x32
        ld      b, 0               ; video page 0
        ld      c, DSS_SETVMOD
        rst     10h
        ENDIF

        xor     a
        ld      (ui_mouse_available), a
        ld      a, 00h             ; initialize mouse if present
        ld      c, a
        rst     30h
        jr      c, .mouse_done
        ld      a, 1
        ld      (ui_mouse_available), a
        ld      a, BIOS_MOUSE_SHOW ; show mouse cursor if available
        ld      c, a
        rst     30h
.mouse_done:
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      b, 1
        ld      c, DSS_GETMEM
        rst     10h
        ret     c
        ld      (ui_window_block_id), a
        ENDIF
        or      a
        ret

; ui_shutdown
; In:  none
; Out: none
; Clobbers: AF, C
ui_shutdown:
        ld      a, (ui_mouse_available)
        or      a
        jr      z, .mouse_done
        ld      a, BIOS_MOUSE_HIDE ; hide mouse cursor if available
        ld      c, a
        rst     30h
.mouse_done:
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      a, (ui_window_block_id)
        or      a
        ret     z
        ld      c, DSS_FREEMEM
        rst     10h
        xor     a
        ld      (ui_window_block_id), a
        ENDIF
        ret
