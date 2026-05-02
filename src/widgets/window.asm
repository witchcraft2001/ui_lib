; Window drawing and optional background save/restore.

        IFNDEF UI_WINDOW_SAVE_DEPTH
UI_WINDOW_SAVE_DEPTH equ 4
        ENDIF

ui_window_saved_x:
        db      0
ui_window_saved_y:
        db      0
ui_window_saved_w:
        db      0
ui_window_saved_h:
        db      0
ui_window_buffer_page:
        db      0
ui_window_saved_p3:
        db      0
ui_window_save_depth:
        db      0
ui_window_save_offset:
        dw      0
ui_window_save_addr:
        dw      0
ui_window_save_bytes:
        dw      0
ui_window_save_x_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0
ui_window_save_y_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0
ui_window_save_w_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0
ui_window_save_h_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0
ui_window_save_off_lo_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0
ui_window_save_off_hi_stack:
        ds      UI_WINDOW_SAVE_DEPTH, 0

; ui_window_save_under
; In:  IX=window descriptor
; Out: CF=0 on success, CF=1 when DSS buffer is enabled but unavailable
; Clobbers: AF, BC, DE, HL, IX
ui_window_save_under:
        IF UI_USE_DSS_WINDOW_BUFFER
        call    ui_window_calc_save_rect
        call    ui_window_alloc_save_slot
        ret     c
        call    ui_window_prepare_buffer_page
        ret     c
        ld      a, (ui_window_saved_y)
        ld      d, a
        ld      a, (ui_window_saved_x)
        ld      e, a
        ld      a, (ui_window_saved_h)
        ld      h, a
        ld      a, (ui_window_saved_w)
        ld      l, a
        ld      ix, (ui_window_save_addr)
        ld      a, (ui_window_buffer_page)
        ld      b, a
        ld      c, DSS_WINCOPY
        di
        call    ui_call_dss
        ei
        jr      c, .copy_error
        call    ui_window_push_save_slot
        ret
.copy_error:
        call    ui_window_free_pending_slot
        scf
        ret
        ELSE
        or      a
        ret
        ENDIF

; ui_window_restore_under
; In:  none, uses the last saved rectangle
; Out: CF=0 on success, CF=1 when DSS buffer is enabled but unavailable
; Clobbers: AF, BC, DE, HL, IX
ui_window_restore_under:
        IF UI_USE_DSS_WINDOW_BUFFER
        call    ui_window_pop_save_slot
        ret     c
        call    ui_window_prepare_buffer_page
        ret     c
        ld      a, (ui_window_saved_y)
        ld      d, a
        ld      a, (ui_window_saved_x)
        ld      e, a
        ld      a, (ui_window_saved_h)
        ld      h, a
        ld      a, (ui_window_saved_w)
        ld      l, a
        ld      ix, (ui_window_save_addr)
        ld      a, (ui_window_buffer_page)
        ld      b, a
        ld      c, DSS_WINREST
        di
        call    ui_call_dss
        ei
        ret
        ELSE
        or      a
        ret
        ENDIF

        IF UI_USE_DSS_WINDOW_BUFFER
ui_window_alloc_save_slot:
        ld      a, (ui_window_save_depth)
        cp      UI_WINDOW_SAVE_DEPTH
        jr      nc, .error
        call    ui_window_calc_save_bytes
        ld      (ui_window_save_bytes), hl
        ld      de, (ui_window_save_offset)
        add     hl, de
        ld      a, h
        cp      40h
        jr      nc, .error
        ld      hl, (ui_window_save_offset)
        ld      de, 0C000h
        add     hl, de
        ld      (ui_window_save_addr), hl
        or      a
        ret
.error:
        scf
        ret

ui_window_free_pending_slot:
        ret

ui_window_push_save_slot:
        ld      a, (ui_window_save_depth)
        ld      e, a
        ld      d, 0
        ld      hl, ui_window_save_x_stack
        add     hl, de
        ld      a, (ui_window_saved_x)
        ld      (hl), a
        ld      hl, ui_window_save_y_stack
        add     hl, de
        ld      a, (ui_window_saved_y)
        ld      (hl), a
        ld      hl, ui_window_save_w_stack
        add     hl, de
        ld      a, (ui_window_saved_w)
        ld      (hl), a
        ld      hl, ui_window_save_h_stack
        add     hl, de
        ld      a, (ui_window_saved_h)
        ld      (hl), a
        ld      hl, ui_window_save_off_lo_stack
        add     hl, de
        ld      a, (ui_window_save_addr)
        ld      (hl), a
        ld      hl, ui_window_save_off_hi_stack
        add     hl, de
        ld      a, (ui_window_save_addr + 1)
        ld      (hl), a
        ld      hl, (ui_window_save_bytes)
        ld      de, (ui_window_save_offset)
        add     hl, de
        ld      (ui_window_save_offset), hl
        ld      a, (ui_window_save_depth)
        inc     a
        ld      (ui_window_save_depth), a
        or      a
        ret

ui_window_pop_save_slot:
        ld      a, (ui_window_save_depth)
        or      a
        jr      z, .error
        dec     a
        ld      (ui_window_save_depth), a
        ld      e, a
        ld      d, 0
        ld      hl, ui_window_save_x_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_saved_x), a
        ld      hl, ui_window_save_y_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_saved_y), a
        ld      hl, ui_window_save_w_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_saved_w), a
        ld      hl, ui_window_save_h_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_saved_h), a
        ld      hl, ui_window_save_off_lo_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_save_addr), a
        ld      hl, ui_window_save_off_hi_stack
        add     hl, de
        ld      a, (hl)
        ld      (ui_window_save_addr + 1), a
        ld      hl, (ui_window_save_addr)
        ld      de, 0C000h
        or      a
        sbc     hl, de
        ld      (ui_window_save_offset), hl
        or      a
        ret
.error:
        scf
        ret

ui_window_calc_save_bytes:
        ld      a, (ui_window_saved_h)
        ld      b, a
        ld      c, 0
        ld      hl, 0
        ld      a, (ui_window_saved_w)
        add     a, a
        ld      e, a
        ld      d, 0
.loop:
        ld      a, b
        or      a
        ret     z
        add     hl, de
        dec     b
        jr      .loop

ui_window_prepare_buffer_page:
        ld      a, (ui_window_block_id)
        or      a
        jr      z, .error
        in      a, (EmmWin.P3)
        ld      (ui_window_saved_p3), a
        ld      a, (ui_window_block_id)
        ld      b, 0
        ld      c, DSS_SETWIN3
        call    ui_call_dss
        jr      c, .restore_error
        in      a, (EmmWin.P3)
        ld      (ui_window_buffer_page), a
        ld      a, (ui_window_saved_p3)
        out     (EmmWin.P3), a
        or      a
        ret
.restore_error:
        ld      a, (ui_window_saved_p3)
        out     (EmmWin.P3), a
.error:
        scf
        ret

ui_window_calc_save_rect:
        ld      a, (ix + UI_WINDOW_X)
        ld      (ui_window_saved_x), a
        ld      a, (ix + UI_WINDOW_Y)
        ld      (ui_window_saved_y), a

        ld      a, (ix + UI_WINDOW_W)
        add     a, 2
        ld      b, a
        ld      a, UI_SCREEN_COLS
        ld      c, a
        ld      a, (ui_window_saved_x)
        ld      d, a
        ld      a, c
        sub     d
        cp      b
        jr      c, .store_w
        ld      a, b
.store_w:
        ld      (ui_window_saved_w), a

        ld      a, (ix + UI_WINDOW_H)
        inc     a
        ld      b, a
        ld      a, UI_SCREEN_ROWS
        ld      c, a
        ld      a, (ui_window_saved_y)
        ld      d, a
        ld      a, c
        sub     d
        cp      b
        jr      c, .store_h
        ld      a, b
.store_h:
        ld      (ui_window_saved_h), a
        ret
        ENDIF

; ui_draw_window
; In:  IX=window descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_window:
        call    ui_draw_window_shadow
        ld      e, (ix + UI_WINDOW_X)
        ld      d, (ix + UI_WINDOW_Y)
        ld      l, (ix + UI_WINDOW_W)
        ld      h, (ix + UI_WINDOW_H)
        ld      a, " "
        push    af
        ld      a, (ui_theme_window)
        ld      b, a
        pop     af
        call    ui_fill_rect
        call    ui_draw_window_frame
        call    ui_draw_window_title
        ret

ui_draw_window_shadow:
        ld      a, (ix + UI_WINDOW_X)
        add     a, (ix + UI_WINDOW_W)
        cp      UI_SCREEN_COLS
        jr      nc, .bottom
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        inc     a
        cp      UI_SCREEN_ROWS
        jr      nc, .bottom
        ld      d, a
        ld      h, (ix + UI_WINDOW_H)
        ld      l, 2
        ld      a, " "
        push    af
        ld      a, (ui_theme_shadow)
        ld      b, a
        pop     af
        call    ui_fill_rect
.bottom:
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (ix + UI_WINDOW_H)
        cp      UI_SCREEN_ROWS
        ret     nc
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        inc     a
        inc     a
        cp      UI_SCREEN_COLS
        ret     nc
        ld      e, a
        ld      h, 1
        ld      l, (ix + UI_WINDOW_W)
        ld      a, " "
        push    af
        ld      a, (ui_theme_shadow)
        ld      b, a
        pop     af
        call    ui_fill_rect
        ret

ui_draw_window_frame:
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C9h
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.top:
        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0CDh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .top

        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0BBh
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_H)
        sub     2
        ld      c, a
.sides:
        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0BAh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ix + UI_WINDOW_W)
        dec     a
        add     a, e
        ld      e, a
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0BAh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0C8h
        push    de
        call    ui_put_cell
        pop     de

        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      c, a
.bottom:
        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0CDh
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .bottom

        inc     e
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, 0BCh
        call    ui_put_cell
        ret

ui_draw_window_title:
        ld      l, (ix + UI_WINDOW_TITLE)
        ld      h, (ix + UI_WINDOW_TITLE + 1)
        ld      a, h
        or      l
        ret     z
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        inc     e
        inc     e
        ld      a, (ui_theme_window_title)
        call    ui_print_z
        ret
