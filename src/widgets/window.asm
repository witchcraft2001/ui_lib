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

; Active glyph set copied from the style table at draw time:
; top-left, horizontal, top-right, vertical, bottom-left, bottom-right.
ui_frame_tl:
        db      0
ui_frame_h:
        db      0
ui_frame_tr:
        db      0
ui_frame_v:
        db      0
ui_frame_bl:
        db      0
ui_frame_br:
        db      0

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
        ld      c, Dss.WinCopy
        call    ui_window_save_iff
        di
        call    ui_call_dss
        push    af
        call    ui_window_restore_iff
        pop     af
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
        call    ui_window_peek_save_slot
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
        ld      c, Dss.WinRest
        call    ui_window_save_iff
        di
        call    ui_call_dss
        push    af
        call    ui_window_restore_iff
        pop     af
        ret     c
        call    ui_window_commit_restore_slot
        ret

; Capture the caller's interrupt-enable state, then re-enable it only if it
; was on. Keeps DI/EI balanced around DSS window-buffer calls instead of
; force-enabling interrupts the caller may have intentionally masked.
ui_window_save_iff:
        push    af
        ld      a, i            ; P/V = IFF2
        ld      a, 0
        jp      po, .masked
        inc     a
.masked:
        ld      (ui_window_saved_iff), a
        pop     af
        ret

ui_window_restore_iff:
        push    af
        ld      a, (ui_window_saved_iff)
        or      a
        jr      z, .done
        ei
.done:
        pop     af
        ret

ui_window_saved_iff:
        db      0
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

ui_window_peek_save_slot:
        ld      a, (ui_window_save_depth)
        or      a
        jr      z, .error
        dec     a
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
        or      a
        ret
.error:
        scf
        ret

ui_window_commit_restore_slot:
        ld      hl, (ui_window_save_addr)
        ld      de, 0C000h
        or      a
        sbc     hl, de
        ld      (ui_window_save_offset), hl
        ld      a, (ui_window_save_depth)
        dec     a
        ld      (ui_window_save_depth), a
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
        ld      c, Dss.SetWin3
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
        ld      a, (ui_theme_shadow)
        ld      b, a
        call    ui_shade_rect
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
        ld      a, (ui_theme_shadow)
        ld      b, a
        jp      ui_shade_rect

; ui_window_load_frame_glyphs
; Copies the six glyphs for the descriptor's frame style into the active set.
; In:  IX = window descriptor (UI_WINDOW_FRAME selects the style)
; Clobbers: AF, BC, DE, HL
ui_window_load_frame_glyphs:
        ld      a, (ix + UI_WINDOW_FRAME)
        dec     a                       ; UI_FRAME_SINGLE -> 0
        ld      hl, ui_frame_glyphs_single
        jr      z, .copy
        ld      hl, ui_frame_glyphs_double
.copy:
        ld      de, ui_frame_tl
        ld      bc, 6
        ldir
        ret

; Glyph order: top-left, horizontal, top-right, vertical, bottom-left,
; bottom-right. CP866 box-drawing characters.
ui_frame_glyphs_double:
        db      0C9h, 0CDh, 0BBh, 0BAh, 0C8h, 0BCh
ui_frame_glyphs_single:
        db      0DAh, 0C4h, 0BFh, 0B3h, 0C0h, 0D9h

ui_draw_window_frame:
        call    ui_window_load_frame_glyphs

        ; top-left corner
        ld      d, (ix + UI_WINDOW_Y)
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_tl)
        call    ui_put_cell

        ; top edge as one horizontal run
        ld      d, (ix + UI_WINDOW_Y)
        ld      a, (ix + UI_WINDOW_X)
        inc     a
        ld      e, a
        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_h)
        call    ui_fill_rect

        ; top-right corner
        ld      d, (ix + UI_WINDOW_Y)
        ld      a, (ix + UI_WINDOW_X)
        add     a, (ix + UI_WINDOW_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_tr)
        call    ui_put_cell

        ld      d, (ix + UI_WINDOW_Y)
        ld      a, (ix + UI_WINDOW_H)
        sub     2
        ld      c, a
.sides:
        inc     d
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_v)
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
        ld      a, (ui_frame_v)
        push    bc
        push    de
        call    ui_put_cell
        pop     de
        pop     bc
        dec     c
        jr      nz, .sides

        ; bottom-left corner
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (ix + UI_WINDOW_H)
        dec     a
        ld      d, a
        ld      e, (ix + UI_WINDOW_X)
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_bl)
        call    ui_put_cell

        ; bottom edge as one horizontal run
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (ix + UI_WINDOW_H)
        dec     a
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        inc     a
        ld      e, a
        ld      a, (ix + UI_WINDOW_W)
        sub     2
        ld      l, a
        ld      h, 1
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_h)
        call    ui_fill_rect

        ; bottom-right corner
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (ix + UI_WINDOW_H)
        dec     a
        ld      d, a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (ix + UI_WINDOW_W)
        dec     a
        ld      e, a
        ld      a, (ui_theme_window_title)
        ld      b, a
        ld      a, (ui_frame_br)
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
