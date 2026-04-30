; Button drawing. '&' in label marks the hot character.

; ui_draw_button
; In:  IX=parent window descriptor, IY=button descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_button:
        ld      a, (iy + UI_BUTTON_FLAGS)
        bit     7, a
        jr      nz, .disabled
        bit     6, a
        jr      nz, .focused
        ld      a, UI_COLOR_BUTTON
        jr      .have_color
.focused:
        ld      a, UI_COLOR_BUTTON_FOCUS
        jr      .have_color
.disabled:
        ld      a, UI_COLOR_DISABLED
.have_color:
        ld      (ui_button_attr), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_BUTTON_Y)
        ld      d, a
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
.loop:
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
        ld      b, UI_COLOR_HOTKEY
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop
.normal:
        push    hl
        push    de
        ld      a, (ui_button_attr)
        ld      b, a
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop

ui_button_attr:
        db      0
