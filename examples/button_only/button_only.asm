; Minimal button-only example for modular linking.

        output  "build/examples/BUTTON_ONLY.EXE"

BUTTON_ONLY_LOAD_ADDR  equ     4200h
BUTTON_ONLY_STACK      equ     7F00h

        org     BUTTON_ONLY_LOAD_ADDR - 512

exe_header:
        db      "EXE"               ; signature
        db      1                   ; EXE version
        dw      code_start - exe_header
        dw      0                   ; high word of file offset
        dw      button_only_end - code_start
        dw      0, 0, 0             ; reserved
        dw      code_start          ; load address
        dw      button_only_main    ; entry point
        dw      BUTTON_ONLY_STACK   ; stack
        ds      512 - ($ - exe_header), 0

        org     BUTTON_ONLY_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"
        include "src/widgets/button_events.asm"

button_only_main:
        call    ui_init
        jp      c, button_only_exit_raw

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, button_only_window
        call    ui_draw_window
        ld      hl, button_only_text
        ld      a, (ui_theme_window)
        ld      d, 12
        ld      e, 22
        ld      b, 34
        ld      c, 3
        call    ui_print_wrapped_z

        ld      hl, button_only_ok + UI_BUTTON_FLAGS
        set     6, (hl)
        ld      ix, button_only_window
        ld      iy, button_only_ok
        call    ui_draw_button

button_only_loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      z, button_only_key
        cp      UI_EVENT_MOUSE
        jr      z, button_only_mouse
        jr      button_only_loop

button_only_key:
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jr      z, button_only_cancel
        cp      UI_KEY_SPACE
        jr      z, button_only_accept_key
        ld      iy, button_only_ok
        call    ui_button_accepts_key
        jr      c, button_only_loop
button_only_accept_key:
        ld      ix, button_only_window
        ld      iy, button_only_ok
        call    ui_button_press_key_feedback
        jr      button_only_ok_result

button_only_mouse:
        ld      ix, button_only_window
        ld      iy, button_only_ok
        ld      a, (ui_event_mouse_x)
        ld      hl, ui_event_mouse_y
        ld      b, (hl)
        call    ui_button_hit_test
        jr      c, button_only_loop
        call    ui_button_press_mouse_feedback
        jr      c, button_only_loop
        jr      button_only_ok_result

button_only_ok_result:
        ld      hl, button_only_ok_text
        jr      button_only_show_result

button_only_cancel:
        ld      hl, button_only_cancel_text

button_only_show_result:
        ld      a, " "
        push    hl
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen
        pop     hl
        ld      a, (ui_theme_hint)
        ld      d, 15
        ld      e, 20
        call    ui_print_z
        ld      c, Dss.WaitKey
        rst     10h

button_only_exit:
        call    ui_shutdown
button_only_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

button_only_window:
        db      18, 8, 44, 13
        dw      button_only_title

button_only_ok:
        db      18, 9, 0, UI_CMD_OK, "o"
        dw      button_only_ok_label

button_only_title:
        db      " Button-only module demo ", 0
button_only_ok_label:
        db      "  &OK  ", 0
button_only_text:
        db      "Only window and button widgets", 0Ah
        db      "are linked.", 0
button_only_ok_text:
        db      "OK command received. Press any key.", 0
button_only_cancel_text:
        db      "Cancelled. Press any key.", 0

button_only_end:
