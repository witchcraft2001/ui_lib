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

; MenuBar descriptor:
;   +0 x
;   +1 y
;   +2 width
;   +3 word menu item table

UI_MENU_BAR_X           equ     0
UI_MENU_BAR_Y           equ     1
UI_MENU_BAR_W           equ     2
UI_MENU_BAR_ITEMS       equ     3
UI_MENU_BAR_SIZE        equ     5

; MenuBar item descriptor:
;   +0 x relative to menu bar
;   +1 flags
;   +2 hot key ASCII or scan code
;   +3 hot key modifiers/flags, see UI_HOTKEY_* constants
;   +4 word label ASCIIZ, '&' marks visible mnemonic
;   +6 word popup item table, may be 0
;   +8 popup width including frame
;   +9 word hint ASCIIZ, may be 0

UI_MENU_ITEM_X          equ     0
UI_MENU_ITEM_FLAGS      equ     1
UI_MENU_ITEM_HOTKEY     equ     2
UI_MENU_ITEM_HOTKEY_MODS equ    3
UI_MENU_ITEM_LABEL      equ     4
UI_MENU_ITEM_POPUP      equ     6
UI_MENU_ITEM_POPUP_W    equ     8
UI_MENU_ITEM_HINT       equ     9
UI_MENU_ITEM_SIZE       equ     11

; Menu popup item descriptor:
;   +0 flags, bit 7 = disabled, bit 2 = separator
;   +1 hot key ASCII or scan code
;   +2 hot key modifiers/flags, see UI_HOTKEY_* constants
;   +3 command
;   +4 word label ASCIIZ, '&' marks visible mnemonic
;   +6 word hint ASCIIZ, may be 0

UI_MENU_POPUP_FLAGS     equ     0
UI_MENU_POPUP_HOTKEY    equ     1
UI_MENU_POPUP_HOTKEY_MODS equ   2
UI_MENU_POPUP_COMMAND   equ     3
UI_MENU_POPUP_LABEL     equ     4
UI_MENU_POPUP_HINT      equ     6
UI_MENU_POPUP_SIZE      equ     8

; Dialog descriptor:
;   +0 word window descriptor
;   +2 word buttons table
;   +4 word checkbox table, may be 0
;   +6 word radio button table, may be 0
;   +8 word group box table, may be 0
;   +10 word separator table, may be 0
;   +12 word text field table, may be 0
;   +14 word item selector table, may be 0
;   +16 word combo box table, may be 0
;   +18 word hint table, may be 0 when UI_ENABLE_HINTS is enabled

UI_DIALOG_WINDOW        equ     0
UI_DIALOG_BUTTONS       equ     2
UI_DIALOG_CHECKS        equ     4
UI_DIALOG_RADIOS        equ     6
UI_DIALOG_GROUPS        equ     8
UI_DIALOG_SEPARATORS    equ     10
UI_DIALOG_TEXT_FIELDS   equ     12
UI_DIALOG_ITEM_SELECTORS        equ     14
UI_DIALOG_COMBOS        equ     16
UI_DIALOG_HINTS         equ     18
UI_DIALOG_SIZE          equ     20

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

; TextField descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 width
;   +3 flags, bit UI_FLAG_PASSWORD masks displayed text
;   +4 hot key ASCII, 0 if none
;   +5 word editable ASCIIZ buffer in RAM
;   +7 max input length
;   +8 cursor position in buffer
;   +9 horizontal scroll offset

UI_TEXT_X               equ     0
UI_TEXT_Y               equ     1
UI_TEXT_W               equ     2
UI_TEXT_FLAGS           equ     3
UI_TEXT_HOTKEY          equ     4
UI_TEXT_BUFFER          equ     5
UI_TEXT_MAXLEN          equ     7
UI_TEXT_CURSOR          equ     8
UI_TEXT_SCROLL          equ     9
UI_TEXT_SIZE            equ     10

; ItemSelector descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 width
;   +3 flags
;   +4 hot key ASCII
;   +5 word item pointer table, each item is ASCIIZ
;   +7 item count
;   +8 selected item index

UI_ITEM_SELECTOR_X              equ     0
UI_ITEM_SELECTOR_Y              equ     1
UI_ITEM_SELECTOR_W              equ     2
UI_ITEM_SELECTOR_FLAGS          equ     3
UI_ITEM_SELECTOR_HOTKEY         equ     4
UI_ITEM_SELECTOR_ITEMS          equ     5
UI_ITEM_SELECTOR_COUNT          equ     7
UI_ITEM_SELECTOR_SELECTED       equ     8
UI_ITEM_SELECTOR_SIZE           equ     9

; ComboBox descriptor:
;   +0 x relative to parent window
;   +1 y relative to parent window
;   +2 width
;   +3 flags
;   +4 hot key ASCII
;   +5 word item pointer table, each item is ASCIIZ
;   +7 item count
;   +8 selected item index
;   +9 popup height

UI_COMBO_X              equ     0
UI_COMBO_Y              equ     1
UI_COMBO_W              equ     2
UI_COMBO_FLAGS          equ     3
UI_COMBO_HOTKEY         equ     4
UI_COMBO_ITEMS          equ     5
UI_COMBO_COUNT          equ     7
UI_COMBO_SELECTED       equ     8
UI_COMBO_POPUP_H        equ     9
UI_COMBO_SIZE           equ     10

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
;   +12 text field
;   +13 focused text field
;   +14 focused horizontal menu item
;   +15 focused vertical/dropdown menu item
;   +16 disabled menu item
