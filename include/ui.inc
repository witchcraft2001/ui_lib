; Public include for applications using selected UI modules.
;
; Applications choose implementation modules explicitly, for example:
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

UI_DIALOG_WINDOW        equ     0
UI_DIALOG_BUTTONS       equ     2
