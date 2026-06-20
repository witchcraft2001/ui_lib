; Minimal UI library demo for Sprinter DSS.

        DEFINE  UI_ENABLE_HINTS 1

        output  "build/demo/UI_DEMO.EXE"

DEMO_LOAD_ADDR  equ     4200h
DEMO_STACK      equ     7F00h

DEMO_CMD_LOAD   equ     10h
DEMO_CMD_THEME  equ     11h
DEMO_CMD_DRIVE  equ     12h
DEMO_CMD_MOUSE  equ     13h
DEMO_CMD_ABOUT  equ     14h

        org     DEMO_LOAD_ADDR - 512

exe_header:
        db      "EXE"               ; signature
        db      1                   ; EXE version
        dw      code_start - exe_header
        dw      0                   ; high word of file offset
        dw      demo_end - code_start
        dw      0, 0, 0             ; reserved
        dw      code_start          ; load address
        dw      demo_main           ; entry point
        dw      DEMO_STACK          ; stack
        ds      512 - ($ - exe_header), 0

        org     DEMO_LOAD_ADDR

code_start:
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/core/hint.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/menu_bar.asm"
        include "src/widgets/button.asm"
        include "src/widgets/text_field.asm"
        include "src/widgets/group_box.asm"
        include "src/widgets/separator.asm"
        include "src/widgets/checkbox.asm"
        include "src/widgets/radio_button.asm"
        include "src/widgets/item_selector.asm"
        include "src/widgets/combo_box.asm"
        include "src/widgets/button_events.asm"
        include "src/widgets/dialog.asm"

demo_main:
        call    ui_init
        jp      c, demo_no_memory
        ld      hl, demo_theme
        call    ui_set_theme

demo_main_menu:
        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen
        ld      ix, demo_menu_bar
        call    ui_menu_bar_run
        cp      UI_CMD_CANCEL
        jp      z, demo_exit
        cp      UI_CMD_NONE
        jr      z, demo_main_menu
        call    demo_menu_placeholder_command
        jr      c, demo_main_menu

        IF UI_USE_DSS_WINDOW_BUFFER
        call    demo_draw_restore_backdrop
        ENDIF

        ld      ix, demo_dialog
        call    ui_dialog_run
        ld      (demo_last_command), a

        IF UI_USE_DSS_WINDOW_BUFFER
        call    demo_pause_after_restore
        call    demo_nested_window_restore_test
        ENDIF

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, demo_window
        call    ui_draw_window
        ld      hl, demo_body_text
        ld      a, (ui_theme_window)
        ld      d, 10
        ld      e, 20
        call    ui_print_z

        ld      a, (demo_last_command)
        cp      UI_CMD_OK
        jr      z, .ok
        ld      hl, demo_cancel_text
        jr      .show_result
.ok:
        ld      hl, demo_ok_text
.show_result:
        ld      a, (ui_theme_window_title)
        ld      d, 12
        ld      e, 29
        call    ui_print_z

        ; Diagnostic line: cmd / mouse pos / focus index, all in hex.
        ld      hl, demo_diag_label
        ld      a, (ui_theme_window)
        ld      d, 14
        ld      e, 20
        call    ui_print_z

        ld      hl, demo_diag_buf
        ld      a, (demo_last_command)
        call    demo_put_hex
        ld      (hl), " "
        inc     hl
        ld      (hl), "X"
        inc     hl
        ld      (hl), "="
        inc     hl
        ld      a, (ui_event_mouse_x)
        call    demo_put_hex
        ld      (hl), " "
        inc     hl
        ld      (hl), "Y"
        inc     hl
        ld      (hl), "="
        inc     hl
        ld      a, (ui_event_mouse_y)
        call    demo_put_hex
        ld      (hl), " "
        inc     hl
        ld      (hl), "F"
        inc     hl
        ld      (hl), "="
        inc     hl
        ld      a, (ui_dialog_focus_index)
        call    demo_put_hex
        ld      (hl), 0
        ld      hl, demo_diag_label_cmd
        ld      a, (ui_theme_hotkey)
        ld      d, 16
        ld      e, 20
        call    ui_print_z
        ld      hl, demo_diag_buf
        ld      a, (ui_theme_hotkey)
        ld      d, 16
        ld      e, 24
        call    ui_print_z

        ld      hl, demo_hint
        ld      a, (ui_theme_hint)
        ld      d, 31
        ld      e, 1
        call    ui_print_z

        ld      c, Dss.WaitKey
        rst     10h

