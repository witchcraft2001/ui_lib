; MessageBox example: shows each button set and reports the chosen result.

        DEFINE  UI_USE_DSS_WINDOW_BUFFER 1

        output  "build/examples/MSGBOX.EXE"

MSGBOX_LOAD_ADDR equ    4200h
MSGBOX_STACK     equ    7F00h

        org     MSGBOX_LOAD_ADDR - 512

exe_header:
        db      "EXE"
        db      1
        dw      code_start - exe_header
        dw      0
        dw      msgbox_end - code_start
        dw      0, 0, 0
        dw      code_start
        dw      msgbox_main
        dw      MSGBOX_STACK
        ds      512 - ($ - exe_header), 0

        org     MSGBOX_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"
        include "src/widgets/button_events.asm"
        include "src/widgets/message_box.asm"

msgbox_main:
        call    ui_init
        jp      c, msgbox_exit_raw

        ld      a, 0B0h                 ; desktop dither so the shadow shows
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      hl, msgbox_intro
        ld      a, (ui_theme_hint)
        ld      d, 1
        ld      e, 2
        call    ui_print_z

msgbox_loop:
        ld      c, Dss.ScanKey
        call    ui_call_dss
        jr      z, msgbox_loop
        cp      UI_KEY_ESCAPE
        jp      z, msgbox_exit
        cp      "1"
        jp      z, .ok
        cp      "2"
        jp      z, .okcancel
        cp      "3"
        jp      z, .yesno
        cp      "4"
        jp      z, .yesnocancel
        cp      "5"
        jp      z, .abort
        jr      msgbox_loop
.ok:
        ld      hl, msgbox_txt_short
        ld      de, msgbox_title
        ld      a, UI_MSG_OK
        ld      b, 0
        jr      .show
.okcancel:
        ld      hl, msgbox_txt_long
        ld      de, msgbox_title
        ld      a, UI_MSG_OKCANCEL
        ld      b, 0
        jr      .show
.yesno:
        ld      hl, msgbox_txt_q
        ld      de, 0                    ; no title
        ld      a, UI_MSG_YESNO
        ld      b, 0
        jr      .show
.yesnocancel:
        ld      hl, msgbox_txt_q
        ld      de, msgbox_title
        ld      a, UI_MSG_YESNOCANCEL
        ld      b, 17h                  ; blue body, white text
        jr      .show
.abort:
        ld      hl, msgbox_txt_err
        ld      de, msgbox_title_err
        ld      a, UI_MSG_ABORTRETRYIGNORE
        ld      b, 0
.show:
        call    ui_message_box
        call    msgbox_report
        jr      msgbox_loop

; Show "Result: <name>" on the bottom line. In: A = result code.
msgbox_report:
        ld      hl, msgbox_results
        dec     a                       ; result codes start at 1
        add     a, a                    ; *2 word table
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a                    ; HL = result name ptr

        push    hl
        ld      a, 020h
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        ld      d, 30
        ld      e, 2
        ld      h, 1
        ld      l, 40
        call    ui_fill_rect
        pop     hl

        push    hl
        ld      hl, msgbox_result_label
        ld      a, (ui_theme_hint)
        ld      d, 30
        ld      e, 2
        call    ui_print_z
        pop     hl
        ld      a, (ui_theme_hint)
        ld      d, 30
        ld      e, 10
        call    ui_print_z
        ret

msgbox_exit:
        call    ui_shutdown
msgbox_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

msgbox_intro:
        db      "MessageBox demo: 1=OK 2=OKCancel 3=YesNo 4=YesNoCancel 5=AbortRetryIgnore, Esc exits", 0
msgbox_result_label:
        db      "Result:", 0

msgbox_title:
        db      "Notice", 0
msgbox_title_err:
        db      "Error", 0
msgbox_txt_short:
        db      "Operation completed.", 0
msgbox_txt_long:
        db      "The document has unsaved changes. Saving will overwrite the previous version on disk. Do you want to continue?", 0
msgbox_txt_q:
        db      "Are you sure you want to proceed with this action?", 0
msgbox_txt_err:
        db      "Failed to read the file. You can abort the operation, retry the read, or ignore this file and continue.", 0

; Indexed by result code - 1.
msgbox_results:
        dw      msgbox_r_ok, msgbox_r_cancel, msgbox_r_yes, msgbox_r_no
        dw      msgbox_r_abort, msgbox_r_retry, msgbox_r_ignore
msgbox_r_ok:     db "OK", 0
msgbox_r_cancel: db "Cancel", 0
msgbox_r_yes:    db "Yes", 0
msgbox_r_no:     db "No", 0
msgbox_r_abort:  db "Abort", 0
msgbox_r_retry:  db "Retry", 0
msgbox_r_ignore: db "Ignore", 0

msgbox_end:
