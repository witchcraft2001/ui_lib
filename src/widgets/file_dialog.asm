;======================================================================
; file_dialog.asm - modal file open / save dialog.
;
; Built from ui_lib widgets (window, text field, combo box, button) plus a
; custom two-column file list. The directory entries are kept in a DSS page
; (allocated at first use), so the bulk buffer does not occupy contiguous WIN1
; memory; only a small per-entry index lives in WIN1.
;
; Navigation is done by ChDir + re-reading the canonical cwd (drive + CurDir),
; so the displayed path is always real and a failed cd self-corrects.
;
; ui_file_dialog:
;   In:  A  = mode (0 = open, 1 = save)
;        HL = initial name suggestion (ASCIIZ; copied into the Name field)
;        DE = title ASCIIZ
;   Out: CF=0 accepted, ui_fd_result = full path (ASCIIZ).  CF=1 cancelled.
;
; Requires window.asm, text_field.asm, combo_box.asm, button.asm,
; button_events.asm and draw/text.asm. The directory page uses GetMem/SetWin3,
; independent of UI_USE_DSS_WINDOW_BUFFER.
;======================================================================

UI_FD_MAX        equ    900             ; max directory entries (page capacity)
UI_FD_RECLEN     equ    16              ; bytes per entry record in the page
UI_FD_NAMELEN    equ    15              ; ASCIIZ name room inside a record
UI_FD_DRIVES     equ    6               ; A: .. F:

UI_FD_FOC_NAME   equ    0
UI_FD_FOC_LIST   equ    1
UI_FD_FOC_OK     equ    2
UI_FD_FOC_CANCEL equ    3
UI_FD_FOC_DRIVE  equ    4
UI_FD_FOC_COUNT  equ    5

; Window layout (centred 48x23). The Path line sits one blank row below the list.
UI_FD_WX         equ    16
UI_FD_WY         equ    5
UI_FD_WW         equ    48
UI_FD_WH         equ    23
UI_FD_PATHROW    equ    UI_FD_WY + UI_FD_WH - 2

; List geometry, relative to the window. Two columns of UI_FD_LROWS rows.
UI_FD_LX         equ    2
UI_FD_LY         equ    6
UI_FD_LW         equ    30              ; frame (2) + 2 columns
UI_FD_LROWS      equ    12              ; visible rows per column
UI_FD_COLW       equ    14              ; text width of one column
UI_FD_BTNX       equ    34              ; buttons sit just right of the list

; Record layout inside the page (mapped to WIN3 at 0C000h).
UI_FD_PAGE_BASE  equ    0C000h
UI_FD_R_ISDIR    equ    0               ; +0 directory flag (0x10 = dir)
UI_FD_R_NAME     equ    1               ; +1 ASCIIZ display name

;----------------------------------------------------------------------
; Page allocation / mapping. The page id is cached; the page is mapped into
; WIN3 around enumeration and rendering, restoring P3 afterwards.
;----------------------------------------------------------------------

; Allocate the directory page if not already held, and learn its physical page
; number (so we can map it into WIN3 with a raw port write, never holding a DSS
; mapping across CPU access). Out: CF=1 on failure.
ui_fd_alloc_page:
        ld      a, (ui_fd_block_id)
        or      a
        jr      nz, .ok
        ld      b, 1                    ; one 16K page (count in B)
        ld      c, Dss.GetMem
        call    ui_call_dss
        ret     c
        ld      (ui_fd_block_id), a     ; A = block id; resolve its physical page
        ld      b, 0                    ; logical page index 0 (first page)
        ld      c, Bios.Emm_Fn4         ; A = block id -> A = physical page number
        call    ui_call_bios
        ret     c
        ld      (ui_fd_page_num), a
.ok:
        or      a
        ret

ui_fd_free_page:
        ld      a, (ui_fd_block_id)
        or      a
        ret     z
        ld      c, Dss.FreeMem
        call    ui_call_dss
        xor     a
        ld      (ui_fd_block_id), a
        ret

; Map the page into WIN3 with a raw port write, interrupts off (no DSS/BIOS call
; runs while the page is mapped, so nothing else can touch WIN3). Out: CF=1 if no
; page. The caller must pair every successful map with ui_fd_unmap_page.
ui_fd_map_page:
        ld      a, (ui_fd_block_id)
        or      a
        scf
        ret     z
        di
        in      a, (EmmWin.P3)
        ld      (ui_fd_saved_p3), a
        ld      a, (ui_fd_page_num)
        out     (EmmWin.P3), a
        or      a
        ret

ui_fd_unmap_page:
        ld      a, (ui_fd_saved_p3)
        out     (EmmWin.P3), a
        ei
        ret

; HL = record address in WIN3 for entry index HL. Preserves DE (callers stage
; into a DE-held destination across this call).
ui_fd_record_addr:
        add     hl, hl                  ; *16
        add     hl, hl
        add     hl, hl
        add     hl, hl
        push    de
        ld      de, UI_FD_PAGE_BASE
        add     hl, de
        pop     de
        ret

; CF=1 (carry set) when ui_fd_count has reached UI_FD_MAX.
ui_fd_full:
        push    hl
        push    de
        ld      hl, (ui_fd_count)
        ld      de, UI_FD_MAX
        or      a
        sbc     hl, de                  ; CF=1 if count < MAX
        pop     de
        pop     hl
        ccf                             ; CF=1 if count >= MAX
        ret

;----------------------------------------------------------------------
; Directory scan: fill the page from the current directory. "[..]" first, then
; directories (pass 1), then files (pass 2). The page must be mapped by the
; caller (ui_fd_map_page).
;----------------------------------------------------------------------
; Z set when ui_fd_path is a drive root ("X:" or "X:\").
ui_fd_is_root:
        ld      a, (ui_fd_path + 2)
        or      a
        ret     z
        cp      5Ch
        ret     nz
        ld      a, (ui_fd_path + 3)
        or      a
        ret

ui_fd_scan_entries:
        ld      hl, 0
        ld      (ui_fd_count), hl
        call    ui_fd_is_root                   ; the root has no parent: no "[..]"
        jr      z, .nodotdot
        call    ui_fd_add_updir
.nodotdot:
        ld      a, 1
        ld      (ui_fd_pass), a
        call    ui_fd_scan_pass
        xor     a
        ld      (ui_fd_pass), a
        call    ui_fd_scan_pass
        ret

ui_fd_scan_pass:
        ld      hl, ui_fd_mask          ; pass 1 (dirs): list all directories
        ld      a, (ui_fd_pass)
        or      a
        jr      nz, .havemask
        ld      hl, ui_fd_scan_mask     ; pass 2 (files): honour the Name filter
.havemask:
        ld      de, ui_fd_findbuf
        ld      a, 037h                 ; match files + dirs
        ld      c, Dss.F_First
        call    ui_call_dss
        ret     c
.loop:
        call    ui_fd_full
        ret     c
        ld      a, (ui_fd_findbuf + 33)  ; skip "." and ".." (DSS lists them)
        cp      "."
        jr      z, .next
        ld      a, (ui_fd_findbuf + 32)  ; matched attribute
        and     10h                     ; directory bit
        ld      b, a
        ld      a, (ui_fd_pass)
        or      a
        jr      z, .wantfile
        ld      a, b                    ; pass 1: directories only
        or      a
        jr      z, .next
        jr      .add
.wantfile:
        ld      a, b                    ; pass 2: files only
        or      a
        jr      nz, .next
.add:
        call    ui_fd_add_entry
.next:
        ld      de, ui_fd_findbuf
        ld      c, Dss.F_Next
        call    ui_call_dss
        jr      nc, .loop
        ret

ui_fd_add_updir:
        ld      hl, ui_fd_dotdot
        ld      b, 10h
        jp      ui_fd_store_entry

; Format the current find result into a record. Files keep the name; dirs
; become "[NAME]". In: B = directory flag (0 / 0x10).
ui_fd_add_entry:
        ld      a, b
        or      a
        jr      nz, .dir
        ld      hl, ui_fd_findbuf + 33   ; file: align to 8.3 columns
        call    ui_fd_fmt_83
        ld      hl, ui_fd_tmpname
        ld      b, 0
        jp      ui_fd_store_entry
.dir:
        ld      hl, ui_fd_tmpname        ; dir: "[" + name + "]"
        ld      (hl), "["
        inc     hl
        ld      de, ui_fd_findbuf + 33
        ld      b, 8                     ; 8.3 name: at most 8 chars, no spaces
.dcopy:
        ld      a, (de)
        or      a
        jr      z, .dclose
        cp      " "
        jr      z, .dclose               ; stop at padding (trims DSS junk)
        ld      (hl), a
        inc     hl
        inc     de
        djnz    .dcopy
.dclose:
        ld      (hl), "]"
        inc     hl
        ld      (hl), 0
        ld      hl, ui_fd_tmpname
        ld      b, 10h
        jp      ui_fd_store_entry

; Format ASCIIZ "NAME.EXT" (HL) into ui_fd_tmpname as "NNNNNNNN EEE": name in a
; fixed 8-cell field, one separator space, then the extension. The extension
; column always lines up; an 8-char name still gets its separator space.
ui_fd_fmt_83:
        push    hl
        ld      hl, ui_fd_tmpname        ; 12 spaces + null
        ld      b, 12
.fill:
        ld      (hl), " "
        inc     hl
        djnz    .fill
        ld      (hl), 0
        pop     hl
        ld      de, ui_fd_tmpname        ; name -> [0..7]
        ld      b, 8
.name:
        ld      a, (hl)
        or      a
        ret     z
        cp      "."
        jr      z, .dot
        ld      (de), a
        inc     hl
        inc     de
        djnz    .name
.skip:
        ld      a, (hl)                  ; name >= 8: skip to '.'
        or      a
        ret     z
        inc     hl
        cp      "."
        jr      z, .ext
        jr      .skip
.dot:
        inc     hl                       ; skip '.'
.ext:
        ld      de, ui_fd_tmpname + 9    ; ext -> [9..11] ([8] stays the separator)
        ld      b, 3
.extl:
        ld      a, (hl)
        or      a
        ret     z
        ld      (de), a
        inc     hl
        inc     de
        djnz    .extl
        ret

; Append a record: write the directory flag + ASCIIZ name (HL) to the page at
; index ui_fd_count, then bump the count. In: HL = name, B = dir flag.
ui_fd_store_entry:
        call    ui_fd_full
        ret     c
        ld      (ui_fd_se_src), hl
        ld      a, b
        ld      (ui_fd_se_isdir), a
        call    ui_fd_map_page
        ret     c
        ld      hl, (ui_fd_count)
        call    ui_fd_record_addr        ; HL = record in WIN3
        ld      a, (ui_fd_se_isdir)
        ld      (hl), a                  ; +0 dir flag
        inc     hl
        ex      de, hl                   ; DE = name dest (+1)
        ld      hl, (ui_fd_se_src)
        ld      b, UI_FD_NAMELEN - 1
.copy:
        ld      a, (hl)
        ld      (de), a
        or      a
        jr      z, .done
        inc     hl
        inc     de
        djnz    .copy
        xor     a
        ld      (de), a
.done:
        call    ui_fd_unmap_page
        ld      hl, (ui_fd_count)
        inc     hl
        ld      (ui_fd_count), hl
        ret

;----------------------------------------------------------------------
; ui_file_dialog: entry point.
;----------------------------------------------------------------------
ui_file_dialog:
        ld      (ui_fd_mode), a
        ld      (ui_fd_title), de
        ld      de, ui_fd_input                 ; copy the input path
        call    ui_fd_strcpy
        ld      hl, (ui_fd_title)
        ld      (ui_fd_window + UI_WINDOW_TITLE), hl
        ; OK button label = Open / Save per mode
        ld      hl, ui_fd_lbl_open
        ld      a, (ui_fd_mode)
        or      a
        jr      z, .lbl
        ld      hl, ui_fd_lbl_save
.lbl:
        ld      (ui_fd_btn_ok + UI_BUTTON_LABEL), hl

        call    ui_fd_alloc_page
        jp      c, ui_fd_fail

        call    ui_fd_save_cwd
        call    ui_fd_split_input               ; ChDir to input dir, fill name
        call    ui_fd_combo_sync
        call    ui_fd_rescan

        ld      hl, 0
        ld      (ui_fd_selected), hl
        ld      (ui_fd_top), hl
        ld      a, UI_FD_FOC_NAME
        ld      (ui_fd_focus), a

        ld      ix, ui_fd_window
        call    ui_window_save_under
        call    ui_fd_draw_all
.loop:
        call    ui_poll_event
        ld      a, (ui_event_type)
        cp      UI_EVENT_KEY
        jr      z, .key
        cp      UI_EVENT_MOUSE
        jp      z, ui_fd_mouse
        jr      .loop
.key:
        ld      a, (ui_event_key)
        cp      UI_KEY_ESCAPE
        jp      z, .cancel
        cp      UI_KEY_TAB
        jp      z, .tab
        ld      a, (ui_fd_focus)
        cp      UI_FD_FOC_NAME
        jp      z, ui_fd_key_name
        cp      UI_FD_FOC_LIST
        jp      z, ui_fd_key_list
        cp      UI_FD_FOC_DRIVE
        jp      z, ui_fd_key_drive
        ld      a, (ui_event_key)               ; OK / Cancel focus
        cp      UI_KEY_ENTER
        jr      z, .btn
        cp      UI_KEY_SPACE
        jr      z, .btn
        jp      .loop
.btn:
        ld      a, (ui_fd_focus)
        cp      UI_FD_FOC_CANCEL
        jr      z, .act_cancel
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        call    ui_button_press_key_feedback
        jp      ui_fd_accept_name
.act_cancel:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_cancel
        call    ui_button_press_key_feedback
        jp      .cancel
.tab:
        ld      a, (ui_event_mods)
        and     0D0h
        jr      nz, .tabprev
        ld      a, (ui_fd_focus)
        inc     a
        cp      UI_FD_FOC_COUNT
        jr      c, .tabset
        xor     a
        jr      .tabset
.tabprev:
        ld      a, (ui_fd_focus)
        or      a
        jr      nz, .tabdec
        ld      a, UI_FD_FOC_COUNT
.tabdec:
        dec     a
.tabset:
        ld      (ui_fd_focus), a
        call    ui_fd_move_focus
        jp      .loop
.cancel:
        call    ui_fd_close
        scf
        ret

ui_fd_done_ok:
        call    ui_fd_close
        or      a
        ret

ui_fd_fail:
        scf
        ret

ui_fd_close:
        ld      hl, ui_fd_savedcwd
        ld      c, Dss.ChDir
        call    ui_call_dss
        ld      ix, ui_fd_window
        call    ui_window_restore_under
        ret

;----------------------------------------------------------------------
; Path / cwd helpers.
;----------------------------------------------------------------------
ui_fd_save_cwd:
        ld      c, Dss.CurDisk
        call    ui_call_dss
        add     a, "A"
        ld      (ui_fd_savedcwd), a
        ld      a, ":"
        ld      (ui_fd_savedcwd + 1), a
        ld      hl, ui_fd_savedcwd + 2
        ld      c, Dss.CurDir
        call    ui_call_dss
        ret

; ChDir(HL), then ui_fd_path = "<drive>:" + CurDir.
ui_fd_set_cwd:
        ld      c, Dss.ChDir
        call    ui_call_dss
        ld      c, Dss.CurDisk
        call    ui_call_dss
        add     a, "A"
        ld      (ui_fd_path), a
        ld      a, ":"
        ld      (ui_fd_path + 1), a
        ld      hl, ui_fd_path + 2
        ld      c, Dss.CurDir
        call    ui_call_dss
        ret

ui_fd_combo_sync:
        ld      c, Dss.CurDisk
        call    ui_call_dss
        cp      UI_FD_DRIVES
        jr      c, .ok
        ld      a, UI_FD_DRIVES - 1
.ok:
        ld      (ui_fd_drive_combo + UI_COMBO_SELECTED), a
        ret

; Split ui_fd_input into a directory (ChDir) and a filename (Name field).
; ui_fd_dirtmp = copy of the input; ui_fd_lastsep points to the first char after
; the last '\' or ':' (= the filename). The directory is everything before it.
ui_fd_split_input:
        ld      hl, ui_fd_input
        ld      de, ui_fd_dirtmp
        call    ui_fd_strcpy
        ld      hl, ui_fd_dirtmp
        ld      (ui_fd_lastsep), hl
.scan:
        ld      a, (hl)
        or      a
        jr      z, .scandone
        cp      5Ch
        jr      z, .sep
        cp      ":"
        jr      z, .sep
        jr      .next
.sep:
        inc     hl
        ld      (ui_fd_lastsep), hl
        dec     hl
.next:
        inc     hl
        jr      .scan
.scandone:
        ld      hl, (ui_fd_lastsep)             ; filename -> Name field
        ld      de, ui_fd_name_buf
        call    ui_fd_strcpy
        ld      hl, (ui_fd_lastsep)             ; separator present?
        ld      de, ui_fd_dirtmp
        or      a
        sbc     hl, de
        jr      z, .nodir
        ld      hl, (ui_fd_lastsep)             ; terminate dir part, ChDir to it
        ld      (hl), 0
        ld      hl, ui_fd_dirtmp
        call    ui_fd_set_cwd
        jr      .field
.nodir:
        ld      hl, ui_fd_dot                   ; no directory: current dir
        call    ui_fd_set_cwd
.field:
        ld      hl, ui_fd_mask                  ; default filter "*.*", or the
        ld      de, ui_fd_scan_mask             ; initial name if it is a mask
        call    ui_fd_strcpy
        ld      hl, ui_fd_name_buf
        call    ui_fd_has_wildcard
        jr      nc, .nofilter
        ld      hl, ui_fd_name_buf
        ld      de, ui_fd_scan_mask
        call    ui_fd_strcpy
.nofilter:
        ld      hl, ui_fd_name_buf
        call    ui_fd_strlen
        ld      (ui_fd_namefield + UI_TEXT_CURSOR), a
        xor     a
        ld      (ui_fd_namefield + UI_TEXT_SCROLL), a
        ret

; Re-scan the current directory into the page and reset the list state. Each
; record is written with the page mapped only across the store (no DSS call in
; between), so directory I/O can never disturb the mapping.
ui_fd_rescan:
        call    ui_fd_scan_entries
        ld      hl, 0
        ld      (ui_fd_selected), hl
        ld      (ui_fd_top), hl
        ret

;----------------------------------------------------------------------
; Drawing.
;----------------------------------------------------------------------
ui_fd_draw_all:
        ld      ix, ui_fd_window
        call    ui_draw_window
        ; fall through: repaint all widgets over the fresh window body

; Repaint every widget without clearing the window body (no flash). Also repairs
; any damage left by a transient popup (e.g. the drive dropdown).
ui_fd_redraw_contents:
        ld      hl, ui_fd_lbl_drive
        ld      a, (ui_theme_window)
        ld      d, UI_FD_WY + 2
        ld      e, UI_FD_WX + 2
        call    ui_print_z
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        call    ui_draw_combo_box
        ld      hl, ui_fd_lbl_name
        ld      a, (ui_theme_window)
        ld      d, UI_FD_WY + 4
        ld      e, UI_FD_WX + 2
        call    ui_print_z
        ld      ix, ui_fd_window
        ld      iy, ui_fd_namefield
        call    ui_draw_text_field
        call    ui_fd_draw_list_frame
        call    ui_fd_draw_list
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        call    ui_draw_button
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_cancel
        call    ui_draw_button
        call    ui_fd_draw_path
        call    ui_fd_apply_focus
        ret

ui_fd_draw_list_frame:
        ld      a, UI_FD_WY
        add     a, UI_FD_LY
        ld      d, a
        ld      a, UI_FD_WX
        add     a, UI_FD_LX
        ld      e, a
        ld      h, UI_FD_LROWS + 2
        ld      l, UI_FD_LW
        ld      a, (ui_theme_window)
        ld      b, a
        call    ui_draw_box_single
        ld      hl, ui_fd_lbl_files     ; "Files" group label on the top frame
        ld      a, (ui_theme_window)
        ld      d, UI_FD_WY + UI_FD_LY
        ld      e, UI_FD_WX + UI_FD_LX + 2
        jp      ui_print_z

; Repaint only the path line and the list (navigation, no frame).
ui_fd_redraw_listpath:
        call    ui_fd_draw_path
        jp      ui_fd_draw_list

;----------------------------------------------------------------------
; Two-column list rendering. The page is mapped only to stage the visible
; records into a small WIN1 buffer (pure LDIR); drawing then runs with no page
; mapped, so BIOS video access can never disturb the mapping.
;----------------------------------------------------------------------
ui_fd_draw_list:
        call    ui_fd_map_page
        ret     c
        ld      hl, (ui_fd_top)
        ld      (ui_fd_visidx), hl
        xor     a
        ld      (ui_fd_visp), a
.read:
        ld      a, (ui_fd_visp)                 ; dest slot = ui_fd_vis + p*16
        ld      l, a
        ld      h, 0
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      de, ui_fd_vis
        add     hl, de
        ex      de, hl                          ; DE = dest slot
        ld      hl, (ui_fd_visidx)              ; entry < count?
        ld      bc, (ui_fd_count)
        or      a
        sbc     hl, bc
        jr      nc, .blank
        ld      hl, (ui_fd_visidx)
        call    ui_fd_record_addr               ; HL = WIN3 record (16 bytes)
        ld      bc, 16
        ldir
        jr      .readnext
.blank:
        ld      a, 0FFh                         ; blank marker
        ld      (de), a
.readnext:
        ld      hl, (ui_fd_visidx)
        inc     hl
        ld      (ui_fd_visidx), hl
        ld      a, (ui_fd_visp)
        inc     a
        ld      (ui_fd_visp), a
        cp      2 * UI_FD_LROWS
        jr      c, .read
        call    ui_fd_unmap_page

        xor     a                               ; draw cells from the staged copy
        ld      (ui_fd_dcol), a
.dcol:
        xor     a
        ld      (ui_fd_drow), a
.drow:
        call    ui_fd_draw_slot
        ld      a, (ui_fd_drow)
        inc     a
        ld      (ui_fd_drow), a
        cp      UI_FD_LROWS
        jr      c, .drow
        ld      a, (ui_fd_dcol)
        inc     a
        ld      (ui_fd_dcol), a
        cp      2
        jr      c, .dcol
        jp      ui_fd_draw_hscroll

; Horizontal scroll bar on the list's bottom frame row: left/right arrows, a
; patterned track, and a thumb whose position reflects the current column-page
; (top / LROWS) within the total column count.
UI_FD_HS_THUMBW  equ    3
UI_FD_HS_ROW     equ    UI_FD_WY + UI_FD_LY + UI_FD_LROWS + 1
UI_FD_HS_X0      equ    UI_FD_WX + UI_FD_LX + 1   ; left arrow cell
UI_FD_HS_TRACKW  equ    UI_FD_LW - 4              ; cells between the two arrows
ui_fd_draw_hscroll:
        ld      d, UI_FD_HS_ROW                 ; left arrow
        ld      e, UI_FD_HS_X0
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 011h
        call    ui_put_cell
        ld      d, UI_FD_HS_ROW                 ; right arrow
        ld      e, UI_FD_HS_X0 + UI_FD_HS_TRACKW + 1
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 010h
        call    ui_put_cell
        ld      d, UI_FD_HS_ROW                 ; patterned track
        ld      e, UI_FD_HS_X0 + 1
        ld      h, 1
        ld      l, UI_FD_HS_TRACKW
        ld      a, (ui_theme_text_field)
        ld      b, a
        ld      a, 0B1h
        call    ui_fill_rect
        ld      hl, (ui_fd_count)               ; ncols = ceil(count / LROWS) -> C
        ld      c, 0
.nc:
        ld      a, h
        or      l
        jr      z, .ncd
        inc     c
        ld      de, UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      c, .ncd
        jr      .nc
.ncd:
        ld      a, c                            ; denom = ncols - 2
        sub     2
        ret     c                               ; <=2 columns: everything fits
        ret     z
        ld      c, a                            ; C = denom
        ld      hl, (ui_fd_top)                 ; curcol = top / LROWS -> B
        ld      b, 0
.cc:
        ld      a, h
        or      l
        jr      z, .ccd
        inc     b
        ld      de, UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      c, .ccd
        jr      .cc
.ccd:
        ld      a, UI_FD_HS_TRACKW - UI_FD_HS_THUMBW ; span = trackw - thumbw
        ld      e, a                            ; thumb_x = curcol*span/denom
        ld      a, b
        call    ui_fd_muldiv                    ; A = A*E/C
        add     a, UI_FD_HS_X0 + 1
        ld      e, a
        ld      d, UI_FD_HS_ROW
        ld      h, 1
        ld      l, UI_FD_HS_THUMBW
        ld      a, (ui_theme_text_field_focus)
        ld      b, a
        ld      a, 0DBh
        jp      ui_fill_rect

; A = (A * E) / C, all unsigned, intermediate product fits 16 bits.
ui_fd_muldiv:
        ld      hl, 0
        or      a
        jr      z, .div
        ld      b, a
        ld      d, 0
.mul:
        add     hl, de
        djnz    .mul
.div:
        ld      d, 0
        ld      e, c
        ld      a, -1
.dl:
        inc     a
        or      a
        sbc     hl, de
        jr      nc, .dl
        ret

; Cell screen origin for (ui_fd_dcol, ui_fd_drow) -> D=row, E=col.
ui_fd_cell_origin:
        ld      a, UI_FD_WY
        add     a, UI_FD_LY
        inc     a
        ld      b, a
        ld      a, (ui_fd_drow)
        add     a, b
        ld      d, a
        ld      a, UI_FD_WX
        add     a, UI_FD_LX
        inc     a
        ld      b, a
        ld      a, (ui_fd_dcol)
        or      a
        ld      c, 0
        jr      z, .c0
        ld      c, UI_FD_COLW
.c0:
        ld      a, b
        add     a, c
        ld      e, a
        ret

ui_fd_blank_cell:
        call    ui_fd_cell_origin
        ld      h, 1
        ld      l, UI_FD_COLW
        ld      a, (ui_theme_text_field)
        ld      b, a
        ld      a, " "
        jp      ui_fill_rect

; Draw the cell at (dcol,drow) from the staged slot p = dcol*LROWS + drow.
ui_fd_draw_slot:
        ld      a, (ui_fd_dcol)
        or      a
        ld      e, 0
        jr      z, .p0
        ld      e, UI_FD_LROWS
.p0:
        ld      a, (ui_fd_drow)
        add     a, e
        ld      (ui_fd_visp), a                 ; p
        ld      l, a                            ; slot = ui_fd_vis + p*16
        ld      h, 0
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      de, ui_fd_vis
        add     hl, de
        ld      (ui_fd_slotptr), hl
        ld      a, (hl)
        cp      0FFh
        jp      z, ui_fd_blank_cell
        ld      a, (ui_fd_visp)                 ; the selected entry is always
        ld      e, a                            ; highlighted, so it stays clear
        ld      d, 0                            ; which file Open will return even
        ld      hl, (ui_fd_top)                 ; when focus is on another widget
        add     hl, de                          ; entry = top + p
        ld      de, (ui_fd_selected)
        or      a
        sbc     hl, de
        jr      nz, .normal
        ld      a, (ui_theme_menu_popup_focus)
        jr      .attr
.normal:
        ld      a, (ui_theme_text_field)
.attr:
        ld      (ui_fd_cellattr), a
        call    ui_fd_cell_origin
        ld      hl, (ui_fd_slotptr)
        inc     hl                              ; name = slot + 1
        ld      a, (ui_fd_cellattr)
        ld      b, UI_FD_COLW
        jp      ui_fd_print_field

; Read entry HL from the page into ui_fd_drawname / ui_fd_drawisdir (page mapped).
ui_fd_read_name:
        call    ui_fd_record_addr
        ld      a, (hl)
        ld      (ui_fd_drawisdir), a
        inc     hl
        ld      de, ui_fd_drawname
        ld      b, UI_FD_NAMELEN
.c:
        ld      a, (hl)
        ld      (de), a
        or      a
        jr      z, .d
        inc     hl
        inc     de
        djnz    .c
        xor     a
        ld      (de), a
.d:
        ret

; Print HL padded/truncated to width B at D=row, E=col, attribute A. Cursor set
; once with BIOS auto-advance.
ui_fd_print_field:
        ld      (.attr), a
        ld      a, b
        ld      (.w), a
        or      a
        ret     z
        push    ix
        push    iy
        ld      c, Bios.Lp_Set_Place
        call    ui_call_bios
.loop:
        ld      a, (.w)
        or      a
        jr      z, .done
        dec     a
        ld      (.w), a
        ld      a, (hl)
        or      a
        jr      nz, .ch
        ld      a, " "
        jr      .emit
.ch:
        inc     hl
.emit:
        push    hl
        ld      c, a
        ld      a, (.attr)
        ld      e, a
        ld      a, c
        ld      b, 1
        ld      c, Bios.Lp_Print_All
        call    ui_call_bios
        pop     hl
        jr      .loop
.done:
        pop     iy
        pop     ix
        ret
.attr:
        db      0
.w:
        db      0

;----------------------------------------------------------------------
; List navigation (two-column, column-major).
;----------------------------------------------------------------------
ui_fd_list_make_visible:
        ; while selected < top: top -= LROWS
.up:
        ld      hl, (ui_fd_selected)
        ld      de, (ui_fd_top)
        or      a
        sbc     hl, de
        jr      nc, .down                       ; selected >= top
        ld      hl, (ui_fd_top)
        ld      de, UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      c, .zero_top
        ld      (ui_fd_top), hl
        jr      .up
.zero_top:
        ld      hl, 0
        ld      (ui_fd_top), hl
.down:
        ; while selected >= top + 2*LROWS: top += LROWS
        ld      hl, (ui_fd_top)
        ld      de, 2 * UI_FD_LROWS
        add     hl, de
        ex      de, hl                          ; DE = top + 2*LROWS
        ld      hl, (ui_fd_selected)
        or      a
        sbc     hl, de
        ret     c                               ; selected < top+2R -> visible
        ld      hl, (ui_fd_top)
        ld      de, UI_FD_LROWS
        add     hl, de
        ld      (ui_fd_top), hl
        jr      .down

; Clamp selected into [0, count-1].
ui_fd_list_clamp:
        ld      hl, (ui_fd_count)
        ld      a, h
        or      l
        jr      nz, .nz
        ld      hl, 0                            ; empty
        ld      (ui_fd_selected), hl
        ret
.nz:
        dec     hl                               ; HL = count-1
        ld      de, (ui_fd_selected)
        ex      de, hl                           ; HL=selected, DE=count-1
        or      a
        sbc     hl, de
        ret     c                                ; selected < count-1
        ret     z
        ld      hl, (ui_fd_count)                ; selected > count-1 -> clamp
        dec     hl
        ld      (ui_fd_selected), hl
        ret

;----------------------------------------------------------------------
; Focus + path line.
;----------------------------------------------------------------------
ui_fd_apply_focus:
        ld      hl, ui_fd_namefield + UI_TEXT_FLAGS
        res     6, (hl)
        ld      hl, ui_fd_drive_combo + UI_COMBO_FLAGS
        res     6, (hl)
        ld      hl, ui_fd_btn_ok + UI_BUTTON_FLAGS
        res     6, (hl)
        ld      hl, ui_fd_btn_cancel + UI_BUTTON_FLAGS
        res     6, (hl)
        ld      a, (ui_fd_focus)
        cp      UI_FD_FOC_NAME
        jr      z, .name
        cp      UI_FD_FOC_DRIVE
        jr      z, .drive
        cp      UI_FD_FOC_OK
        jr      z, .ok
        cp      UI_FD_FOC_CANCEL
        jr      z, .cancel
        jr      .redraw
.name:
        ld      hl, ui_fd_namefield + UI_TEXT_FLAGS
        set     6, (hl)
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        jr      .redraw
.drive:
        ld      hl, ui_fd_drive_combo + UI_COMBO_FLAGS
        set     6, (hl)
        jr      .redraw
.ok:
        ld      hl, ui_fd_btn_ok + UI_BUTTON_FLAGS
        set     6, (hl)
        jr      .redraw
.cancel:
        ld      hl, ui_fd_btn_cancel + UI_BUTTON_FLAGS
        set     6, (hl)
.redraw:
        ld      a, (ui_fd_focus)
        ld      (ui_fd_drawn_focus), a
        ld      ix, ui_fd_window
        ld      iy, ui_fd_namefield
        call    ui_draw_text_field
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        call    ui_draw_combo_box
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        call    ui_draw_button
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_cancel
        call    ui_draw_button
        jp      ui_fd_draw_list

; Move focus to ui_fd_focus, repainting only the widget that lost focus and the
; one that gained it (the others are untouched -> no flicker).
ui_fd_move_focus:
        ld      a, (ui_fd_drawn_focus)
        cp      UI_FD_FOC_COUNT
        jr      nc, .new                        ; no valid previous widget
        ld      b, a
        ld      a, (ui_fd_focus)
        cp      b
        jr      z, .new                         ; focus unchanged
        ld      a, b
        or      a                               ; CF=0 -> unfocused
        call    ui_fd_redraw_widget
.new:
        ld      a, (ui_fd_focus)
        scf                                     ; CF=1 -> focused
        call    ui_fd_redraw_widget
        ld      a, (ui_fd_focus)
        ld      (ui_fd_drawn_focus), a
        ret

; Repaint widget A (a UI_FD_FOC_* id); CF=1 focused, CF=0 unfocused.
ui_fd_redraw_widget:
        ld      b, 0
        jr      nc, .haveb
        ld      b, 1
.haveb:
        cp      UI_FD_FOC_NAME
        jr      z, .name
        cp      UI_FD_FOC_DRIVE
        jr      z, .drive
        cp      UI_FD_FOC_OK
        jr      z, .ok
        cp      UI_FD_FOC_CANCEL
        jr      z, .cancel
        jp      ui_fd_draw_list                 ; LIST: selection shows on its own
.name:
        ld      hl, ui_fd_namefield + UI_TEXT_FLAGS
        call    ui_fd_apply_bit
        ld      a, b
        or      a
        jr      z, .name_draw
        ld      a, 1
        ld      (ui_text_cursor_visible), a
.name_draw:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_namefield
        jp      ui_draw_text_field
.drive:
        ld      hl, ui_fd_drive_combo + UI_COMBO_FLAGS
        call    ui_fd_apply_bit
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        jp      ui_draw_combo_box
.ok:
        ld      hl, ui_fd_btn_ok + UI_BUTTON_FLAGS
        call    ui_fd_apply_bit
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        jp      ui_draw_button
.cancel:
        ld      hl, ui_fd_btn_cancel + UI_BUTTON_FLAGS
        call    ui_fd_apply_bit
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_cancel
        jp      ui_draw_button

; HL = flags byte; B: 1 = set focus bit 6, 0 = clear it.
ui_fd_apply_bit:
        bit     0, b
        jr      z, .clr
        set     6, (hl)
        ret
.clr:
        res     6, (hl)
        ret

ui_fd_draw_path:
        ld      a, (ui_theme_window)
        ld      b, a
        ld      a, " "
        ld      d, UI_FD_PATHROW
        ld      e, UI_FD_WX + 1
        ld      h, 1
        ld      l, UI_FD_WW - 2
        call    ui_fill_rect
        ld      hl, ui_fd_lbl_path
        ld      a, (ui_theme_window)
        ld      d, UI_FD_PATHROW
        ld      e, UI_FD_WX + 2
        call    ui_print_z
        ld      hl, ui_fd_path          ; show the tail if it overflows the field
        call    ui_fd_strlen            ; A = len (strlen clobbers HL)
        ld      hl, ui_fd_path
        cp      UI_FD_WW - 10 + 1
        jr      c, .show
        sub     UI_FD_WW - 10
        ld      e, a
        ld      d, 0
        add     hl, de
.show:
        ld      a, (ui_theme_window)
        ld      d, UI_FD_PATHROW
        ld      e, UI_FD_WX + 8
        jp      ui_print_z

;----------------------------------------------------------------------
; Name-field key handling.
;----------------------------------------------------------------------
ui_fd_key_name:
        ld      a, (ui_event_key)
        cp      UI_KEY_ENTER
        jp      z, ui_fd_accept_name
        ld      iy, ui_fd_namefield
        ld      a, (ui_event_scan)
        cp      UI_SCAN_LEFT
        jr      z, .l
        cp      UI_SCAN_RIGHT
        jr      z, .r
        cp      UI_SCAN_HOME
        jr      z, .h
        cp      UI_SCAN_END
        jr      z, .e
        cp      UI_SCAN_DELETE
        jr      z, .del
        ld      a, (ui_event_key)
        cp      08h
        jr      z, .bs
        cp      7Fh
        jr      z, .bs
        cp      " "
        jp      c, ui_file_dialog.loop
        cp      7Fh
        jp      nc, ui_file_dialog.loop
        call    ui_text_field_insert_char
        jr      .rd
.l:
        call    ui_text_field_cursor_left
        jr      .rd
.r:
        call    ui_text_field_cursor_right
        jr      .rd
.h:
        call    ui_text_field_cursor_home
        jr      .rd
.e:
        call    ui_text_field_cursor_end
        jr      .rd
.del:
        call    ui_text_field_delete_at_cursor
        jr      .rd
.bs:
        call    ui_text_field_backspace
.rd:
        ld      a, 1
        ld      (ui_text_cursor_visible), a
        ld      ix, ui_fd_window
        ld      iy, ui_fd_namefield
        call    ui_draw_text_field
        jp      ui_file_dialog.loop

; Accept the Name field. If it is an absolute path ("X:..." or "\..."), it is
; returned verbatim; otherwise ui_fd_result = <cwd> "\" <name>. Finish (CF=0).
ui_fd_accept_name:
        ld      hl, ui_fd_name_buf               ; a wildcard is a filter, not a file
        call    ui_fd_has_wildcard
        jr      nc, .notmask
        ld      hl, ui_fd_name_buf
        ld      de, ui_fd_scan_mask
        call    ui_fd_strcpy
        call    ui_fd_rescan
        call    ui_fd_redraw_listpath
        jp      ui_file_dialog.loop
.notmask:
        ld      hl, ui_fd_name_buf               ; absolute? (leading '\' or a ':')
        ld      a, (hl)
        cp      5Ch
        jr      z, .absolute
.scancolon:
        ld      a, (hl)
        or      a
        jr      z, .relative
        cp      ":"
        jr      z, .absolute
        inc     hl
        jr      .scancolon
.absolute:
        ld      hl, ui_fd_name_buf
        ld      de, ui_fd_result
        call    ui_fd_strcpy
        jp      ui_fd_done_ok
.relative:
        ld      hl, ui_fd_path
        ld      de, ui_fd_result
        call    ui_fd_strcpy                     ; DE -> terminator
        ld      hl, ui_fd_result
        ld      a, (hl)
        or      a
        jr      z, .app
        push    de
        dec     de
        ld      a, (de)
        pop     de
        cp      5Ch
        jr      z, .app
        cp      ":"
        jr      z, .app
        ld      a, 5Ch
        ld      (de), a
        inc     de
.app:
        ld      hl, ui_fd_name_buf
        call    ui_fd_strcpy
        jp      ui_fd_done_ok

;----------------------------------------------------------------------
; List key handling.
;----------------------------------------------------------------------
ui_fd_key_list:
        ld      a, (ui_event_key)
        cp      UI_KEY_ENTER
        jp      z, ui_fd_list_enter
        cp      UI_KEY_SPACE
        jp      z, ui_fd_list_enter
        ld      a, (ui_event_scan)
        cp      UI_SCAN_DOWN
        jr      z, .down
        cp      50h
        jr      z, .down
        cp      72h
        jr      z, .down
        cp      UI_SCAN_UP
        jr      z, .up
        cp      48h
        jr      z, .up
        cp      75h
        jr      z, .up
        cp      UI_SCAN_RIGHT
        jr      z, .right
        cp      4Dh
        jr      z, .right
        cp      UI_SCAN_LEFT
        jr      z, .left
        cp      4Bh
        jr      z, .left
        cp      UI_SCAN_PGDN
        jp      z, .pgdn
        cp      UI_SCAN_PGUP
        jp      z, .pgup
        cp      UI_SCAN_HOME
        jp      z, .home
        cp      UI_SCAN_END
        jp      z, .end
        jp      ui_file_dialog.loop
.pgdn:
        ld      hl, (ui_fd_selected)
        ld      de, 2 * UI_FD_LROWS
        add     hl, de
        ld      (ui_fd_selected), hl
        jr      .moved
.pgup:
        ld      hl, (ui_fd_selected)
        ld      de, 2 * UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      nc, .pgup_set
        ld      hl, 0
.pgup_set:
        ld      (ui_fd_selected), hl
        jr      .moved
.down:
        ld      hl, (ui_fd_selected)
        inc     hl
        ld      (ui_fd_selected), hl
        jr      .moved
.up:
        ld      hl, (ui_fd_selected)
        ld      a, h
        or      l
        jp      z, ui_file_dialog.loop
        dec     hl
        ld      (ui_fd_selected), hl
        jr      .moved
.right:
        ld      hl, (ui_fd_selected)
        ld      de, UI_FD_LROWS
        add     hl, de
        ld      (ui_fd_selected), hl
        jr      .moved
.left:
        ld      hl, (ui_fd_selected)
        ld      de, UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      nc, .left_set                   ; underflow from column 0 -> top
        ld      hl, 0
.left_set:
        ld      (ui_fd_selected), hl
        jr      .moved
.home:
        ld      hl, 0
        ld      (ui_fd_selected), hl
        jr      .moved
.end:
        ld      hl, (ui_fd_count)
        ld      a, h
        or      l
        jp      z, ui_file_dialog.loop
        dec     hl
        ld      (ui_fd_selected), hl
.moved:
        call    ui_fd_list_clamp
        call    ui_fd_list_make_visible
        call    ui_fd_draw_list
        jp      ui_file_dialog.loop

; Enter on the list: [..] / [DIR] -> navigate, file -> accept.
ui_fd_list_enter:
        call    ui_fd_map_page
        jp      c, ui_file_dialog.loop
        ld      hl, (ui_fd_selected)
        call    ui_fd_read_name
        call    ui_fd_unmap_page
        ld      a, (ui_fd_drawisdir)
        or      a
        jr      z, .file
        ld      hl, ui_fd_drawname + 1           ; strip [ ]
        ld      de, ui_fd_dirtmp
.strip:
        ld      a, (hl)
        or      a
        jr      z, .stripdone
        cp      "]"
        jr      z, .stripdone
        ld      (de), a
        inc     hl
        inc     de
        jr      .strip
.stripdone:
        xor     a
        ld      (de), a
        ld      hl, ui_fd_dirtmp
        call    ui_fd_set_cwd
        call    ui_fd_rescan
        call    ui_fd_redraw_listpath
        jp      ui_file_dialog.loop
.file:
        ld      hl, ui_fd_drawname
        ld      de, ui_fd_name_buf
        call    ui_fd_strcpy
        jp      ui_fd_accept_name

;----------------------------------------------------------------------
; Drive combo key handling.
;----------------------------------------------------------------------
ui_fd_key_drive:
        ld      a, (ui_event_key)
        cp      UI_KEY_ENTER
        jr      z, .open
        cp      UI_KEY_SPACE
        jr      z, .open
        jp      ui_file_dialog.loop
.open:
        call    ui_fd_drive_dropdown
        jp      ui_file_dialog.loop

; Open the drive dropdown; on commit, switch drive and rescan. Only the combo,
; path line and list are repainted (no full-window clear), so there is no flash.
ui_fd_drive_dropdown:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        call    ui_combo_select_popup
        jr      c, .redraw
        ld      a, (ui_fd_drive_combo + UI_COMBO_SELECTED)
        ld      c, Dss.ChDisk
        call    ui_call_dss
        ld      hl, ui_fd_dot
        call    ui_fd_set_cwd
        call    ui_fd_rescan
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        call    ui_draw_combo_box
        jp      ui_fd_redraw_listpath
.redraw:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_drive_combo
        jp      ui_draw_combo_box

;----------------------------------------------------------------------
; Mouse: dispatch a left click to a button or the list.
;----------------------------------------------------------------------
ui_fd_mouse:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_event_mouse_x)
        call    ui_button_hit_test
        jp      nc, .ok
        ld      iy, ui_fd_btn_cancel
        ld      a, (ui_event_mouse_y)
        ld      b, a
        ld      a, (ui_event_mouse_x)
        call    ui_button_hit_test
        jp      nc, .cancel
        ld      a, (ui_event_mouse_y)           ; Name field?
        cp      UI_FD_WY + 4
        jr      nz, .notname
        ld      a, (ui_event_mouse_x)
        cp      UI_FD_WX + 8
        jr      c, .notname
        cp      UI_FD_WX + 8 + 38
        jr      nc, .notname
        ld      a, UI_FD_FOC_NAME
        ld      (ui_fd_focus), a
        call    ui_fd_move_focus
        jp      ui_file_dialog.loop
.notname:
        ld      a, (ui_event_mouse_y)           ; Drive combo?
        cp      UI_FD_WY + 2
        jr      nz, .notdrive
        ld      a, (ui_event_mouse_x)
        cp      UI_FD_WX + 9
        jr      c, .notdrive
        cp      UI_FD_WX + 9 + 11
        jr      nc, .notdrive
        ld      a, UI_FD_FOC_DRIVE
        ld      (ui_fd_focus), a
        call    ui_fd_move_focus
        call    ui_fd_drive_dropdown
        jp      ui_file_dialog.loop
.notdrive:
        ld      a, (ui_event_mouse_y)           ; scroll bar arrows?
        cp      UI_FD_HS_ROW
        jr      nz, .notscroll
        ld      a, (ui_event_mouse_x)
        cp      UI_FD_HS_X0
        jr      z, .scroll_left
        cp      UI_FD_HS_X0 + UI_FD_HS_TRACKW + 1
        jp      z, .scroll_right
        jp      ui_file_dialog.loop
.scroll_left:
        ld      hl, (ui_fd_selected)
        ld      de, 2 * UI_FD_LROWS
        or      a
        sbc     hl, de
        jr      nc, .scroll_apply
        ld      hl, 0
.scroll_apply:
        ld      (ui_fd_selected), hl
        call    ui_fd_list_clamp
        call    ui_fd_list_make_visible
        ld      a, UI_FD_FOC_LIST
        ld      (ui_fd_focus), a
        call    ui_fd_move_focus
        jp      ui_file_dialog.loop
.scroll_right:
        ld      hl, (ui_fd_selected)
        ld      de, 2 * UI_FD_LROWS
        add     hl, de
        jr      .scroll_apply
.notscroll:
        ld      a, (ui_fd_focus)                ; list_mouse draws with the focus
        cp      UI_FD_FOC_LIST                  ; that is in effect, so make the
        jr      z, .listfocused                 ; list focused first if needed
        ld      a, UI_FD_FOC_LIST
        ld      (ui_fd_focus), a
        call    ui_fd_move_focus                ; unfocus old widget; draw list
.listfocused:
        call    ui_fd_list_mouse                ; selection redraws only the list
        jp      c, ui_file_dialog.loop          ; no list hit
        or      a
        jp      z, ui_file_dialog.loop
        jp      ui_fd_list_enter
.ok:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_ok
        call    ui_button_press_mouse_feedback
        jp      c, ui_file_dialog.loop
        jp      ui_fd_accept_name
.cancel:
        ld      ix, ui_fd_window
        ld      iy, ui_fd_btn_cancel
        call    ui_button_press_mouse_feedback
        jp      c, ui_file_dialog.loop
        jp      ui_file_dialog.cancel

; Out: CF=1 no list hit; CF=0 with A=0 selected (redrawn), A=1 enter requested.
ui_fd_list_mouse:
        ld      a, (ui_event_mouse_y)
        ld      c, a
        ld      a, UI_FD_WY + UI_FD_LY + 1
        ld      b, a
        ld      a, c
        sub     b
        ret     c
        cp      UI_FD_LROWS
        ccf
        ret     c
        ld      (ui_fd_drow), a
        ld      a, (ui_event_mouse_x)
        ld      c, a
        ld      a, UI_FD_WX + UI_FD_LX + 1
        ld      b, a
        ld      a, c
        sub     b
        ret     c
        cp      UI_FD_COLW
        jr      c, .col0
        sub     UI_FD_COLW
        cp      UI_FD_COLW
        ccf
        ret     c
        ld      a, 1
        jr      .setcol
.col0:
        xor     a
.setcol:
        ld      (ui_fd_dcol), a
        or      a
        ld      e, 0
        jr      z, .nc
        ld      e, UI_FD_LROWS
.nc:
        ld      a, (ui_fd_drow)
        add     a, e
        ld      e, a
        ld      d, 0
        ld      hl, (ui_fd_top)
        add     hl, de                           ; HL = entry index
        ld      de, (ui_fd_count)
        push    hl
        or      a
        sbc     hl, de
        pop     hl
        ccf
        ret     c                                ; entry >= count -> miss
        ld      de, (ui_fd_selected)
        push    hl
        or      a
        sbc     hl, de
        pop     hl
        jr      z, .enter
        ld      (ui_fd_selected), hl
        call    ui_fd_draw_list
        xor     a
        ret
.enter:
        ld      a, 1
        or      a
        ret

;----------------------------------------------------------------------
; Small string helpers.
;----------------------------------------------------------------------
ui_fd_strcpy:
        ld      a, (hl)
        ld      (de), a
        or      a
        ret     z
        inc     hl
        inc     de
        jr      ui_fd_strcpy

ui_fd_strlen:
        ld      b, 0
.l:
        ld      a, (hl)
        or      a
        jr      z, .d
        inc     hl
        inc     b
        jr      .l
.d:
        ld      a, b
        ret

; CF=1 if the ASCIIZ string at HL contains a '*' or '?' wildcard.
ui_fd_has_wildcard:
        ld      a, (hl)
        or      a
        ret     z
        cp      "*"
        jr      z, .yes
        cp      "?"
        jr      z, .yes
        inc     hl
        jr      ui_fd_has_wildcard
.yes:
        scf
        ret

;----------------------------------------------------------------------
; Data (WIN1). The bulk name buffer lives in the DSS page, not here.
;----------------------------------------------------------------------
ui_fd_window:
        db      UI_FD_WX, UI_FD_WY, UI_FD_WW, UI_FD_WH
        dw      0
        db      UI_FRAME_DOUBLE
ui_fd_drive_combo:
        db      9, 2, 8, 0, 0
        dw      ui_fd_drive_items
        db      UI_FD_DRIVES, 0, 6
ui_fd_namefield:
        db      8, 4, 38, 0, 0
        dw      ui_fd_name_buf
        db      63, 0, 0
ui_fd_btn_ok:
        db      UI_FD_BTNX, 7, 0, UI_CMD_OK, 0
        dw      ui_fd_lbl_open
ui_fd_btn_cancel:
        db      UI_FD_BTNX, 10, 0, UI_CMD_CANCEL, 0
        dw      ui_fd_lbl_cancel

ui_fd_drive_items:
        dw      ui_fd_drv_a, ui_fd_drv_b, ui_fd_drv_c
        dw      ui_fd_drv_d, ui_fd_drv_e, ui_fd_drv_f
ui_fd_drv_a:    db "A:", 0
ui_fd_drv_b:    db "B:", 0
ui_fd_drv_c:    db "C:", 0
ui_fd_drv_d:    db "D:", 0
ui_fd_drv_e:    db "E:", 0
ui_fd_drv_f:    db "F:", 0

ui_fd_lbl_drive:  db "Drive:", 0
ui_fd_lbl_name:   db "Name:", 0
ui_fd_lbl_files:  db " Files ", 0
ui_fd_lbl_path:   db "Path: ", 0
ui_fd_lbl_open:   db "   Open   ", 0
ui_fd_lbl_save:   db "   Save   ", 0
ui_fd_lbl_cancel: db "  Cancel  ", 0
ui_fd_dot:        db ".", 0

ui_fd_mode:       db 0
ui_fd_focus:      db 0
ui_fd_drawn_focus: db 0FFh
ui_fd_title:      dw 0
ui_fd_selected:   dw 0
ui_fd_top:        dw 0
ui_fd_dcol:       db 0
ui_fd_drow:       db 0
ui_fd_visidx:     dw 0
ui_fd_visp:       db 0
ui_fd_slotptr:    dw 0
ui_fd_drawisdir:  db 0
ui_fd_cellattr:   db 0
ui_fd_lastsep:    dw 0
ui_fd_drawname:   ds UI_FD_NAMELEN + 1
ui_fd_vis:        ds 2 * UI_FD_LROWS * UI_FD_RECLEN
ui_fd_input:      ds 96
ui_fd_path:       ds 96
ui_fd_savedcwd:   ds 96
ui_fd_dirtmp:     ds 96
ui_fd_name_buf:   ds 64
ui_fd_result:     ds 160

;----------------------------------------------------------------------
; Original data continues below (page state, scan scratch).
;----------------------------------------------------------------------
ui_fd_block_id:
        db      0
ui_fd_saved_p3:
        db      0
ui_fd_page_num:
        db      0
ui_fd_count:
        dw      0
ui_fd_pass:
        db      0
ui_fd_se_src:
        dw      0
ui_fd_se_isdir:
        db      0
ui_fd_mask:
        db      "*.*", 0
ui_fd_scan_mask:
        db      "*.*", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
ui_fd_dotdot:
        db      "[..]", 0
ui_fd_tmpname:
        ds      UI_FD_NAMELEN + 2
ui_fd_findbuf:
        ds      48