demo_exit:
        call    ui_shutdown
        ld      b, 0
        ld      c, Dss.Exit
        rst     10h

demo_menu_placeholder_command:
        cp      DEMO_CMD_LOAD
        jr      z, .show
        cp      DEMO_CMD_THEME
        jr      z, .show
        cp      DEMO_CMD_DRIVE
        jr      z, .show
        cp      DEMO_CMD_MOUSE
        jr      z, .show
        cp      DEMO_CMD_ABOUT
        jr      z, .show
        or      a
        ret
.show:
        ld      hl, demo_menu_placeholder_text
        ld      a, (ui_theme_hint)
        ld      d, UI_HINT_LINE_ROW
        ld      e, 1
        call    ui_print_z
        ld      c, Dss.WaitKey
        rst     10h
        scf
        ret

; demo_put_hex
; In:  A=byte, HL=destination
; Out: HL advanced past 2 written hex chars.
demo_put_hex:
        push    af
        rrca
        rrca
        rrca
        rrca
        and     0Fh
        call    .nibble
        ld      (hl), a
        inc     hl
        pop     af
        and     0Fh
        call    .nibble
        ld      (hl), a
        inc     hl
        ret
.nibble:
        add     a, "0"
        cp      "9" + 1
        ret     c
        add     a, "A" - "0" - 10
        ret

        IF UI_USE_DSS_WINDOW_BUFFER
demo_draw_restore_backdrop:
        ld      hl, demo_restore_backdrop_1
        ld      a, (ui_theme_window_title)
        ld      d, 7
        ld      e, 19
        call    ui_print_z
        ld      hl, demo_restore_backdrop_2
        ld      a, (ui_theme_hotkey)
        ld      d, 11
        ld      e, 22
        call    ui_print_z
        ld      hl, demo_restore_backdrop_3
        ld      a, (ui_theme_button)
        ld      d, 18
        ld      e, 18
        call    ui_print_z
        ret

demo_pause_after_restore:
        ld      hl, demo_restore_pause_hint
        ld      a, (ui_theme_hint)
        ld      d, 31
        ld      e, 1
        call    ui_print_z
        ld      b, Dss.WaitKey
        ld      c, Dss.K_Clear
        rst     10h
        ret

demo_nested_window_restore_test:
        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen
        ld      hl, demo_nested_backdrop_1
        ld      a, (ui_theme_hotkey)
        ld      d, 8
        ld      e, 14
        call    ui_print_z
        ld      hl, demo_nested_backdrop_2
        ld      a, (ui_theme_window_title)
        ld      d, 19
        ld      e, 18
        call    ui_print_z

        ld      ix, demo_nested_outer_window
        call    ui_window_save_under
        jr      c, .error
        ld      ix, demo_nested_outer_window
        call    ui_draw_window
        ld      hl, demo_nested_outer_text
        ld      a, (ui_theme_window)
        ld      d, 10
        ld      e, 22
        call    ui_print_z

        ld      ix, demo_nested_inner_window
        call    ui_window_save_under
        jr      c, .error
        ld      ix, demo_nested_inner_window
        call    ui_draw_window
        ld      hl, demo_nested_inner_text
        ld      a, (ui_theme_window)
        ld      d, 13
        ld      e, 31
        call    ui_print_z

        ld      hl, demo_nested_step_1
        call    demo_wait_with_hint
        call    ui_window_restore_under
        jr      c, .error
        ld      hl, demo_nested_step_2
        call    demo_wait_with_hint
        call    ui_window_restore_under
        jr      c, .error
        ld      hl, demo_nested_step_3
        call    demo_wait_with_hint
        ret
.error:
        ld      hl, demo_nested_error
        call    demo_wait_with_hint
        ret

demo_wait_with_hint:
        ld      a, (ui_theme_hint)
        ld      d, 31
        ld      e, 1
        call    ui_print_z
        ld      b, Dss.WaitKey
        ld      c, Dss.K_Clear
        rst     10h
        ret
        ENDIF

demo_no_memory:
        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen
        ld      hl, demo_no_memory_text
        ld      a, (ui_theme_window_title)
        ld      d, 12
        ld      e, 18
        call    ui_print_z
        ld      c, Dss.WaitKey
        rst     10h
        jp      demo_exit

