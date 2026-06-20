; Public constants for the Sprinter text-mode UI library.
; Comments in source files are intentionally English.

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
UI_HOTKEY_USE_SCAN     equ     80h
UI_HOTKEY_NO_MNEMONIC  equ     40h

UI_KEYMOD_ALT_ANY      equ     15h     ; DSS ScanKey B bits 4, 2, 0

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
UI_SCAN_LEFT           equ     54h
UI_SCAN_RIGHT          equ     56h
UI_SCAN_HOME           equ     57h
UI_SCAN_UP             equ     58h

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
