; Minimal progress-bar example for modular linking.

        output  "build/examples/PROGRESS_ONLY.EXE"

PROGRESS_ONLY_LOAD_ADDR equ     4200h
PROGRESS_ONLY_STACK     equ     7F00h

        org     PROGRESS_ONLY_LOAD_ADDR - 512

exe_header:
        db      "EXE"               ; signature
        db      1                   ; EXE version
        dw      code_start - exe_header
        dw      0                   ; high word of file offset
        dw      progress_only_end - code_start
        dw      0, 0, 0             ; reserved
        dw      code_start          ; load address
        dw      progress_only_main  ; entry point
        dw      PROGRESS_ONLY_STACK ; stack
        ds      512 - ($ - exe_header), 0

        org     PROGRESS_ONLY_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/progress_bar.asm"

progress_only_main:
        call    ui_init
        jp      c, progress_only_exit_raw

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, progress_only_window
        call    ui_draw_window
        ld      hl, progress_only_text
        ld      a, (ui_theme_window)
        ld      d, 10
        ld      e, 22
        ld      b, 36
        ld      c, 3
        call    ui_print_wrapped_z
        call    progress_only_draw_labels
        call    progress_only_draw

progress_only_loop:
        call    progress_only_idle
        ld      c, Dss.ScanKey
        call    ui_call_dss
        jr      z, progress_only_no_key
        cp      UI_KEY_ESCAPE
        jp      z, progress_only_exit
        cp      UI_KEY_ENTER
        jp      z, progress_only_exit
        cp      UI_KEY_SPACE
        jr      z, progress_only_step
        call    progress_only_clear_keys
        jr      progress_only_no_key

        ; Space advances the determinate bar. The keyboard buffer is flushed
        ; after each handled key to avoid auto-repeat redraw storms.
progress_only_step:
        call    progress_only_clear_keys
        ld      hl, progress_only_done + UI_PROGRESS_VALUE
        inc     (hl)
        ld      a, (hl)
        cp      11
        jr      c, .redraw
        ld      (hl), 0
.redraw:
        ld      iy, progress_only_busy
        call    ui_progress_bar_tick
        call    progress_only_draw
        jr      progress_only_loop

progress_only_no_key:
        halt
        jr      progress_only_loop

progress_only_clear_keys:
        push    af
        push    bc
        ld      b, Dss.ScanKey
        ld      c, Dss.K_Clear
        call    ui_call_dss
        pop     bc
        pop     af
        ret

progress_only_idle:
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        push    iy
        ld      iy, progress_only_busy
        call    ui_progress_bar_tick
        ld      ix, progress_only_window
        ld      iy, progress_only_busy
        call    ui_draw_progress_bar
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

progress_only_draw_labels:
        ld      hl, progress_only_done_label
        ld      a, (ui_theme_window)
        ld      d, 14
        ld      e, 24
        call    ui_print_z
        ld      hl, progress_only_busy_label
        ld      a, (ui_theme_window)
        ld      d, 17
        ld      e, 24
        jp      ui_print_z

progress_only_draw:
        ld      ix, progress_only_window
        ld      iy, progress_only_done
        call    ui_draw_progress_bar
progress_only_draw_busy:
        ld      ix, progress_only_window
        ld      iy, progress_only_busy
        call    ui_draw_progress_bar
        ret

progress_only_exit:
        call    ui_shutdown
progress_only_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

progress_only_window:
        db      18, 8, 44, 13
        dw      progress_only_title
        db      UI_FRAME_DOUBLE

progress_only_done:
        db      15, 6, 22, 0, 0, 10, 0
progress_only_busy:
        db      15, 9, 22, UI_FLAG_INDETERMINATE, 0, 0, 0

progress_only_title:
        db      " ProgressBar module demo ", 0
progress_only_text:
        db      "Any key advances the top bar.", 0Ah
        db      "Busy bar animates while idle.", 0Ah
        db      "Enter or Esc exits.", 0
progress_only_done_label:
        db      "Done:", 0
progress_only_busy_label:
        db      "Busy:", 0

progress_only_end:
