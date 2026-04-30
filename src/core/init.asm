; Core initialization and shutdown.

        IFNDEF UI_USE_DSS_WINDOW_BUFFER
UI_USE_DSS_WINDOW_BUFFER equ 0
        ENDIF

ui_context:
ui_window_block_id:
        db      0
ui_flags:
        db      0

; ui_init
; In:  none
; Out: CF=0 on success, CF=1 on allocation error
; Clobbers: AF, BC
ui_init:
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
