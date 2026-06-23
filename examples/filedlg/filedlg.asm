; File dialog example: open a file with a two-column, paged file list.

        DEFINE  UI_ENABLE_HINTS 1
        DEFINE  UI_USE_DSS_WINDOW_BUFFER 1

        output  "build/examples/FILEDLG.EXE"

FILEDLG_LOAD_ADDR equ   4200h
FILEDLG_STACK     equ   7F00h

        org     FILEDLG_LOAD_ADDR - 512

exe_header:
        db      "EXE"
        db      1
        dw      code_start - exe_header
        dw      0
        dw      filedlg_end - code_start
        dw      0, 0, 0
        dw      code_start
        dw      filedlg_main
        dw      FILEDLG_STACK
        ds      512 - ($ - exe_header), 0

        org     FILEDLG_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/core/hint.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/text_field.asm"
        include "src/widgets/combo_box.asm"
        include "src/widgets/button.asm"
        include "src/widgets/button_events.asm"
        include "src/widgets/file_dialog.asm"

filedlg_main:
        call    ui_init
        jp      c, filedlg_exit_raw

        ld      a, 0B0h
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      hl, fdx_intro
        ld      a, (ui_theme_hint)
        ld      d, 1
        ld      e, 2
        call    ui_print_z

        ld      a, 0                    ; open mode
        ld      hl, fdx_initial
        ld      de, fdx_title
        call    ui_file_dialog
        jr      c, .cancelled
        ld      hl, ui_fd_result
        jr      .show
.cancelled:
        ld      hl, fdx_cancelled
.show:
        push    hl                      ; save the message pointer
        ld      a, (ui_theme_desktop)
        ld      b, a
        ld      a, 020h
        ld      d, 30
        ld      e, 0
        ld      h, 1
        ld      l, 80
        call    ui_fill_rect
        pop     hl
        ld      a, (ui_theme_hint)
        ld      d, 30
        ld      e, 2
        call    ui_print_z
.wait:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      nz, .wait

        call    ui_shutdown
filedlg_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

fdx_intro:
        db      "File dialog: Tab between fields, navigate the list with arrows, Enter opens a dir/file.", 0
fdx_cancelled:
        db      "Cancelled.", 0
fdx_initial:
        db      "*.*", 0
fdx_title:
        db      "Open a file", 0

filedlg_end:
