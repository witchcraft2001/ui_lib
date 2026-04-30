; Button drawing. '&' in label marks the hot character.

; ui_button_visible_width
; In:  HL=button label ASCIIZ with optional '&'
; Out: B=visible width
; Clobbers: AF, HL
ui_button_visible_width:
        ld      b, 0
.loop:
        ld      a, (hl)
        or      a
        ret     z
        cp      "&"
        jr      z, .skip_marker
        inc     b
        inc     hl
        jr      .loop
.skip_marker:
        inc     hl
        ld      a, (hl)
        or      a
        ret     z
        inc     b
        inc     hl
        jr      .loop

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
        ld      a, (ui_theme_button)
        jr      .have_color
.focused:
        ld      a, (ui_theme_button_focus)
        jr      .have_color
.disabled:
        ld      a, (ui_theme_disabled)
.have_color:
        ld      (ui_button_attr), a
        ld      a, (iy + UI_BUTTON_FLAGS)
        bit     6, a
        jr      nz, .focused_hotkey
        ld      a, (ui_theme_button_hotkey)
        jr      .have_hotkey_color
.focused_hotkey:
        ld      a, (ui_theme_button_focus_hotkey)
.have_hotkey_color:
        ld      (ui_button_hotkey_attr), a
        call    ui_clear_button_area
        ld      a, (iy + UI_BUTTON_FLAGS)
        bit     5, a
        jr      nz, .pressed
        call    ui_draw_button_shadow
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        ld      e, a
        jr      .have_pos
.pressed:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        inc     a
        ld      e, a
.have_pos:
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
        ld      (ui_button_char), a
        ld      a, (ui_button_hotkey_attr)
        ld      b, a
        ld      a, (ui_button_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop
.normal:
        push    hl
        push    de
        ld      (ui_button_char), a
        ld      a, (ui_button_attr)
        ld      b, a
        ld      a, (ui_button_char)
        call    ui_put_cell
        pop     de
        pop     hl
        inc     hl
        inc     e
        jr      .loop

ui_button_attr:
        db      0
ui_button_char:
        db      0
ui_button_width:
        db      0
ui_button_hotkey_attr:
        db      0

ui_clear_button_area:
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        call    ui_button_visible_width
        ld      a, b
        or      a
        ret     z
        ld      (ui_button_width), a

        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_BUTTON_Y)
        ld      d, a
        ld      h, 2
        ld      a, (ui_button_width)
        add     a, 2
        ld      l, a
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ret

ui_draw_button_shadow:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        ld      c, a
        ld      a, (ui_button_width)
        add     a, c
        cp      UI_SCREEN_COLS
        ld      e, a
        jr      nc, .bottom
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_BUTTON_Y)
        cp      UI_SCREEN_ROWS
        jr      nc, .bottom
        ld      d, a
        ld      a, (ui_theme_button_shadow)
        ld      b, a
        ld      a, 0DCh
        call    ui_put_cell

.bottom:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_BUTTON_Y)
        inc     a
        cp      UI_SCREEN_ROWS
        ret     nc
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        inc     a
        cp      UI_SCREEN_COLS
        ret     nc
        ld      e, a
        ld      a, (ui_button_width)
        ld      c, a
.bottom_loop:
        ld      a, (ui_theme_button_shadow)
        ld      b, a
        ld      a, 0DFh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        inc     e
        dec     c
        jr      nz, .bottom_loop
        ret

; ui_button_press_key_feedback
; In:  IX=parent window descriptor, IY=button descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_button_press_key_feedback:
        set     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        call    ui_button_press_delay
        call    ui_wait_key_release
        res     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        ret

; ui_button_press_mouse_feedback
; In:  IX=parent window descriptor, IY=button descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_button_press_mouse_feedback:
        set     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        call    ui_button_press_delay
        call    ui_wait_mouse_release
        res     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        ret

ui_wait_mouse_release:
        ld      a, (ui_mouse_available)
        or      a
        ret     z
.loop:
        ld      c, BIOS_MOUSE_REFRESH
        rst     30h
        ld      c, BIOS_MOUSE_READ
        rst     30h
        ret     c
        and     01h
        ret     z
        halt
        jr      .loop

ui_wait_key_release:
        ld      b, 20
.loop:
        push    bc
        ld      c, DSS_TESTKEY
        rst     10h
        pop     bc
        jr      nz, .consume
        halt
        djnz    .loop
        ret
.consume:
        push    bc
        ld      c, DSS_SCANKEY
        rst     10h
        pop     bc
        ld      b, 20
        halt
        jr      .loop
        ret

ui_button_press_delay:
        ld      b, 3
.loop:
        halt
        djnz    .loop
        ret
