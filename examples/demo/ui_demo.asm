; Minimal UI library demo for Sprinter DSS.

        output  "build/demo/UI_DEMO.EXE"

DEMO_LOAD_ADDR  equ     4200h
DEMO_STACK      equ     7F00h

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
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"
        include "src/widgets/text_field.asm"
        include "src/widgets/group_box.asm"
        include "src/widgets/separator.asm"
        include "src/widgets/checkbox.asm"
        include "src/widgets/radio_button.asm"
        include "src/widgets/button_events.asm"
        include "src/widgets/dialog.asm"

demo_main:
        call    ui_init
        jp      c, demo_no_memory
        ld      hl, demo_theme
        call    ui_set_theme

        ld      a, " "
        push    af
        ld      a, (ui_theme_desktop)
        ld      b, a
        pop     af
        call    ui_clear_screen

        ld      ix, demo_dialog
        call    ui_dialog_run
        ld      (demo_last_command), a

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

        ld      c, DSS_WAITKEY
        rst     10h

demo_exit:
        call    ui_shutdown
        ld      b, 0
        ld      c, DSS_EXIT
        rst     10h

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
        ld      c, DSS_WAITKEY
        rst     10h
        jr      demo_exit

demo_window:
        db      15, 4, 50, 20
        dw      demo_title

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
        db      3, 9, 44
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
        db      12, 4
        db      UI_TEXT_FIELDS_END

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
demo_ok_text:
        db      "[ OK ]      cmd=01h", 0
demo_cancel_text:
        db      "[ Cancel ]  cmd=02h  (or Esc key)", 0
demo_no_memory_text:
        db      "UI init failed: no DSS memory", 0
demo_diag_label:
        db      "Diagnostics (hex):", 0
demo_diag_label_cmd:
        db      "cmd=", 0
demo_theme:
        db      17h, 70h, 7Fh, 7Eh, 20h, 2Fh
        db      78h, 08h, 1Eh, 70h, 2Eh, 2Eh
        db      07h, 0Fh
demo_last_command:
        db      0
demo_diag_buf:
        ds      24, 0
demo_text_name_buffer:
        db      "demo", 0
        ds      9, 0

demo_end:
