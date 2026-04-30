; Public constants for the Sprinter text-mode UI library.
; Comments in source files are intentionally English.

UI_SCREEN_COLS          equ     80
UI_SCREEN_ROWS          equ     32

UI_COLOR_DESKTOP        equ     17h     ; blue background, white text
UI_COLOR_WINDOW         equ     1Fh
UI_COLOR_WINDOW_TITLE   equ     1Eh
UI_COLOR_HOTKEY         equ     1Ch
UI_COLOR_BUTTON         equ     70h
UI_COLOR_BUTTON_FOCUS   equ     4Fh
UI_COLOR_DISABLED       equ     18h
UI_COLOR_SHADOW         equ     08h
UI_COLOR_HINT           equ     1Eh

UI_FLAG_DISABLED        equ     80h
UI_FLAG_FOCUSED         equ     40h
UI_FLAG_PRESSED         equ     20h

UI_CMD_NONE             equ     00h
UI_CMD_OK               equ     01h
UI_CMD_CANCEL           equ     02h

UI_EVENT_NONE           equ     00h
UI_EVENT_MOUSE          equ     01h
UI_EVENT_KEY            equ     02h
UI_EVENT_COMBO_KEY      equ     03h
UI_EVENT_COMMAND        equ     04h
UI_EVENT_MESSAGE        equ     05h

UI_KEY_ENTER           equ     0Dh
UI_KEY_ESCAPE          equ     1Bh
UI_KEY_TAB             equ     09h

UI_BUTTONS_END         equ     0FFh
