; ItemSelector drawing and state helpers.

; ui_draw_item_selector
; In:  IX=parent window descriptor, IY=item selector descriptor
; Out: none
; Clobbers: AF, BC, DE, HL
ui_draw_item_selector:
        call    ui_item_selector_clamp_selected
        call    ui_item_selector_attr
        ld      (ui_item_selector_attr_value), a
        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_ITEM_SELECTOR_X)
        ld      (ui_item_selector_base_x), a
        ld      e, a
        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_ITEM_SELECTOR_Y)
        ld      (ui_item_selector_base_y), a
        ld      d, a
        ld      a, (iy + UI_ITEM_SELECTOR_W)
        ld      (ui_item_selector_width), a
        or      a
        ret     z

        ld      h, 1
        ld      l, a
        ld      a, " "
        push    af
        ld      a, (ui_item_selector_attr_value)
        ld      b, a
        pop     af
        call    ui_fill_rect

        ld      a, (ui_item_selector_width)
        cp      3
        ret     c
        sub     2
        ld      (ui_item_selector_text_left), a
        ld      a, (ui_item_selector_base_y)
        ld      d, a
        ld      a, (ui_item_selector_base_x)
        ld      e, a
        ld      a, "<"
        call    ui_item_selector_put
        ld      a, (ui_item_selector_width)
        dec     a
        ld      (ui_item_selector_right_x), a
        ld      a, (iy + UI_ITEM_SELECTOR_COUNT)
        or      a
        jr      z, .skip_text
        call    ui_item_selector_selected_item
        ld      a, (ui_item_selector_base_x)
        inc     a
        ld      e, a
        ld      a, (ui_item_selector_base_y)
        ld      d, a
        call    ui_item_selector_print_selected
.skip_text:

        ld      a, (ui_item_selector_base_x)
        ld      b, a
        ld      a, (ui_item_selector_right_x)
        add     a, b
        ld      e, a
        ld      a, (ui_item_selector_base_y)
        ld      d, a
        ld      a, ">"
        jp      ui_item_selector_put

; ui_item_selector_next
; In:  IY=item selector descriptor
; Out: none
; Clobbers: AF, B
ui_item_selector_next:
        ld      a, (iy + UI_ITEM_SELECTOR_FLAGS)
        bit     7, a
        ret     nz
        ld      a, (iy + UI_ITEM_SELECTOR_COUNT)
        or      a
        ret     z
        ld      b, a
        ld      a, (iy + UI_ITEM_SELECTOR_SELECTED)
        inc     a
        cp      b
        jr      c, .store
        xor     a
.store:
        ld      (iy + UI_ITEM_SELECTOR_SELECTED), a
        ret

; ui_item_selector_prev
; In:  IY=item selector descriptor
; Out: none
; Clobbers: AF, B
ui_item_selector_prev:
        ld      a, (iy + UI_ITEM_SELECTOR_FLAGS)
        bit     7, a
        ret     nz
        ld      a, (iy + UI_ITEM_SELECTOR_COUNT)
        or      a
        ret     z
        ld      b, a
        ld      a, (iy + UI_ITEM_SELECTOR_SELECTED)
        or      a
        jr      nz, .dec
        ld      a, b
.dec:
        dec     a
        ld      (iy + UI_ITEM_SELECTOR_SELECTED), a
        ret

ui_item_selector_attr:
        ld      a, (iy + UI_ITEM_SELECTOR_FLAGS)
        bit     7, a
        jr      nz, .disabled
        bit     6, a
        jr      nz, .focused
        ld      a, (ui_theme_text_field)
        ret
.focused:
        ld      a, (ui_theme_text_field_focus)
        ret
.disabled:
        ld      a, (ui_theme_disabled)
        ret

ui_item_selector_put:
        push    af
        ld      a, (ui_item_selector_attr_value)
        ld      b, a
        pop     af
        call    ui_put_cell
        ret

ui_item_selector_clamp_selected:
        ld      a, (iy + UI_ITEM_SELECTOR_COUNT)
        or      a
        jr      z, .zero
        ld      b, a
        ld      a, (iy + UI_ITEM_SELECTOR_SELECTED)
        cp      b
        ret     c
.zero:
        xor     a
        ld      (iy + UI_ITEM_SELECTOR_SELECTED), a
        ret

ui_item_selector_selected_item:
        ld      l, (iy + UI_ITEM_SELECTOR_ITEMS)
        ld      h, (iy + UI_ITEM_SELECTOR_ITEMS + 1)
        ld      a, h
        or      l
        ret     z
        ld      a, (iy + UI_ITEM_SELECTOR_SELECTED)
        add     a, a
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     hl
        ret

ui_item_selector_print_selected:
        ld      a, (ui_item_selector_text_left)
        or      a
        ret     z
        ld      b, a
.loop:
        ld      a, (hl)
        or      a
        ret     z
        push    bc
        push    hl
        push    de
        call    ui_item_selector_put
        pop     de
        pop     hl
        pop     bc
        inc     hl
        inc     e
        djnz    .loop
        ret

ui_item_selector_attr_value:
        db      0
ui_item_selector_base_x:
        db      0
ui_item_selector_base_y:
        db      0
ui_item_selector_width:
        db      0
ui_item_selector_right_x:
        db      0
ui_item_selector_text_left:
        db      0
