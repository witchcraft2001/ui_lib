; Minimal UI library demo for Sprinter DSS.

        output  "build/demo/UI_DEMO.EXE"

        org     8100h - 512

        db      "EXE", 1
        dw      0200h               ; header size
        dw      0200h               ; code offset
        dw      0                   ; no loader
        dw      8100h               ; load address
        dw      demo_main           ; entry point
        dw      0BFFFh              ; stack
        ds      512 - 16, 0

        org     8100h

        include "include/ui.inc"
        include "src/core/init.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"

demo_main:
        call    ui_init
        jr      c, demo_no_memory

        ld      a, " "
        ld      b, UI_COLOR_DESKTOP
        call    ui_clear_screen

        ld      ix, demo_window
        call    ui_draw_window

        ld      ix, demo_window
        ld      iy, demo_button_ok
        call    ui_draw_button

        ld      ix, demo_window
        ld      iy, demo_button_cancel
        call    ui_draw_button

        ld      hl, demo_body_text
        ld      a, UI_COLOR_WINDOW
        ld      d, 10
        ld      e, 20
        call    ui_print_z

        ld      hl, demo_hint
        ld      a, UI_COLOR_HINT
        ld      d, 31
        ld      e, 1
        call    ui_print_z

        ld      c, DSS_WAITKEY
        rst     10h

demo_exit:
        call    ui_shutdown
        ld      b, 0
        ld      c, DSS_EXIT
        rst     10h

demo_no_memory:
        ld      a, " "
        ld      b, UI_COLOR_DESKTOP
        call    ui_clear_screen
        ld      hl, demo_no_memory_text
        ld      a, UI_COLOR_WINDOW_TITLE
        ld      d, 12
        ld      e, 18
        call    ui_print_z
        ld      c, DSS_WAITKEY
        rst     10h
        jr      demo_exit

demo_window:
        db      15, 6, 50, 15
        dw      demo_title

demo_button_ok:
        db      13, 11, UI_FLAG_FOCUSED, UI_CMD_OK, 18h
        dw      demo_ok_label

demo_button_cancel:
        db      28, 11, 0, UI_CMD_CANCEL, 2Eh
        dw      demo_cancel_label

demo_title:
        db      " Sprinter UI Demo ", 0
demo_body_text:
        db      "First vertical slice: window + hotkey buttons", 0
demo_ok_label:
        db      "  &OK  ", 0
demo_cancel_label:
        db      " &Cancel ", 0
demo_hint:
        db      "Press any key to exit", 0
demo_no_memory_text:
        db      "UI init failed: no DSS memory", 0
