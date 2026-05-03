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
; Display the pressed visual and hold it until the mouse button is released.
; While held, the cursor position is sampled each frame. On release, the last
; sampled position is hit-tested against the widget: if the cursor is still
; over the button, return CF=0 (commit); otherwise return CF=1 (cancel) so the
; caller can suppress the click action.
; In:  IX=parent window descriptor, IY=button descriptor
; Out: CF=0 click committed (released over button), CF=1 cancelled
; Clobbers: AF, BC, DE, HL
ui_button_press_mouse_feedback:
        set     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        ; Seed the latest cursor position from the click event so that hit
        ; testing has a valid coordinate even if no further mouse reads happen.
        ld      a, (ui_event_mouse_x)
        ld      (ui_button_last_x), a
        ld      a, (ui_event_mouse_y)
        ld      (ui_button_last_y), a
        ; Mandatory minimum visible press time so the user always sees the
        ; pressed visual even on very fast clicks.
        ld      b, 4
.min_hold:
        halt
        djnz    .min_hold
        ld      a, (ui_mouse_available)
        or      a
        jr      z, .commit
.wait_loop:
        push    ix
        push    iy
        ld      c, Bios.Mouse_Read
        rst     30h
        pop     iy
        pop     ix
        jr      c, .commit
        and     01h               ; only the left button gates the press
        jr      z, .check_position
        ; Buttons still pressed: refresh the saved position. Skip this when
        ; released - some drivers return a stale or zero position when no
        ; buttons are held, which would defeat the cursor-on-button check.
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ld      a, l
        ld      (ui_button_last_x), a
        srl     d
        rr      e
        srl     d
        rr      e
        srl     d
        rr      e
        ld      a, e
        ld      (ui_button_last_y), a
        halt
        jr      .wait_loop
.check_position:
        ld      a, (ui_button_last_x)
        ld      hl, ui_button_last_y
        ld      b, (hl)
        call    ui_button_hit_test
        jr      c, .cancel
.commit:
        res     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        xor     a
        ld      (ui_mouse_prev_buttons), a
        ld      (ui_event_mouse_buttons), a
        or      a
        ret
.cancel:
        res     5, (iy + UI_BUTTON_FLAGS)
        call    ui_draw_button
        xor     a
        ld      (ui_mouse_prev_buttons), a
        ld      (ui_event_mouse_buttons), a
        scf
        ret

ui_button_last_x:
        db      0
ui_button_last_y:
        db      0

ui_wait_key_release:
        ld      b, 20
.loop:
        push    bc
        ld      c, Dss.TestKey
        rst     10h
        pop     bc
        jr      nz, .consume
        halt
        djnz    .loop
        ret
.consume:
        push    bc
        ld      c, Dss.ScanKey
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
