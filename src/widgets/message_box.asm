; MessageBox: a modal notification dialog with word-wrapped text, an optional
; title, a configurable body colour and one to three buttons.
; Requires window.asm, button.asm, button_events.asm and draw/text.asm.

UI_MSG_WRAP_W    equ    44          ; text is measured at this width, then the
                                    ; window shrinks to the longest actual line
UI_MSG_MIN_W     equ    20          ; minimum content width
UI_MSG_MAX_LINES equ    20          ; cap so the window fits on screen

; ui_message_box
; In:  HL = message text ASCIIZ (required)
;      DE = title ASCIIZ, or 0 for no title
;      A  = button set (UI_MSG_OK / OKCANCEL / YESNO / YESNOCANCEL /
;           ABORTRETRYIGNORE)
;      B  = body attribute, or 0 to use the theme default (UI_THEME_WINDOW)
; Out: A  = result code (UI_MSG_RESULT_*)
; Clobbers: AF, BC, DE, HL, IX, IY
ui_message_box:
        ld      (ui_msg_text), hl
        ld      (ui_msg_title), de
        ld      (ui_msg_set), a
        ld      a, b
        ld      (ui_msg_bg), a

        ld      a, (ui_msg_set)
        call    ui_msg_build_buttons

        ld      a, UI_MSG_WRAP_W
        ld      (ui_msg_wrap_w), a
        ld      hl, (ui_msg_text)
        ld      (ui_msg_cursor), hl
        call    ui_msg_measure
        call    ui_msg_layout

        ; optional body colour override (restored on exit). The frame and the
        ; button shadow are recoloured to the same background so they do not
        ; show the default gray over a custom body.
        ld      a, (ui_msg_bg)
        or      a
        jr      z, .nobg
        ld      a, (ui_theme_window)
        ld      (ui_msg_saved_win), a
        ld      a, (ui_theme_window_title)
        ld      (ui_msg_saved_title), a
        ld      a, (ui_theme_button_shadow)
        ld      (ui_msg_saved_btnsh), a
        ld      a, (ui_msg_bg)
        ld      (ui_theme_window), a
        and     0F0h
        ld      c, a                    ; body background nibble, black foreground
        ld      (ui_theme_button_shadow), a
        ld      a, c
        or      0Fh                     ; same background, white frame/title text
        ld      (ui_theme_window_title), a
        ld      a, 1
        ld      (ui_msg_bg_over), a
        jr      .bgset
.nobg:
        xor     a
        ld      (ui_msg_bg_over), a
.bgset:
        call    ui_msg_save_under
        call    ui_msg_draw_all
        call    ui_msg_loop
        ld      (ui_msg_result), a
        call    ui_msg_restore_under

        ld      a, (ui_msg_bg_over)
        or      a
        jr      z, .done
        ld      a, (ui_msg_saved_win)
        ld      (ui_theme_window), a
        ld      a, (ui_msg_saved_title)
        ld      (ui_theme_window_title), a
        ld      a, (ui_msg_saved_btnsh)
        ld      (ui_theme_button_shadow), a
.done:
        ld      a, (ui_msg_result)
        ret

; Fill the button descriptors from the chosen set.
; In: A = button set
ui_msg_build_buttons:
        add     a, a
        add     a, a                    ; *4 = dispatch entry size
        ld      e, a
        ld      d, 0
        ld      hl, ui_msg_dispatch
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = entries pointer
        inc     hl
        ld      a, (hl)
        ld      (ui_msg_count), a
        inc     hl
        ld      a, (hl)
        ld      (ui_msg_esc_result), a

        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
        ld      c, UI_FLAG_FOCUSED      ; first button is the default
.fill:
        ld      a, (de)
        ld      (iy + UI_BUTTON_LABEL), a
        inc     de
        ld      a, (de)
        ld      (iy + UI_BUTTON_LABEL + 1), a
        inc     de
        ld      a, (de)
        ld      (iy + UI_BUTTON_COMMAND), a
        inc     de
        ld      a, (de)
        ld      (iy + UI_BUTTON_HOTKEY), a
        inc     de
        ld      a, c
        ld      (iy + UI_BUTTON_FLAGS), a
        ld      c, 0
        push    de
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     de
        djnz    .fill
        xor     a
        ld      (ui_msg_focus), a
        ret

; Count wrapped lines and the longest line into ui_msg_nlines / ui_msg_maxlen.
ui_msg_measure:
        xor     a
        ld      (ui_msg_nlines), a
        ld      (ui_msg_maxlen), a
.loop:
        call    ui_msg_next_line
        push    af
        ld      a, (ui_msg_nlines)
        inc     a
        ld      (ui_msg_nlines), a
        ld      a, (ui_msg_line_len)
        ld      hl, ui_msg_maxlen
        cp      (hl)
        jr      c, .nomax
        ld      (hl), a
.nomax:
        ld      a, (ui_msg_nlines)
        cp      UI_MSG_MAX_LINES
        jr      nc, .capped
        pop     af
        jr      c, .done
        jr      .loop
.capped:
        pop     af
.done:
        ret

; Extract the next wrapped line (greedy, word-aware).
; Uses ui_msg_cursor and ui_msg_wrap_w; sets ui_msg_line_start / ui_msg_line_len
; and advances ui_msg_cursor. Out: CF=1 if this was the last line.
ui_msg_next_line:
        ld      hl, (ui_msg_cursor)
        ld      (ui_msg_line_start), hl
        xor     a
        ld      (.len), a
        ld      (.hasbreak), a
.loop:
        ld      hl, (ui_msg_cursor)
        ld      a, (hl)
        or      a
        jr      z, .endstr
        cp      0Ah
        jr      z, .newline
        cp      " "
        jr      nz, .notspace
        ld      a, (.len)
        ld      (.bbestlen), a
        ld      a, 1
        ld      (.hasbreak), a
        ld      hl, (ui_msg_cursor)
        inc     hl
        ld      (.bbestptr), hl
.notspace:
        ld      a, (.len)
        inc     a
        ld      (.len), a
        ld      hl, (ui_msg_cursor)
        inc     hl
        ld      (ui_msg_cursor), hl
        ld      a, (ui_msg_wrap_w)
        ld      b, a
        ld      a, (.len)
        cp      b
        jr      z, .loop                ; len == width, keep going
        jr      c, .loop                ; len < width
        ld      a, (.hasbreak)          ; len > width: break
        or      a
        jr      z, .hardbreak
        ld      a, (.bbestlen)
        ld      (ui_msg_line_len), a
        ld      hl, (.bbestptr)
        ld      (ui_msg_cursor), hl
        or      a
        ret
.hardbreak:
        ld      a, (ui_msg_wrap_w)
        ld      (ui_msg_line_len), a
        ld      hl, (ui_msg_line_start)
        ld      a, (ui_msg_wrap_w)
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      (ui_msg_cursor), hl
        or      a
        ret
.newline:
        ld      a, (.len)
        ld      (ui_msg_line_len), a
        ld      hl, (ui_msg_cursor)
        inc     hl
        ld      (ui_msg_cursor), hl
        or      a
        ret
.endstr:
        ld      a, (.len)
        ld      (ui_msg_line_len), a
        scf
        ret
.len:
        db      0
.hasbreak:
        db      0
.bbestlen:
        db      0
.bbestptr:
        dw      0

; Compute window geometry and button positions from the measured text.
ui_msg_layout:
        ; buttons row width = sum(visible widths) + 2*(count-1)
        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
        ld      c, 0
.wb:
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        push    bc
        call    ui_button_visible_width
        ld      a, b
        pop     bc
        add     a, c
        ld      c, a
        push    de
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     de
        djnz    .wb
        ld      a, (ui_msg_count)
        dec     a
        add     a, a
        add     a, c
        ld      (ui_msg_btn_w), a

        ; content width = max(maxlen, btn_w, MIN)
        ld      a, (ui_msg_maxlen)
        ld      c, a
        ld      a, (ui_msg_btn_w)
        cp      c
        jr      c, .c1
        ld      c, a
.c1:
        ld      a, UI_MSG_MIN_W
        cp      c
        jr      c, .c2
        ld      c, a