demo_window:
        db      15, 4, 50, 20
        dw      demo_title
        db      UI_FRAME_DOUBLE

        IF UI_USE_DSS_WINDOW_BUFFER
demo_nested_outer_window:
        db      18, 6, 44, 14
        dw      demo_nested_outer_title
        db      UI_FRAME_DOUBLE
demo_nested_inner_window:
        db      27, 10, 26, 8
        dw      demo_nested_inner_title
        db      UI_FRAME_SINGLE
        ENDIF

demo_menu_bar:
        db      0, 0, 80
        dw      demo_menu_items

demo_menu_items:
demo_menu_file:
        db      1, 0, "f", UI_HOTKEY_MOD_NONE
        dw      demo_menu_file_label
        dw      demo_menu_file_popup
        db      18
        dw      demo_menu_file_hint
demo_menu_options:
        db      9, 0, "o", UI_HOTKEY_MOD_NONE
        dw      demo_menu_options_label
        dw      demo_menu_options_popup
        db      20
        dw      demo_menu_options_hint
demo_menu_help:
        db      21, 0, "h", UI_HOTKEY_MOD_NONE
        dw      demo_menu_help_label
        dw      demo_menu_help_popup
        db      14
        dw      demo_menu_help_hint
        db      UI_MENU_ITEMS_END

demo_menu_file_popup:
        db      0, "r", UI_HOTKEY_MOD_NONE, UI_CMD_OK
        dw      demo_menu_run_label
        dw      demo_menu_run_hint
        db      UI_FLAG_DISABLED, "s", UI_HOTKEY_MOD_NONE, UI_CMD_NONE
        dw      demo_menu_save_label
        dw      demo_menu_save_hint
        db      0, "l", UI_HOTKEY_MOD_NONE, DEMO_CMD_LOAD
        dw      demo_menu_load_label
        dw      demo_menu_load_hint
        db      0, UI_SCAN_F3, UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_OK
        dw      demo_menu_diag_label
        dw      demo_menu_diag_hint
        db      UI_FLAG_SEPARATOR, 0, UI_HOTKEY_MOD_NONE, 0
        dw      0, 0
        db      0, "x", UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_CANCEL
        dw      demo_menu_exit_label
        dw      demo_menu_exit_hint
        db      UI_MENU_POPUP_END

demo_menu_options_popup:
        db      0, "t", UI_HOTKEY_MOD_NONE, DEMO_CMD_THEME
        dw      demo_menu_theme_label
        dw      demo_menu_theme_hint
        db      0, "d", UI_HOTKEY_MOD_NONE, DEMO_CMD_DRIVE
        dw      demo_menu_drive_label
        dw      demo_menu_drive_hint
        db      UI_FLAG_DISABLED, "s", UI_HOTKEY_MOD_NONE, UI_CMD_NONE
        dw      demo_menu_sound_label
        dw      demo_menu_sound_hint
        db      0, "m", UI_HOTKEY_MOD_NONE, DEMO_CMD_MOUSE
        dw      demo_menu_mouse_label
        dw      demo_menu_mouse_hint
        db      UI_FLAG_SEPARATOR, 0, UI_HOTKEY_MOD_NONE, 0
        dw      0, 0
        db      UI_FLAG_DISABLED, "a", UI_HOTKEY_MOD_NONE, UI_CMD_NONE
        dw      demo_menu_advanced_label
        dw      demo_menu_advanced_hint
        db      UI_MENU_POPUP_END

demo_menu_help_popup:
        db      0, "a", UI_HOTKEY_MOD_NONE, DEMO_CMD_ABOUT
        dw      demo_menu_about_label
        dw      demo_menu_about_hint
        db      UI_MENU_POPUP_END

demo_buttons:
demo_button_ok:
        db      13, 15, UI_FLAG_FOCUSED, UI_CMD_OK, "o"
        dw      demo_ok_label

demo_button_cancel:
        db      28, 15, 0, UI_CMD_CANCEL, "c"
        dw      demo_cancel_label
        db      UI_BUTTONS_END

demo_dialog:
        dw      demo_window
        dw      demo_buttons
        dw      demo_checks
        dw      demo_radios
        dw      demo_groups
        dw      demo_separators
        dw      demo_text_fields
        dw      demo_item_selectors
        dw      demo_combos
        dw      demo_hints

