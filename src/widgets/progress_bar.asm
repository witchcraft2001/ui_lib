; ProgressBar drawing helpers.

UI_PROGRESS_EMPTY_CHAR  equ     0B1h

; ui_draw_progress_bar
; In:  IX=parent window descriptor, IY=progress bar descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_progress_bar:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_PROGRESS_X)
        ld      (ui_progress_base_x), a
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_PROGRESS_Y)
        ld      (ui_progress_base_y), a
        ld      d, a
        ld      a, (iy + UI_PROGRESS_W)
        ld      (ui_progress_width), a
        or      a
        ret     z

        ld      h, 1
        ld      l, a
        ld      a, UI_PROGRESS_EMPTY_CHAR
        push    af
        ld      a, (ui_theme_progress)
        ld      b, a
        pop     af
        call    ui_fill_rect

        ld      a, (iy + UI_PROGRESS_FLAGS)
        bit     3, a
        jr      nz, ui_draw_progress_indeterminate
        call    ui_progress_fill_count
        or      a
        ret     z
        ld      l, a
        ld      h, 1
        ld      a, (ui_progress_base_x)
        ld      e, a
        ld      a, (ui_progress_base_y)
        ld      d, a
        ld      a, " "
        push    af
        ld      a, (ui_theme_progress_fill)
        ld      b, a
        pop     af
        jp      ui_fill_rect

ui_draw_progress_indeterminate:
        ld      a, (ui_progress_width)
        cp      3
        jr      nc, .width_ok
        ld      l, a
        jr      .draw
.width_ok:
        ld      a, (iy + UI_PROGRESS_PHASE)
        ld      c, a
        ld      a, (ui_progress_width)
        cp      c
        jr      c, .reset_phase
        jr      z, .reset_phase
        ld      a, c
        jr      .phase_ok
.reset_phase:
        xor     a
.phase_ok:
        ld      c, a
        ld      a, (ui_progress_width)
        sub     c
        cp      3
        jr      c, .tail
        ld      a, 3
.tail:
        ld      l, a
        ld      a, (ui_progress_base_x)
        add     a, c
        ld      e, a
        jr      .draw_at
.draw:
        ld      a, (ui_progress_base_x)
        ld      e, a
.draw_at:
        ld      a, (ui_progress_base_y)
        ld      d, a
        ld      h, 1
        ld      a, " "
        push    af
        ld      a, (ui_theme_progress_fill)
        ld      b, a
        pop     af
        jp      ui_fill_rect

; ui_progress_bar_tick
; In:  IY=progress bar descriptor in RAM
; Out: none
; Clobbers: AF, B
ui_progress_bar_tick:
        ld      a, (iy + UI_PROGRESS_W)
        or      a
        ret     z
        ld      b, a
        ld      a, (iy + UI_PROGRESS_PHASE)
        inc     a
        cp      b
        jr      c, .store
        xor     a
.store:
        ld      (iy + UI_PROGRESS_PHASE), a
        ret

ui_progress_fill_count:
        ld      a, (iy + UI_PROGRESS_MAX)
        or      a
        jr      z, .zero
        ld      e, a
        ld      d, 0
        ld      a, (iy + UI_PROGRESS_VALUE)
        cp      e
        jr      nc, .full
        ld      c, (iy + UI_PROGRESS_W)
        call    ui_progress_mul_a_c
        ld      c, 0
.div_loop:
        ld      a, h
        or      a
        jr      nz, .subtract
        ld      a, l
        cp      e
        jr      c, .done
.subtract:
        or      a
        sbc     hl, de
        inc     c
        jr      .div_loop
.done:
        ld      a, c
        ret
.full:
        ld      a, (iy + UI_PROGRESS_W)
        ret
.zero:
        xor     a
        ret

ui_progress_mul_a_c:
        ld      h, 0
        ld      l, 0
        ld      d, 0
        ld      e, a
        ld      a, c
        or      a
        ret     z
        ld      b, a
.mul_loop:
        add     hl, de
        djnz    .mul_loop
        ret

ui_progress_base_x:
        db      0
ui_progress_base_y:
        db      0
ui_progress_width:
        db      0
