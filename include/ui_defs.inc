; Public constants for the Sprinter text-mode UI library.
; Comments in source files are intentionally English.

; Build-time configuration. Override with DEFINE before including this file.
;
; DSS/BIOS calling convention used by ui_call_dss / ui_call_bios, in priority
; order:
;   1. DEFINE UI_CALL_DSS_HOOK / UI_CALL_BIOS_HOOK = app routine label.
;      ui_lib tail-jumps into it and imposes no convention at all. Most
;      flexible: the app owns paging and stack for the firmware call. Each
;      hook is independent, so you may hook only DSS or only BIOS.
;   2. UI_SYSCALL_PLAIN_RST=1 : plain "rst 10h/08h + ret". For apps that own
;      WIN0 and route every RST through their own trampolines.
;   3. UI_SYSCALL_PLAIN_RST=0 (default) : legacy WIN2-borrow over a temporary
;      stack. Assumes the app lives in WIN1 and WIN2 is free scratch, as in
;      the bundled examples.
; A hook takes precedence over UI_SYSCALL_PLAIN_RST. UI_SAFE_STACK is the
; scratch stack used only by the legacy path; relocate it if WIN2
; 0x8000..0x8040 is not free in your memory model.
        IFNDEF UI_SYSCALL_PLAIN_RST
UI_SYSCALL_PLAIN_RST    equ     0
        ENDIF
        IFNDEF UI_SAFE_STACK
UI_SAFE_STACK           equ     8040h
        ENDIF

UI_SCREEN_COLS          equ     80
UI_SCREEN_ROWS          equ     32
UI_HINT_LINE_ROW        equ     31

; Window frame styles, stored in the window descriptor at UI_WINDOW_FRAME.
UI_FRAME_DOUBLE         equ     0       ; CP866 double-line box drawing
UI_FRAME_SINGLE         equ     1       ; CP866 single-line box drawing

UI_COLOR_DESKTOP        equ     17h     ; blue background, white text
UI_COLOR_WINDOW         equ     70h     ; gray background, black text
UI_COLOR_WINDOW_TITLE   equ     7Fh
UI_COLOR_HOTKEY         equ     7Eh
UI_COLOR_BUTTON         equ     20h
UI_COLOR_BUTTON_FOCUS   equ     2Fh
UI_COLOR_DISABLED       equ     18h
UI_COLOR_SHADOW         equ     08h
UI_COLOR_BUTTON_SHADOW  equ     70h
UI_COLOR_HINT           equ     1Eh
UI_COLOR_BUTTON_HOTKEY  equ     2Eh
UI_COLOR_BUTTON_FOCUS_HOTKEY equ 2Eh
UI_COLOR_TEXT_FIELD     equ     17h
UI_COLOR_TEXT_FIELD_FOCUS equ   1Fh
UI_COLOR_MENU_BAR_FOCUS equ     2Fh
UI_COLOR_MENU_POPUP_FOCUS equ   0Fh
UI_COLOR_MENU_DISABLED  equ     78h
UI_COLOR_MENU_HOTKEY    equ     0Eh
UI_COLOR_MENU_BAR_FOCUS_HOTKEY equ 2Eh
UI_COLOR_MENU_POPUP_FOCUS_HOTKEY equ 0Eh
UI_COLOR_PROGRESS       equ     17h
UI_COLOR_PROGRESS_FILL  equ     20h

UI_THEME_DESKTOP        equ     0
UI_THEME_WINDOW         equ     1
UI_THEME_WINDOW_TITLE   equ     2
UI_THEME_HOTKEY         equ     3
UI_THEME_BUTTON         equ     4
UI_THEME_BUTTON_FOCUS   equ     5
UI_THEME_DISABLED       equ     6
UI_THEME_SHADOW         equ     7
UI_THEME_HINT           equ     8
UI_THEME_BUTTON_SHADOW  equ     9
UI_THEME_BUTTON_HOTKEY  equ     10
UI_THEME_BUTTON_FOCUS_HOTKEY equ 11
UI_THEME_TEXT_FIELD     equ     12
UI_THEME_TEXT_FIELD_FOCUS equ   13
UI_THEME_MENU_BAR_FOCUS equ     14
UI_THEME_MENU_POPUP_FOCUS equ   15
UI_THEME_MENU_DISABLED  equ     16
UI_THEME_MENU_HOTKEY    equ     17
UI_THEME_MENU_BAR_FOCUS_HOTKEY equ 18
UI_THEME_MENU_POPUP_FOCUS_HOTKEY equ 19
UI_THEME_PROGRESS       equ     20
UI_THEME_PROGRESS_FILL  equ     21
UI_THEME_SIZE           equ     22

UI_FLAG_DISABLED        equ     80h
UI_FLAG_FOCUSED         equ     40h
UI_FLAG_PRESSED         equ     20h
UI_FLAG_SEPARATOR       equ     04h
UI_FLAG_CHECKED         equ     01h
UI_FLAG_PASSWORD        equ     02h
UI_FLAG_INDETERMINATE   equ     08h

UI_CMD_NONE             equ     00h
UI_CMD_OK               equ     01h
UI_CMD_CANCEL           equ     02h

; MessageBox button sets (ui_message_box input) and result codes (output).
UI_MSG_OK               equ     0
UI_MSG_OKCANCEL         equ     1
UI_MSG_YESNO            equ     2
UI_MSG_YESNOCANCEL      equ     3
UI_MSG_ABORTRETRYIGNORE equ     4

UI_MSG_RESULT_OK        equ     1
UI_MSG_RESULT_CANCEL    equ     2
UI_MSG_RESULT_YES       equ     3
UI_MSG_RESULT_NO        equ     4
UI_MSG_RESULT_ABORT     equ     5
UI_MSG_RESULT_RETRY     equ     6
UI_MSG_RESULT_IGNORE    equ     7

; Vertical scroll bar glyphs and hit-test codes (shared by ScrollBar/ListBox).
UI_SCROLL_UP_CHAR       equ     1Eh     ; up arrow
UI_SCROLL_DOWN_CHAR     equ     1Fh     ; down arrow
UI_SCROLL_TRACK_CHAR    equ     0B1h    ; patterned track
UI_SCROLL_THUMB_CHAR    equ     0DBh    ; thumb block
UI_SCROLL_HIT_NONE      equ     00h
UI_SCROLL_HIT_UP        equ     01h
UI_SCROLL_HIT_DOWN      equ     02h
UI_SCROLL_HIT_TRACK     equ     03h

; ListBox mouse-hit sentinels (returned instead of an item index).
UI_LIST_MOUSE_SCROLL_UP   equ   0FEh
UI_LIST_MOUSE_SCROLL_DOWN equ   0FDh
UI_LIST_MOUSE_NO_ACTION   equ   0FCh

UI_EVENT_NONE           equ     00h
UI_EVENT_MOUSE          equ     01h
UI_EVENT_KEY            equ     02h
UI_EVENT_HOTKEY         equ     03h
UI_EVENT_COMMAND        equ     04h
UI_EVENT_MESSAGE        equ     05h

UI_KEY_ENTER           equ     0Dh
UI_KEY_ESCAPE          equ     1Bh
UI_KEY_TAB             equ     09h
UI_KEY_SPACE           equ     20h

UI_HOTKEY_MOD_NONE     equ     00h
UI_HOTKEY_MOD_ALT      equ     10h
UI_HOTKEY_MOD_CTRL     equ     20h
UI_HOTKEY_USE_SCAN     equ     80h
UI_HOTKEY_NO_MNEMONIC  equ     40h

; Dss.ScanKey returns the keyboard shift state in register B; events.asm stores
; it verbatim in ui_event_mods. Bit layout (DSS manual / sprinter_dss KEYINTER):
;   bit7 Left Shift    bit6 Right Shift
;   bit5 Ctrl (any)    bit4 Alt (any)
;   bit3 Left Ctrl     bit2 Left Alt
;   bit1 Right Ctrl    bit0 Right Alt
; Each _ANY mask covers the generic bit plus both side bits, so a single AND
; detects the modifier regardless of which physical key was used.
; Note: DSS sets bit7 on the positional code (D / ui_event_scan) for Alt/Ctrl
; combinations, so scan-code matching must mask it off (and 7Fh).
UI_KEYMOD_ALT_ANY      equ     15h     ; bits 4, 2, 0
UI_KEYMOD_CTRL_ANY     equ     2Ah     ; bits 5, 3, 1
UI_KEYMOD_SHIFT_ANY    equ     0C0h    ; bits 7, 6

; DSS ScanKey returns Sprinter keyboard position codes in D.
UI_SCAN_F1             equ     3Bh
UI_SCAN_F2             equ     3Ch
UI_SCAN_F3             equ     3Dh
UI_SCAN_F4             equ     3Eh
UI_SCAN_F5             equ     3Fh
UI_SCAN_F6             equ     40h
UI_SCAN_F7             equ     41h
UI_SCAN_F8             equ     42h
UI_SCAN_F9             equ     43h
UI_SCAN_F10            equ     44h
UI_SCAN_DELETE         equ     4Fh
UI_SCAN_END            equ     51h
UI_SCAN_DOWN           equ     52h
UI_SCAN_PGDN           equ     53h
UI_SCAN_LEFT           equ     54h
UI_SCAN_RIGHT          equ     56h
UI_SCAN_HOME           equ     57h
UI_SCAN_UP             equ     58h
UI_SCAN_PGUP           equ     59h

UI_BUTTONS_END         equ     0FFh
UI_MENU_ITEMS_END      equ     0FFh
UI_MENU_POPUP_END      equ     0FFh
UI_TEXT_FIELDS_END     equ     0FFh
UI_ITEM_SELECTORS_END          equ     0FFh
UI_COMBOS_END          equ     0FFh
UI_PROGRESS_END        equ     0FFh
UI_CHECKS_END          equ     0FFh
UI_RADIOS_END          equ     0FFh
UI_GROUPS_END          equ     0FFh
UI_SEPARATORS_END      equ     0FFh