demo_hints:
        dw      demo_hint_text_name
        dw      demo_hint_password
        dw      demo_hint_fast
        dw      demo_hint_safe
        dw      demo_hint_item_selector
        dw      demo_hint_combo
        dw      demo_hint_ok
        dw      demo_hint_cancel

demo_groups:
demo_group_input:
        db      3, 3, 21, 5
        dw      demo_input_title

demo_group_options:
        db      26, 3, 20, 5
        dw      demo_options_title
        db      UI_GROUPS_END

demo_separators:
demo_separator:
        db      0, 9, 0
        db      UI_SEPARATORS_END

demo_checks:
demo_check_password:
        db      5, 5, UI_FLAG_CHECKED, "p"
        dw      demo_check_password_label
        db      UI_CHECKS_END

demo_text_fields:
demo_text_name:
        db      5, 6, 12, 0, "n"
        dw      demo_text_name_buffer
        db      24, 4, 0
        db      UI_TEXT_FIELDS_END

demo_item_selectors:
demo_item_selector_theme:
        db      5, 11, 16, 0, "t"
        dw      demo_item_selector_theme_items
        db      3, 0
        db      UI_ITEM_SELECTORS_END

demo_item_selector_theme_items:
        dw      demo_item_selector_item_tasm
        dw      demo_item_selector_item_fformat
        dw      demo_item_selector_item_blue

demo_combos:
demo_combo_drive:
        db      26, 11, 16, 0, "d"
        dw      demo_combo_drive_items
        db      8, 0, 4
        db      UI_COMBOS_END

demo_combo_drive_items:
        dw      demo_combo_drive_a
        dw      demo_combo_drive_b
        dw      demo_combo_drive_ram
        dw      demo_combo_drive_flash
        dw      demo_combo_drive_rom
        dw      demo_combo_drive_net
        dw      demo_combo_drive_tape
        dw      demo_combo_drive_none

demo_radios:
demo_radio_fast:
        db      28, 5, UI_FLAG_CHECKED, "f"
        dw      demo_radio_fast_label

demo_radio_safe:
        db      28, 6, 0, "s"
        dw      demo_radio_safe_label
        db      UI_RADIOS_END

demo_title:
        db      " Sprinter UI Demo ", 0
demo_menu_file_label:
        db      "&File", 0
demo_menu_options_label:
        db      "&Options", 0
demo_menu_help_label:
        db      "&Help", 0
demo_menu_file_hint:
        db      "File menu: Enter opens commands, Left/Right changes menu.", 0
demo_menu_options_hint:
        db      "Options menu: Enter opens configurable demo choices.", 0
demo_menu_help_hint:
        db      "Help menu: demo information.", 0
demo_menu_run_label:
        db      "&Run dialog", 0
demo_menu_save_label:
        db      "&Save setup", 0
demo_menu_load_label:
        db      "&Load setup", 0
demo_menu_diag_label:
        db      "Diagnostics F3", 0
demo_menu_exit_label:
        db      "Exit Alt+X", 0
demo_menu_theme_label:
        db      "&Theme", 0
demo_menu_drive_label:
        db      "&Drive", 0
demo_menu_sound_label:
        db      "&Sound", 0
demo_menu_mouse_label:
        db      "&Mouse", 0
demo_menu_advanced_label:
        db      "&Advanced", 0
demo_menu_about_label:
        db      "&About", 0
demo_menu_run_hint:
        db      "Run the widget demo dialog.", 0
demo_menu_save_hint:
        db      "Save setup is disabled in this demo.", 0
demo_menu_load_hint:
        db      "Load setup placeholder command.", 0
demo_menu_diag_hint:
        db      "F3 opens diagnostics without a visible mnemonic.", 0
demo_menu_exit_hint:
        db      "Alt+X exits the demo without a visible mnemonic.", 0
demo_menu_theme_hint:
        db      "Theme menu placeholder.", 0
demo_menu_drive_hint:
        db      "Drive menu placeholder.", 0
demo_menu_sound_hint:
        db      "Sound option is disabled in this demo.", 0
demo_menu_mouse_hint:
        db      "Mouse option placeholder.", 0
demo_menu_advanced_hint:
        db      "Advanced options are disabled in this demo.", 0
demo_menu_about_hint:
        db      "About this demo.", 0
