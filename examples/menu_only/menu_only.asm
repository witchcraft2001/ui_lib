; Minimal menu-only example for modular linking.

        DEFINE  UI_ENABLE_HINTS 1

        output  "build/examples/MENU_ONLY.EXE"

MENU_ONLY_LOAD_ADDR  equ     4200h
MENU_ONLY_STACK      equ     7F00h

MENU_CMD_RUN         equ     10h
MENU_CMD_LOAD        equ     11h
MENU_CMD_ABOUT       equ     12h
MENU_CMD_THEME       equ     13h

        org     MENU_ONLY_LOAD_ADDR - 512

exe_header:
        db      "EXE"               ; signature
        db      1                   ; EXE version
        dw      code_start - exe_header
        dw      0                   ; high word of file offset
        dw      menu_only_end - code_start
        dw      0, 0, 0             ; reserved
        dw      code_start          ; load address
        dw      menu_only_main      ; entry point
        dw      MENU_ONLY_STACK     ; stack
        ds      512 - ($ - exe_header), 0

        org     MENU_ONLY_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/core/hint.asm"
        include "src/draw/text.asm"
        include "src/widgets/menu_bar.asm"

menu_only_main:
        call    ui_init
        jp      c, menu_only_exit_raw

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

menu_only_loop:
        ld      hl, menu_only_intro
        ld      a, (ui_theme_hint)
        ld      d, 4
        ld      e, 8
        call    ui_print_z

        ld      ix, menu_only_bar
        call    ui_menu_bar_run
        cp      UI_CMD_CANCEL
        jr      z, menu_only_exit
        cp      UI_CMD_NONE
        jr      z, menu_only_loop
        call    menu_only_show_command
        jr      menu_only_loop

menu_only_show_command:
        push    af
        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        ld      c, 78
        ld      d, 10
        ld      e, 1
        call    ui_fill_rect
        pop     af

        cp      MENU_CMD_RUN
        jr      z, .run
        cp      MENU_CMD_LOAD
        jr      z, .load
        cp      MENU_CMD_ABOUT
        jr      z, .about
        cp      MENU_CMD_THEME
        jr      z, .theme
        ld      hl, menu_only_unknown
        jr      .print
.run:
        ld      hl, menu_only_run_text
        jr      .print
.load:
        ld      hl, menu_only_load_text
        jr      .print
.about:
        ld      hl, menu_only_about_text
        jr      .print
.theme:
        ld      hl, menu_only_theme_text
.print:
        ld      a, (ui_theme_window_title)
        ld      d, 10
        ld      e, 8
        call    ui_print_z
        ld      c, Dss.WaitKey
        rst     10h
        ret

menu_only_exit:
        call    ui_shutdown
menu_only_exit_raw:
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

menu_only_bar:
        db      0, 0, 80
        dw      menu_only_items

menu_only_items:
        db      1, 0, "f", UI_HOTKEY_MOD_NONE
        dw      menu_only_file_label
        dw      menu_only_file_popup
        db      18
        dw      menu_only_file_hint

        db      9, 0, "o", UI_HOTKEY_MOD_NONE
        dw      menu_only_options_label
        dw      menu_only_options_popup
        db      18
        dw      menu_only_options_hint

        db      21, 0, "h", UI_HOTKEY_MOD_NONE
        dw      menu_only_help_label
        dw      menu_only_help_popup
        db      14
        dw      menu_only_help_hint

        db      UI_MENU_ITEMS_END

menu_only_file_popup:
        db      0, "r", UI_HOTKEY_MOD_NONE, MENU_CMD_RUN
        dw      menu_only_run_label
        dw      menu_only_run_hint
        db      0, "l", UI_HOTKEY_MOD_NONE, MENU_CMD_LOAD
        dw      menu_only_load_label
        dw      menu_only_load_hint
        db      UI_FLAG_DISABLED, "s", UI_HOTKEY_MOD_NONE, UI_CMD_NONE
        dw      menu_only_save_label
        dw      menu_only_save_hint
        db      UI_FLAG_SEPARATOR, 0, UI_HOTKEY_MOD_NONE, 0
        dw      0, 0
        db      0, "x", UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_CANCEL
        dw      menu_only_exit_label
        dw      menu_only_exit_hint
        db      UI_MENU_POPUP_END

menu_only_options_popup:
        db      0, "t", UI_HOTKEY_MOD_NONE, MENU_CMD_THEME
        dw      menu_only_theme_label
        dw      menu_only_theme_hint
        db      UI_FLAG_DISABLED, "m", UI_HOTKEY_MOD_NONE, UI_CMD_NONE
        dw      menu_only_mouse_label
        dw      menu_only_mouse_hint
        db      UI_MENU_POPUP_END

menu_only_help_popup:
        db      0, UI_SCAN_F1, UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC
        db      MENU_CMD_ABOUT
        dw      menu_only_about_label
        dw      menu_only_about_hint
        db      UI_MENU_POPUP_END

menu_only_file_label:
        db      "&File", 0
menu_only_options_label:
        db      "&Options", 0
menu_only_help_label:
        db      "&Help", 0
menu_only_run_label:
        db      "&Run command", 0
menu_only_load_label:
        db      "&Load setup", 0
menu_only_save_label:
        db      "&Save setup", 0
menu_only_exit_label:
        db      "Exit Alt+X", 0
menu_only_theme_label:
        db      "&Theme", 0
menu_only_mouse_label:
        db      "&Mouse", 0
menu_only_about_label:
        db      "About F1", 0

menu_only_file_hint:
        db      "File commands. Enter/F10 opens, Esc closes.", 0
menu_only_options_hint:
        db      "Options menu placeholder.", 0
menu_only_help_hint:
        db      "Help and about commands.", 0
menu_only_run_hint:
        db      "Run command returns MENU_CMD_RUN.", 0
menu_only_load_hint:
        db      "Load command returns MENU_CMD_LOAD.", 0
menu_only_save_hint:
        db      "Save is disabled in this menu-only demo.", 0
menu_only_exit_hint:
        db      "Alt+X exits the menu-only demo.", 0
menu_only_theme_hint:
        db      "Theme placeholder command.", 0
menu_only_mouse_hint:
        db      "Mouse option is disabled in this demo.", 0
menu_only_about_hint:
        db      "F1 returns MENU_CMD_ABOUT without a visible mnemonic.", 0

menu_only_intro:
        db      "Menu-only module demo. Use arrows, Enter, F10, Esc, Alt+X or mouse.", 0
menu_only_run_text:
        db      "Run command selected. Press any key.", 0
menu_only_load_text:
        db      "Load command selected. Press any key.", 0
menu_only_about_text:
        db      "About command selected. Press any key.", 0
menu_only_theme_text:
        db      "Theme placeholder selected. Press any key.", 0
menu_only_unknown:
        db      "Command selected. Press any key.", 0

menu_only_end:
