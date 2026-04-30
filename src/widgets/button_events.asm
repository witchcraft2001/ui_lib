; Button event helpers.

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

; ui_button_hit_test
; In:  IX=parent window, IY=button, A=mouse x, B=mouse y
; Out: CF=0 if hit, CF=1 if not hit
; Clobbers: AF, BC, DE, HL
ui_button_hit_test:
        ld      c, a              ; C=mouse x

        ld      a, (ix + UI_WINDOW_Y)
        add     a, (iy + UI_BUTTON_Y)
        cp      b
        jr      nz, .miss

        ld      a, (ix + UI_WINDOW_X)
        add     a, (iy + UI_BUTTON_X)
        ld      d, a              ; D=left x
        ld      a, c
        cp      d
        jr      c, .miss

        ld      l, (iy + UI_BUTTON_LABEL)
        ld      h, (iy + UI_BUTTON_LABEL + 1)
        call    ui_button_visible_width
        ld      a, d
        add     a, b
        ld      e, a              ; E=right exclusive
        ld      a, c
        cp      e
        jr      nc, .miss
        or      a
        ret
.miss:
        scf
        ret

; ui_button_accepts_key
; In:  IY=button, A=key
; Out: CF=0 if key activates button, CF=1 otherwise
; Clobbers: AF
ui_button_accepts_key:
        cp      UI_KEY_ENTER
        jr      z, .enter
        cp      (iy + UI_BUTTON_HOTKEY)
        jr      z, .hit
        or      20h
        cp      (iy + UI_BUTTON_HOTKEY)
        jr      z, .hit
        and     0DFh
        cp      (iy + UI_BUTTON_HOTKEY)
        jr      z, .hit
        scf
        ret
.enter:
        ld      a, (iy + UI_BUTTON_FLAGS)
        bit     6, a
        jr      z, .miss
.hit:
        ld      a, (iy + UI_BUTTON_FLAGS)
        bit     7, a
        jr      nz, .miss
        or      a
        ret
.miss:
        scf
        ret