demo_menu_placeholder_text:
        db      "Placeholder menu command. Press any key.", 0
demo_input_title:
        db      " Input ", 0
demo_options_title:
        db      " Options ", 0
demo_check_password_label:
        db      "&Password mask", 0
demo_radio_fast_label:
        db      "&Fast mode", 0
demo_radio_safe_label:
        db      "&Safe mode", 0
demo_body_text:
        db      "Last button pressed:", 0
demo_ok_label:
        db      "  &OK  ", 0
demo_cancel_label:
        db      " &Cancel ", 0
demo_hint:
        db      "Use Enter, O, C, Esc or mouse. Press any key to exit.", 0
        IF UI_USE_DSS_WINDOW_BUFFER
demo_restore_backdrop_1:
        db      "DSS window buffer restore test", 0
demo_restore_backdrop_2:
        db      "This text is behind the dialog", 0
demo_restore_backdrop_3:
        db      "Close dialog: this backdrop must reappear", 0
demo_restore_pause_hint:
        db      "Dialog closed. If save/restore works, the backdrop is visible. Press any key.", 0
demo_nested_outer_title:
        db      " Outer ", 0
demo_nested_inner_title:
        db      " Inner ", 0
demo_nested_backdrop_1:
        db      "Nested restore test backdrop line A", 0
demo_nested_backdrop_2:
        db      "Nested restore test backdrop line B", 0
demo_nested_outer_text:
        db      "Outer window content under inner window", 0
demo_nested_inner_text:
        db      "Inner window", 0
demo_nested_step_1:
        db      "Nested test: press key to restore inner window.", 0
demo_nested_step_2:
        db      "Inner restored. Outer content should be intact. Press key.", 0
demo_nested_step_3:
        db      "Outer restored. Backdrop should be intact. Press key.", 0
demo_nested_error:
        db      "Nested restore test failed: save/restore stack returned CF=1.", 0
        ENDIF
demo_hint_text_name:
        db      "Name field: type text, use Left/Right/Home/End, Backspace/Delete.", 0
demo_hint_password:
        db      "Password mask: Space toggles masking for the input field.", 0
demo_hint_fast:
        db      "Fast mode: radio option selected with Space, hotkey or mouse.", 0
demo_hint_safe:
        db      "Safe mode: radio option selected with Space, hotkey or mouse.", 0
demo_hint_item_selector:
        db      "Theme selector: Space, Enter, T or mouse cycles the selected item.", 0
demo_hint_combo:
        db      "Drive combo: Enter, Space, D or mouse opens the dropdown list.", 0
demo_hint_ok:
        db      "OK: Enter, Space, O or mouse confirms the dialog.", 0
demo_hint_cancel:
        db      "Cancel: Esc, C or mouse closes the dialog.", 0
demo_ok_text:
        db      "[ OK ]      cmd=01h", 0
demo_cancel_text:
        db      "[ Cancel ]  cmd=02h  (or Esc key)", 0
demo_item_selector_item_tasm:
        db      "TASM gray", 0
demo_item_selector_item_fformat:
        db      "fformat", 0
demo_item_selector_item_blue:
        db      "Blue BP7", 0
demo_combo_drive_a:
        db      "Drive A:", 0
demo_combo_drive_b:
        db      "Drive B:", 0
demo_combo_drive_ram:
        db      "RAM disk", 0
demo_combo_drive_flash:
        db      "Flash card", 0
demo_combo_drive_rom:
        db      "ROM image", 0
demo_combo_drive_net:
        db      "Network", 0
demo_combo_drive_tape:
        db      "Tape input", 0
demo_combo_drive_none:
        db      "No drive", 0
demo_no_memory_text:
        db      "UI init failed: no DSS memory", 0
demo_diag_label:
        db      "Diagnostics (hex):", 0
demo_diag_label_cmd:
        db      "cmd=", 0
demo_theme:
        db      17h, 70h, 7Fh, 7Eh, 20h, 2Fh
        db      78h, 08h, 1Eh, 70h, 2Eh, 2Eh
        db      17h, 1Fh, 2Fh, 0Fh, 78h
        db      0Eh, 2Eh, 0Eh, 17h, 20h
demo_last_command:
        db      0
demo_diag_buf:
        ds      24, 0
demo_text_name_buffer:
        db      "demo", 0
        ds      21, 0

demo_end:
