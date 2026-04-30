; CheckBox drawing and state helpers.

; ui_draw_checkbox
; In:  IX=parent window descriptor, IY=checkbox descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_checkbox:
        call    ui_checkbox_attr
        ld      (ui_checkbox_attr_value), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_CHECK_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_CHECK_Y)
        ld      d, a
        ld      a, "["
        call    ui_checkbox_put
        inc     e
        ld      a, (iy + UI_CHECK_FLAGS)
        bit     0, a
        ld      a, " "
        jr      z, .mark
        ld      a, "X"
.mark:
        call    ui_checkbox_put
        inc     e
        ld      a, "]"
        call    ui_checkbox_put
        inc     e
        inc     e
        ld      l, (iy + UI_CHECK_LABEL)
        ld      h, (iy + UI_CHECK_LABEL + 1)
        jp      ui_checkbox_print_label

; ui_toggle_checkbox
; In:  IY=checkbox descriptor
; Out: none
; Clobbers: AF
ui_toggle_checkbox:
        ld      a, (iy + UI_CHECK_FLAGS)
        bit     7, a
        ret     nz
        xor     UI_FLAG_CHECKED
        ld      (iy + UI_CHECK_FLAGS), a
        ret

ui_checkbox_attr:
        ld      a, (iy + UI_CHECK_FLAGS)
        bit     7, a
        jr      nz, .disabled
        bit     6, a
        jr      nz, .focused
        ld      a, (ui_theme_window)
        ret
.focused:
        ld      a, (ui_theme_button_focus)
        ret
.disabled:
        ld      a, (ui_theme_disabled)
        ret

ui_checkbox_put:
        push    af
        ld      a, (ui_checkbox_attr_value)
        ld      b, a
        pop     af
        call    ui_put_cell
        ret

ui_checkbox_print_label:
        ld      a, (hl)
        or      a
        ret     z
        cp      "&"
        jr      nz, .normal
        inc     hl
        ld      a, (hl)
        or      a
        ret     z
        push    hl
        push    de
        ld      (ui_checkbox_char), a
        ld      a, (ui_theme_hotkey)
        ld      b, a
        ld      a, (ui_checkbox_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      ui_checkbox_print_label
.normal:
        push    hl
        push    de
        ld      (ui_checkbox_char), a
        ld      a, (ui_checkbox_attr_value)
        ld      b, a
        ld      a, (ui_checkbox_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      ui_checkbox_print_label

ui_checkbox_attr_value:
        db      0
ui_checkbox_char:
        db      0
