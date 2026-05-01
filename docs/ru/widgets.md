# Виджеты

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

## Dialog Navigation

`ui_dialog_run` поддерживает фокус для `TextField`, `CheckBox`, `RadioButton` и `Button`. Порядок обхода: text field table, checkbox table, radio table, button table.

- `Tab` переводит фокус вперед.
- `Shift+Tab` или `Alt+Tab` переводит фокус назад.
- Печатные клавиши редактируют активное текстовое поле. `Backspace` удаляет символ перед курсором, `Delete` удаляет символ под курсором, `Left`/`Right`/`Home`/`End` двигают курсор.
- `Space` вводит пробел в активное текстовое поле или активирует другой элемент. `Enter` активирует текущий элемент.
- Hotkey из descriptor активирует элемент напрямую.
- Мышь переводит фокус на элемент под курсором и активирует его.

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
```

Таблицы завершаются байтом `UI_*_END`. Для отсутствующей таблицы можно указать `0`.

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
