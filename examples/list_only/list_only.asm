; Minimal ListBox/ScrollBar example for modular linking.

        output  "build/examples/LIST_ONLY.EXE"

LIST_ONLY_LOAD_ADDR equ     4200h
LIST_ONLY_STACK     equ     7F00h

        org     LIST_ONLY_LOAD_ADDR - 512

exe_header:
        db      "EXE"               ; signature
        db      1                   ; EXE version
        dw      code_start - exe_header
        dw      0                   ; high word of file offset
        dw      list_only_end - code_start
        dw      0, 0, 0             ; reserved
        dw      code_start          ; load address
        dw      list_only_main      ; entry point
        dw      LIST_ONLY_STACK     ; stack
        ds      512 - ($ - exe_header), 0

        org     LIST_ONLY_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/scrollbar.asm"
        include "src/widgets/list_box.asm"

list_only_main:
        call    ui_init
        jp      c, list_only_exit_raw

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, list_only_window
        call    ui_draw_window
        ld      hl, list_only_intro
        ld      a, (ui_theme_hint)
        ld      d, 4
        ld      e, 22
        call    ui_print_z

        ; Draw the list once, then re-enter only the event loop so that
        ; pressing Enter updates just the "Picked:" line, not the whole list.
        ld      ix, list_only_window
        ld      iy, list_only_box
        call    ui_draw_list_box
list_only_loop:
        ld      iy, list_only_box
        call    ui_list_box_loop
        jr      c, list_only_exit           ; Esc cancels
        call    list_only_show_selected
        jr      list_only_loop

list_only_show_selected:
        ; A = selected index; print the chosen item under the list
        push    af
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        ld      d, 24
        ld      e, 22
        ld      h, 1
        ld      l, 36
        call    ui_fill_rect
        pop     af
        ld      iy, list_only_box
        call    ui_list_box_item            ; HL = selected string
        push    hl
        ld      hl, list_only_picked
        ld      a, (ui_theme_window_title)
        ld      d, 24
        ld      e, 22
        call    ui_print_z
        pop     hl
        ld      a, (ui_theme_window_title)
        ld      d, 24
        ld      e, 30
        call    ui_print_z
        ret

list_only_exit:
        call    ui_shutdown
list_only_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

list_only_window:
        db      18, 3, 44, 26
        dw      list_only_title
        db      UI_FRAME_DOUBLE

; ListBox: x,y,w,h relative to window, flags, items ptr, count, selected, top.
list_only_box:
        db      4, 6, 24, 14, 0
        dw      list_only_items
        db      16, 0, 0

list_only_items:
        dw      li01, li02, li03, li04, li05, li06, li07, li08
        dw      li09, li10, li11, li12, li13, li14, li15, li16

li01:   db      "Andromeda", 0
li02:   db      "Bootes", 0
li03:   db      "Cassiopeia", 0
li04:   db      "Draco", 0
li05:   db      "Eridanus", 0
li06:   db      "Fornax", 0
li07:   db      "Gemini", 0
li08:   db      "Hydra", 0
li09:   db      "Indus", 0
li10:   db      "Lyra", 0
li11:   db      "Mensa", 0
li12:   db      "Norma", 0
li13:   db      "Orion", 0
li14:   db      "Phoenix", 0
li15:   db      "Reticulum", 0
li16:   db      "Sagittarius", 0

list_only_title:
        db      "ListBox demo", 0
list_only_intro:
        db      "Up/Down/Home/End, Enter selects, Esc exits, mouse scrolls.", 0
list_only_picked:
        db      "Picked:", 0

list_only_end:
