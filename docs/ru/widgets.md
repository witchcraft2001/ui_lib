# Виджеты

## MenuBar

`MenuBar` рисует верхнюю строку меню и dropdown-окна по таблицам. Координаты задаются явно, поэтому модуль не требует фиксированного адреса и может использоваться отдельно от `Dialog`. `ui_menu_bar_run` держит фокус на верхней строке, `Left`/`Right` переключают пункты меню, `Enter`/mouse click открывают dropdown, `Up`/`Down` двигают выбор внутри открытого dropdown, `Esc` закрывает dropdown или выходит из меню.

```asm
menu_bar:
        db      0, 0, 80
        dw      menu_items

menu_items:
        db      1, 0, "f"
        dw      file_label
        dw      file_popup
        db      14                  ; popup width
        db      UI_MENU_ITEMS_END

file_popup:
        db      0, "x", UI_CMD_CANCEL
        dw      exit_label
        dw      exit_hint
        db      UI_MENU_POPUP_END
```

MenuBar item: `x, flags, hotkey, label_ptr, popup_ptr, popup_width`. Popup item: `flags, hotkey, command, label_ptr, hint_ptr`. Для separator используйте `UI_FLAG_SEPARATOR`.

## GroupBox

`GroupBox` рисует рамку внутри родительского окна. Координаты относительны `UI_WINDOW_X/Y`.

```asm
group_example:
        db      3, 3, 21, 5
        dw      group_title
group_title:
        db      " Options ", 0

        ld      ix, window_desc
        ld      iy, group_example
        call    ui_draw_group_box
```

Формат: `x, y, width, height, title_ptr`. Минимальный размер: `2x2`.

## Separator

`Separator` рисует горизонтальную линию внутри окна. Используется для отделения блоков в диалогах и выпадающих меню.

```asm
separator_example:
        db      3, 9, 44

        ld      ix, window_desc
        ld      iy, separator_example
        call    ui_draw_separator
```

Формат: `x, y, width`.

## CheckBox

`CheckBox` хранит состояние в `flags`: бит `UI_FLAG_CHECKED` означает выбранное состояние. Дескриптор должен быть в RAM, если приложение вызывает `ui_toggle_checkbox`.

```asm
check_example:
        db      5, 5, UI_FLAG_CHECKED, "p"
        dw      check_label
check_label:
        db      "&Password mask", 0

        ld      ix, window_desc
        ld      iy, check_example
        call    ui_draw_checkbox
```

Формат: `x, y, flags, hotkey, label_ptr`.

## TextField

`TextField` хранит редактируемый текст в ASCIIZ-буфере приложения. Дескриптор и буфер должны быть в RAM. `UI_FLAG_PASSWORD` маскирует отображение символами `*`. Активное поле мигает знакоместом курсора, сохраняя символ под ним.

```asm
text_example:
        db      5, 6, 12, UI_FLAG_PASSWORD, "n"
        dw      text_buffer
        db      12, 0
text_buffer:
        db      "demo", 0
        ds      9, 0

        ld      ix, window_desc
        ld      iy, text_example
        call    ui_draw_text_field
```

Формат: `x, y, width, flags, hotkey, buffer_ptr, max_len, cursor`.

## ItemSelector

`ItemSelector` хранит выбранный индекс в descriptor и показывает строку из таблицы ASCIIZ-указателей. Это компактный selector без выпадающего popup: `Space`, `Enter`, hotkey или mouse click переключают следующий пункт по кругу, `Left` переключает в обратную сторону, `Right` - вперед.

```asm
item_selector_example:
        db      5, 11, 16, 0, "t"
        dw      item_selector_items
        db      3, 0                 ; count, selected index

item_selector_items:
        dw      item_tasm
        dw      item_fformat
        dw      item_blue
```

Формат: `x, y, width, flags, hotkey, items_ptr, count, selected`.

## ComboBox

`ComboBox` использует такую же таблицу строк, но открывает выпадающий список с отдельной рамкой и фоном. `Space`, `Enter`, hotkey или mouse click открывают popup. Внутри popup работают `Up`/`Down`/`Home`/`End`, `Enter` или click выбирает пункт, `Esc` или click вне popup отменяет выбор. Если элементов больше высоты popup, на правой рамке показывается маркер прокрутки.

```asm
combo_example:
        db      26, 11, 16, 0, "d"
        dw      combo_items
        db      3, 0, 3              ; count, selected index, popup height

combo_items:
        dw      item_drive_a
        dw      item_drive_b
        dw      item_ram
```

Формат: `x, y, width, flags, hotkey, items_ptr, count, selected, popup_height`.

## Dialog Navigation

`ui_dialog_run` поддерживает фокус для `TextField`, `CheckBox`, `RadioButton`, `ItemSelector`, `ComboBox` и `Button`. Порядок обхода: text field table, checkbox table, radio table, item selector table, combo box table, button table.

- `Tab` переводит фокус вперед.
- `Shift+Tab` или `Alt+Tab` переводит фокус назад.
- Печатные клавиши редактируют активное текстовое поле. `Backspace` удаляет символ перед курсором, `Delete` удаляет символ под курсором, `Left`/`Right`/`Home`/`End` двигают курсор.
- `Space` вводит пробел в активное текстовое поле или активирует другой элемент. `Enter` активирует текущий элемент. Для `ItemSelector` активация выбирает следующий пункт; для `ComboBox` открывает popup.
- Hotkey из descriptor активирует элемент напрямую.
- Мышь переводит фокус на элемент под курсором и активирует его.
- Если перед сборкой определить `DEFINE UI_ENABLE_HINTS 1` и подключить `src/core/hint.asm`, диалог будет обновлять нижнюю строку подсказки по текущему focus index.

Расширенный dialog descriptor:

```asm
dialog_example:
        dw      window_desc
        dw      buttons_table
        dw      checks_table
        dw      radios_table
        dw      groups_table
        dw      separators_table
        dw      text_fields_table
        dw      item_selectors_table
        dw      combos_table
        dw      hints_table          ; optional when UI_ENABLE_HINTS=1

hints_table:
        dw      text_field_hint
        dw      checkbox_hint
        dw      first_radio_hint
        dw      second_radio_hint
        dw      item_selector_hint
        dw      combo_hint
        dw      ok_button_hint
        dw      cancel_button_hint
```

Таблицы завершаются байтом `UI_*_END`. Для отсутствующей таблицы можно указать `0`. Таблица подсказок содержит word-указатели в том же порядке, что и обход фокуса.

## Status Hint Line

`ui_set_context_hint` печатает ASCIIZ-строку в нижней строке экрана (`row 31`) цветом `ui_theme_hint`; `ui_clear_context_hint` очищает эту строку. Модуль зависит только от `src/draw/text.asm` и темы.

```asm
        include "src/core/hint.asm"

        ld      hl, hint_text
        call    ui_set_context_hint
```

## RadioButton

`RadioButton` использует тот же бит `UI_FLAG_CHECKED`. Сейчас реализованы базовые функции отрисовки и установки выбранного состояния; управление группой будет добавлено в dialog/focus layer.

```asm
radio_example:
        db      28, 5, UI_FLAG_CHECKED, "f"
        dw      radio_label
radio_label:
        db      "&Fast mode", 0

        ld      ix, window_desc
        ld      iy, radio_example
        call    ui_draw_radio_button
```

Формат: `x, y, flags, hotkey, label_ptr`.
