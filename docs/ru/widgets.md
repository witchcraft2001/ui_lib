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

## Dialog Navigation

`ui_dialog_run` поддерживает фокус для `CheckBox`, `RadioButton` и `Button`. Порядок обхода: checkbox table, radio table, button table.

- `Tab` переводит фокус вперед.
- `Shift+Tab` или `Alt+Tab` переводит фокус назад.
- `Space` и `Enter` активируют текущий элемент.
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