.c2:
        ld      a, c
        add     a, 4                    ; + 2 margin + 2 frame
        ld      (ui_msg_window + UI_WINDOW_W), a
        ld      a, (ui_msg_nlines)
        add     a, 6
        ld      (ui_msg_window + UI_WINDOW_H), a

        ld      a, UI_SCREEN_COLS
        ld      hl, ui_msg_window + UI_WINDOW_W
        sub     (hl)
        srl     a
        ld      (ui_msg_window + UI_WINDOW_X), a
        ld      a, UI_SCREEN_ROWS
        ld      hl, ui_msg_window + UI_WINDOW_H
        sub     (hl)
        srl     a
        ld      (ui_msg_window + UI_WINDOW_Y), a

        ld      hl, (ui_msg_title)
        ld      a, l
        ld      (ui_msg_window + UI_WINDOW_TITLE), a
        ld      a, h
        ld      (ui_msg_window + UI_WINDOW_TITLE + 1), a
        ld      a, UI_FRAME_DOUBLE
        ld      (ui_msg_window + UI_WINDOW_FRAME), a

        ; button row Y (relative) and centred start X (relative)
        ld      a, (ui_msg_window + UI_WINDOW_H)
        sub     3
        ld      (ui_msg_btn_y), a
        ld      a, (ui_msg_window + UI_WINDOW_W)
        ld      hl, ui_msg_btn_w
        sub     (hl)
        srl     a
        ld      c, a                    ; running relative X

        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
.pos:
        ld      a, c
        ld      (iy + UI_BUTTON_X), a
        ld      a, (ui_msg_btn_y)
        ld      (iy + UI_BUTTON_Y), a
        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        push    bc
        call    ui_button_visible_width
        ld      a, b
        pop     bc
        add     a, c
        add     a, 2                    ; gap between buttons
        ld      c, a
        push    de
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     de
        djnz    .pos
        ret

; Draw the window, the wrapped text and the buttons.
ui_msg_draw_all:
        ld      ix, ui_msg_window
        call    ui_draw_window

        ld      a, (ui_msg_window + UI_WINDOW_W)
        sub     4
        ld      (ui_msg_wrap_w), a
        ld      hl, (ui_msg_text)
        ld      (ui_msg_cursor), hl
        ld      a, (ui_msg_window + UI_WINDOW_Y)
        add     a, 2
        ld      d, a
        ld      a, (ui_msg_window + UI_WINDOW_X)
        add     a, 2
        ld      e, a
        ld      a, (ui_theme_window)
        call    ui_msg_draw_text

        ld      ix, ui_msg_window
        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
.bl:
        push    bc
        call    ui_draw_button
        pop     bc
        push    bc
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     bc
        djnz    .bl
        ret

; Draw up to ui_msg_nlines wrapped lines.
; In: D=row, E=col, A=attribute; ui_msg_wrap_w and ui_msg_cursor set.
ui_msg_draw_text:
        ld      (ui_msg_text_attr), a
        ld      a, d
        ld      (ui_msg_text_row), a
        ld      a, e
        ld      (ui_msg_text_col), a
        ld      a, (ui_msg_nlines)
        ld      (ui_msg_draw_remain), a
.loop:
        ld      a, (ui_msg_draw_remain)
        or      a
        ret     z
        dec     a
        ld      (ui_msg_draw_remain), a
        call    ui_msg_next_line
        push    af
        ld      a, (ui_msg_line_len)
        or      a
        jr      z, .blank
        ld      hl, (ui_msg_line_start)
        ld      a, (ui_msg_text_row)
        ld      d, a
        ld      a, (ui_msg_text_col)
        ld      e, a
        ld      a, (ui_msg_line_len)
        ld      b, a
        ld      a, (ui_msg_text_attr)
        call    ui_msg_print_n
.blank:
        ld      a, (ui_msg_text_row)
        inc     a
        ld      (ui_msg_text_row), a
        pop     af
        jr      c, .done
        jr      .loop
.done:
        ret

; Print B characters from HL at D=row, E=col with attribute A. Sets the cursor
; once and relies on BIOS auto-advance.
ui_msg_print_n:
        ld      (.attr), a
        ld      a, b
        ld      (.n), a
        or      a
        ret     z
        push    ix
        push    iy
        ld      c, Bios.Lp_Set_Place
        call    ui_call_bios
.loop:
        ld      a, (.n)
        or      a
        jr      z, .done
        dec     a
        ld      (.n), a
        ld      a, (hl)
        push    hl
        ld      c, a
        ld      a, (.attr)
        ld      e, a
        ld      a, c
        ld      b, 1
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     hl
        inc     hl
        jr      .loop
.done:
        pop     iy
        pop     ix
        ret
.attr:
        db      0
.n:
        db      0

; Modal event loop. Out: A = result code.
ui_msg_loop:
.loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      z, .key
        cp      UI_EVENT_MOUSE
        jp      z, .mouse
        jr      .loop
.key:
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jr      z, .escape
        cp      UI_KEY_TAB
        jr      z, .next
        ld      a, (ui_event_scan)
        cp      UI_SCAN_RIGHT
        jr      z, .next
        cp      UI_SCAN_LEFT
        jr      z, .prev
        ld      a, (ui_event_key)
        call    ui_msg_try_key
        jr      nc, .done
        jr      .loop
.escape:
        ld      a, (ui_msg_esc_result)
        or      a
        jr      z, .loop                ; no escape action for this set
        ret
.next:
        call    ui_msg_focus_advance
        jr      .loop
.prev:
        call    ui_msg_focus_retreat
        jr      .loop
.mouse:
        call    ui_msg_try_mouse
        jr      nc, .done
        jp      .loop
.done:
        ret                             ; A = result

; Try to activate a button by key. Out: CF=0 and A=result if activated.
ui_msg_try_key:
        ld      (ui_msg_key_tmp), a
        ld      ix, ui_msg_window
        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
.bl:
        ld      a, (ui_msg_key_tmp)
        push    bc
        call    ui_button_accepts_key
        pop     bc
        jr      nc, .hit
        push    bc
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     bc
        djnz    .bl
        scf
        ret
.hit:
        call    ui_button_press_key_feedback
        ld      a, (iy + UI_BUTTON_COMMAND)
        or      a
        ret

; Try to activate a button by mouse click. Out: CF=0 and A=result if committed.
ui_msg_try_mouse:
        ld      ix, ui_msg_window
        ld      iy, ui_msg_buttons
        ld      a, (ui_msg_count)
        ld      b, a
.bl:
        push    bc
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_event_mouse_x)
        call    ui_button_hit_test
        pop     bc
        jr      nc, .hit
        push    bc
        ld      de, UI_BUTTON_SIZE
        add     iy, de
        pop     bc
        djnz    .bl
        scf
        ret
.hit:
        call    ui_button_press_mouse_feedback
        jr      c, .cancel
        ld      a, (iy + UI_BUTTON_COMMAND)
        or      a
        ret
.cancel:
        scf
        ret

; Move focus to the next / previous button (wraps), redrawing both.
ui_msg_focus_advance:
        ld      a, (ui_msg_count)
        cp      2
        ret     c
        ld      a, (ui_msg_focus)
        ld      c, a
        inc     a
        ld      b, a
        ld      a, (ui_msg_count)
        cp      b
        ld      a, b
        jr      nz, ui_msg_apply_focus
        xor     a
        jr      ui_msg_apply_focus
ui_msg_focus_retreat:
        ld      a, (ui_msg_count)
        cp      2
        ret     c
        ld      a, (ui_msg_focus)
        ld      c, a
        or      a
        jr      nz, .dec
        ld      a, (ui_msg_count)
.dec:
        dec     a
        ; fall through

; In: C = old focus index, A = new focus index
ui_msg_apply_focus:
        ld      (ui_msg_focus), a
        ld      a, c
        call    ui_msg_button_ptr
        res     6, (iy + UI_BUTTON_FLAGS)
        ld      ix, ui_msg_window
        call    ui_draw_button
        ld      a, (ui_msg_focus)
        call    ui_msg_button_ptr
        set     6, (iy + UI_BUTTON_FLAGS)
        ld      ix, ui_msg_window
        call    ui_draw_button
        ret

; In: A = index. Out: IY = &ui_msg_buttons[index].
ui_msg_button_ptr:
        ld      iy, ui_msg_buttons
        or      a
        ret     z
        ld      b, a
        ld      de, UI_BUTTON_SIZE
.l:
        add     iy, de
        djnz    .l
        ret

ui_msg_save_under:
        xor     a
        ld      (ui_msg_saved_under), a
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      ix, ui_msg_window
        call    ui_window_save_under
        ret     c
        ld      a, 1
        ld      (ui_msg_saved_under), a
        ENDIF
        ret

ui_msg_restore_under:
        IF UI_USE_DSS_WINDOW_BUFFER
        ld      a, (ui_msg_saved_under)
        or      a
        ret     z
        xor     a
        ld      (ui_msg_saved_under), a
        call    ui_window_restore_under
        ENDIF
        ret

; --- data --------------------------------------------------------------------

ui_msg_text:
        dw      0
ui_msg_title:
        dw      0
ui_msg_set:
        db      0
ui_msg_bg:
        db      0
ui_msg_bg_over:
        db      0
ui_msg_saved_win:
        db      0
ui_msg_saved_title:
        db      0
ui_msg_saved_btnsh:
        db      0
ui_msg_saved_under:
        db      0
ui_msg_result:
        db      0
ui_msg_count:
        db      0
ui_msg_esc_result:
        db      0
ui_msg_focus:
        db      0
ui_msg_nlines:
        db      0
ui_msg_maxlen:
        db      0
ui_msg_btn_w:
        db      0
ui_msg_btn_y:
        db      0
ui_msg_key_tmp:
        db      0
ui_msg_wrap_w:
        db      0
ui_msg_cursor:
        dw      0
ui_msg_line_start:
        dw      0
ui_msg_line_len:
        db      0
ui_msg_text_attr:
        db      0
ui_msg_text_row:
        db      0
ui_msg_text_col:
        db      0
ui_msg_draw_remain:
        db      0

ui_msg_window:
        db      0, 0, 0, 0              ; x, y, w, h
        dw      0                       ; title
        db      0                       ; frame

ui_msg_buttons:
        ds      3 * UI_BUTTON_SIZE, 0

; Button-set dispatch: dw entries, db count, db escape-result.
ui_msg_dispatch:
        dw      ui_msg_e_ok
        db      1, UI_MSG_RESULT_OK
        dw      ui_msg_e_okcancel
        db      2, UI_MSG_RESULT_CANCEL
        dw      ui_msg_e_yesno
        db      2, UI_MSG_RESULT_NO
        dw      ui_msg_e_yesnocancel
        db      3, UI_MSG_RESULT_CANCEL
        dw      ui_msg_e_abortretryignore
        db      3, 0

; Entries: dw label, db result, db hotkey (lowercase).
ui_msg_e_ok:
        dw      ui_msg_lbl_ok
        db      UI_MSG_RESULT_OK, "o"
ui_msg_e_okcancel:
        dw      ui_msg_lbl_ok
        db      UI_MSG_RESULT_OK, "o"
        dw      ui_msg_lbl_cancel
        db      UI_MSG_RESULT_CANCEL, "c"
ui_msg_e_yesno:
        dw      ui_msg_lbl_yes
        db      UI_MSG_RESULT_YES, "y"
        dw      ui_msg_lbl_no
        db      UI_MSG_RESULT_NO, "n"
ui_msg_e_yesnocancel:
        dw      ui_msg_lbl_yes
        db      UI_MSG_RESULT_YES, "y"
        dw      ui_msg_lbl_no
        db      UI_MSG_RESULT_NO, "n"
        dw      ui_msg_lbl_cancel
        db      UI_MSG_RESULT_CANCEL, "c"
ui_msg_e_abortretryignore:
        dw      ui_msg_lbl_abort
        db      UI_MSG_RESULT_ABORT, "a"
        dw      ui_msg_lbl_retry
        db      UI_MSG_RESULT_RETRY, "r"
        dw      ui_msg_lbl_ignore
        db      UI_MSG_RESULT_IGNORE, "i"

ui_msg_lbl_ok:
        db      " &OK ", 0
ui_msg_lbl_cancel:
        db      " &Cancel ", 0
ui_msg_lbl_yes:
        db      " &Yes ", 0
ui_msg_lbl_no:
        db      " &No ", 0
ui_msg_lbl_abort:
        db      " &Abort ", 0
ui_msg_lbl_retry:
        db      " &Retry ", 0
ui_msg_lbl_ignore:
        db      " &Ignore ", 0
