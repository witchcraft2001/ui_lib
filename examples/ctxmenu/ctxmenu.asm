; Context-menu example: click anywhere to open a popup at the cursor.

        DEFINE  UI_ENABLE_HINTS 1
        DEFINE  UI_USE_DSS_WINDOW_BUFFER 1

        output  "build/examples/CTXMENU.EXE"

CTXMENU_LOAD_ADDR equ   4200h
CTXMENU_STACK     equ   7F00h

MENU_CMD_CUT      equ   10h
MENU_CMD_COPY     equ   11h
MENU_CMD_PASTE    equ   12h
MENU_CMD_DELETE   equ   13h

        org     CTXMENU_LOAD_ADDR - 512

exe_header:
        db      "EXE"
        db      1
        dw      code_start - exe_header
        dw      0
        dw      ctxmenu_end - code_start
        dw      0, 0, 0
        dw      code_start
        dw      ctxmenu_main
        dw      CTXMENU_STACK
        ds      512 - ($ - exe_header), 0

        org     CTXMENU_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/core/hint.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/menu_bar.asm"
        include "src/widgets/context_menu.asm"

ctxmenu_main:
        call    ui_init
        jp      c, ctxmenu_exit_raw

        ld      a, 0B0h
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      hl, ctxmenu_intro
        ld      a, (ui_theme_hint)
        ld      d, 1
        ld      e, 2
        call    ui_print_z

ctxmenu_loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_RMOUSE
        jr      z, .open
        cp      UI_EVENT_KEY
        jr      nz, ctxmenu_loop
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jr      z, ctxmenu_exit
        jr      ctxmenu_loop
.open:
        ld      hl, ctxmenu_items
        ld      a, (ui_event_mouse_x)
        ld      d, a
        ld      a, (ui_event_mouse_y)
        ld      e, a
        call    ui_context_menu_run
        call    ctxmenu_report
        jr      ctxmenu_loop

; Show "Command: <name>" on the bottom line. In: A = command (0 = none).
ctxmenu_report:
        push    af
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
        pop     af

        or      a
        jr      z, .none
        sub     MENU_CMD_CUT
        add     a, a
        ld      e, a
        ld      d, 0
        ld      hl, ctxmenu_names
        add     hl, de
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        jr      .print
.none:
        ld      hl, ctxmenu_cancelled
.print:
        ld      a, (ui_theme_hint)
        ld      d, 30
        ld      e, 2
        jp      ui_print_z

ctxmenu_exit:
        call    ui_shutdown
ctxmenu_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

ctxmenu_intro:
        db      "Right-click to open a context menu. Click an item to choose, click outside or Esc to dismiss.", 0
ctxmenu_cancelled:
        db      "Command: (cancelled)", 0

; Popup items (same layout as a MenuBar dropdown).
ctxmenu_items:
        db      0, "t", UI_HOTKEY_MOD_NONE, MENU_CMD_CUT
        dw      ctxmenu_lbl_cut
        dw      ctxmenu_hint_cut
        db      0, "c", UI_HOTKEY_MOD_NONE, MENU_CMD_COPY
        dw      ctxmenu_lbl_copy
        dw      ctxmenu_hint_copy
        db      0, "p", UI_HOTKEY_MOD_NONE, MENU_CMD_PASTE
        dw      ctxmenu_lbl_paste
        dw      ctxmenu_hint_paste
        db      UI_FLAG_SEPARATOR, 0, UI_HOTKEY_MOD_NONE, 0
        dw      0, 0
        db      0, "d", UI_HOTKEY_MOD_NONE, MENU_CMD_DELETE
        dw      ctxmenu_lbl_delete
        dw      ctxmenu_hint_delete
        db      UI_MENU_POPUP_END

ctxmenu_lbl_cut:    db " Cu&t ", 0
ctxmenu_lbl_copy:   db " &Copy ", 0
ctxmenu_lbl_paste:  db " &Paste ", 0
ctxmenu_lbl_delete: db " &Delete ", 0

ctxmenu_hint_cut:    db "Cut the selection to the clipboard.", 0
ctxmenu_hint_copy:   db "Copy the selection to the clipboard.", 0
ctxmenu_hint_paste:  db "Paste the clipboard contents.", 0
ctxmenu_hint_delete: db "Delete the selection.", 0

ctxmenu_names:
        dw      ctxmenu_n_cut, ctxmenu_n_copy, ctxmenu_n_paste, ctxmenu_n_delete
ctxmenu_n_cut:    db "Command: Cut", 0
ctxmenu_n_copy:   db "Command: Copy", 0
ctxmenu_n_paste:  db "Command: Paste", 0
ctxmenu_n_delete: db "Command: Delete", 0

ctxmenu_end:
