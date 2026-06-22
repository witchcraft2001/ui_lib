; TextView example: a scrollable read-only help window.

        DEFINE  UI_USE_DSS_WINDOW_BUFFER 1

        output  "build/examples/TEXTVIEW.EXE"

TEXTVIEW_LOAD_ADDR equ  4200h
TEXTVIEW_STACK     equ  7F00h

        org     TEXTVIEW_LOAD_ADDR - 512

exe_header:
        db      "EXE"
        db      1
        dw      code_start - exe_header
        dw      0
        dw      textview_end - code_start
        dw      0, 0, 0
        dw      code_start
        dw      textview_main
        dw      TEXTVIEW_STACK
        ds      512 - ($ - exe_header), 0

        org     TEXTVIEW_LOAD_ADDR

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
        include "src/widgets/scrollbar.asm"
        include "src/widgets/text_view.asm"

textview_main:
        call    ui_init
        jp      c, textview_exit_raw

        ld      a, 0B0h
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, textview_window
        call    ui_draw_window
        ld      hl, textview_title_text
        ld      a, (ui_theme_window_title)
        ld      d, 3
        ld      e, 22
        call    ui_print_z
        ld      hl, textview_hint
        ld      a, (ui_theme_hint)
        ld      d, 27
        ld      e, 18
        call    ui_print_z

        ld      ix, textview_window
        ld      iy, textview_view
        call    ui_text_view_run

        call    ui_shutdown
textview_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

textview_window:
        db      14, 2, 52, 28
        dw      textview_caption
        db      UI_FRAME_DOUBLE
textview_caption:
        db      "Help", 0

; TextView: x,y,w,h relative to window, text ptr, top.
textview_view:
        db      3, 5, 46, 18
        dw      textview_body
        db      0

textview_title_text:
        db      "About this library", 0
textview_hint:
        db      "Up/Down/PgUp/PgDn/Home/End scroll, Esc closes", 0

textview_body:
        db      "This is a compact text-mode UI library for the Sprinter "
        db      "Peters Plus computer, drawn in the Borland Pascal / Turbo "
        db      "Vision style.", 0Ah, 0Ah
        db      "The TextView widget word-wraps its text to the inner width "
        db      "and shows a vertical scroll bar. Single-line moves use the "
        db      "DSS hardware scroll, while page jumps repaint the visible "
        db      "lines in place, so scrolling stays smooth without clearing "
        db      "the whole area.", 0Ah, 0Ah
        db      "Widgets included so far: Window with single or double frame "
        db      "and a Turbo Vision style shadow, Dialog, MenuBar with Alt "
        db      "and Ctrl accelerators, Button, CheckBox, RadioButton, "
        db      "TextField, ItemSelector, ComboBox, GroupBox, Separator, "
        db      "ProgressBar, ScrollBar, ListBox, MessageBox, InputBox and "
        db      "this TextView.", 0Ah, 0Ah
        db      "Every widget is an independent module: an application "
        db      "includes only the parts it needs. Descriptors hold "
        db      "coordinates relative to the parent window, so the code "
        db      "stays relocatable.", 0Ah, 0Ah
        db      "Press Esc or Enter to close this window and return to the "
        db      "desktop.", 0

textview_end:
