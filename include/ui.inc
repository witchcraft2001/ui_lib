; Public include for applications using selected UI modules.
;
; Applications choose implementation modules explicitly, for example:
;   include "src/core/theme.asm"
;   include "src/core/init.asm"
;   include "src/draw/text.asm"
;   include "src/widgets/window.asm"
;   include "src/widgets/button.asm"

        include "include/sprinter.inc"
        include "include/ui_defs.inc"

; Window descriptor:
;   +0 x
;   +1 y
;   +2 width
;   +3 height
;   +4 word title ASCIIZ

UI_WINDOW_X             equ     0
UI_WINDOW_Y             equ     1
UI_WINDOW_W             equ     2
UI_WINDOW_H             equ     3
UI_WINDOW_TITLE         equ     4

; Button descriptor:
;   +0 x relative to parent
;   +1 y relative to parent
;   +2 flags
;   +3 command
;   +4 hot key scan code
;   +5 word label ASCIIZ, '&' marks hot character

UI_BUTTON_X             equ     0
UI_BUTTON_Y             equ     1
UI_BUTTON_FLAGS         equ     2
UI_BUTTON_COMMAND       equ     3
UI_BUTTON_HOTKEY        equ     4
UI_BUTTON_LABEL         equ     5
UI_BUTTON_SIZE          equ     7

; Dialog descriptor:
;   +0 word window descriptor
;   +2 word buttons table
;   +4 word checkbox table, may be 0
;   +6 word radio button table, may be 0
;   +8 word group box table, may be 0
;   +10 word separator table, may be 0

UI_DIALOG_WINDOW        equ     0
UI_DIALOG_BUTTONS       equ     2
UI_DIALOG_CHECKS        equ     4
UI_DIALOG_RADIOS        equ     6
UI_DIALOG_GROUPS        equ     8
UI_DIALOG_SEPARATORS    equ     10
UI_DIALOG_SIZE          equ     12

; GroupBox descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 width
;   +3 height
;   +4 word title ASCIIZ, may be 0

UI_GROUP_X              equ     0
UI_GROUP_Y              equ     1
UI_GROUP_W              equ     2
UI_GROUP_H              equ     3
UI_GROUP_TITLE          equ     4
UI_GROUP_SIZE           equ     6

; Separator descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 width

UI_SEPARATOR_X          equ     0
UI_SEPARATOR_Y          equ     1
UI_SEPARATOR_W          equ     2
UI_SEPARATOR_SIZE       equ     3

; CheckBox descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 flags, bit 0 = checked
;   +3 hot key ASCII
;   +4 word label ASCIIZ, '&' marks hot character

UI_CHECK_X              equ     0
UI_CHECK_Y              equ     1
UI_CHECK_FLAGS          equ     2
UI_CHECK_HOTKEY         equ     3
UI_CHECK_LABEL          equ     4
UI_CHECK_SIZE           equ     6

; RadioButton descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 flags, bit 0 = checked
;   +3 hot key ASCII
;   +4 word label ASCIIZ, '&' marks hot character

UI_RADIO_X              equ     0
UI_RADIO_Y              equ     1
UI_RADIO_FLAGS          equ     2
UI_RADIO_HOTKEY         equ     3
UI_RADIO_LABEL          equ     4
UI_RADIO_SIZE           equ     6

; Theme table for ui_set_theme:
;   +0 desktop
;   +1 window
;   +2 window title
;   +3 hotkey
;   +4 button
;   +5 focused button
;   +6 disabled
;   +7 window shadow
;   +8 hint/status line
;   +9 button shadow
;   +10 button hotkey
;   +11 focused button hotkey
