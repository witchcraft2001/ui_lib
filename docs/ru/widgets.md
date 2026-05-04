# Виджеты

## Минимальное подключение

Приложение подключает только те `.asm` модули, которые реально использует. Пример `examples/button_only/button_only.asm` собирает окно с одной кнопкой без `Dialog`, `MenuBar`, `TextField`, `CheckBox`, `RadioButton`, `ItemSelector` и `ComboBox`. Пример `examples/menu_only/menu_only.asm` собирает верхнее меню с dropdown, hints, disabled items и hotkeys без `Dialog` и остальных виджетов.

```asm
        include "include/ui.inc"
        include "src/core/theme.asm"
        include "src/core/init.asm"
        include "src/core/events.asm"
        include "src/draw/text.asm"
        include "src/widgets/window.asm"
        include "src/widgets/button.asm"
        include "src/widgets/button_events.asm"
```

Сборка примера:

```sh
run/make.sh
run/create_floppy_image.sh
```

Дефолтный образ `build/demo/ui_demo.img` содержит `UI_DEMO.EXE`, `BUTTON.EXE` и `MENU.EXE`. Отдельный образ только с button-only примером можно создать командой `run/create_floppy_image.sh build/examples/BUTTON_ONLY.EXE build/examples/button_only.img BUTTON.EXE`; только с menu-only примером: `run/create_floppy_image.sh build/examples/MENU_ONLY.EXE build/examples/menu_only.img MENU.EXE`.

Такой подход оставляет выбор за целевой программой: подключить виджет inline в основной код, собрать библиотечный блок под отдельный адрес или вызывать код из отдельной страницы памяти.

Для простого текста без отдельного виджета используйте `ui_print_wrapped_z`: `HL` - ASCIIZ-текст, `A` - атрибут, `D/E` - row/column, `B` - ширина, `C` - максимум строк. Byte `0Ah` внутри строки принудительно переносит вывод на следующую строку. Чтобы инвертировать уже отрисованный однострочный участок без повторной печати текста, вызовите `ui_invert_range`, где `D/E` - row/column, `B` - ширина.

## MenuBar

`MenuBar` рисует верхнюю строку меню и dropdown-окна по таблицам. Координаты задаются явно, поэтому модуль не требует фиксированного адреса и может использоваться отдельно от `Dialog`. `ui_menu_bar_run` держит фокус на верхней строке, `Left`/`Right` переключают пункты меню, `Enter`, `F10` или mouse click открывают dropdown, `F10` закрывает открытый dropdown, `Up`/`Down` двигают выбор внутри открытого dropdown, `Esc` закрывает dropdown или выходит из меню. Shortcut пункта меню ищется по всем dropdown-таблицам, поэтому `Alt+X` или hotkey из другого раскрытого меню работает как accelerator.

```asm
menu_bar:
        db      0, 0, 80
        dw      menu_items

menu_items:
        db      1, 0, "f", UI_HOTKEY_MOD_NONE
        dw      file_label
        dw      file_popup
        db      14                  ; popup width
        dw      file_hint
        db      UI_MENU_ITEMS_END

file_popup:
        db      0, "x", UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_CANCEL
        dw      exit_label
        dw      exit_hint
        db      0, UI_SCAN_F3, UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC
        db      UI_CMD_NONE
        dw      diagnostics_label
        dw      diagnostics_hint
        db      UI_MENU_POPUP_END
```

Структура `MenuBar`: `x, y, width, menu_items_ptr`.

Структура `MenuBar item`: `x, flags, hotkey, hotkey_mods, label_ptr, popup_ptr, popup_width, hint_ptr`.

- `x` - колонка пункта относительно начала menu bar.
- `flags` - `UI_FLAG_DISABLED` запрещает выбор пункта.
- `hotkey` - ASCII-клавиша или scan-код быстрого доступа.
- `hotkey_mods` - `UI_HOTKEY_MOD_NONE`, `UI_HOTKEY_MOD_ALT`, `UI_HOTKEY_USE_SCAN`, `UI_HOTKEY_NO_MNEMONIC`.
- `label_ptr` - ASCIIZ-строка; `&` явно задает подсвеченную букву. Если `&` нет, renderer подсветит первый символ, совпадающий с `hotkey`.
- `popup_ptr` - таблица пунктов dropdown, `0` если popup нет.
- `popup_width` - ширина dropdown вместе с рамкой.
- `hint_ptr` - ASCIIZ-подсказка для status line, `0` если не нужна.

Структура `Popup item`: `flags, hotkey, hotkey_mods, command, label_ptr, hint_ptr`.

- `flags` - `UI_FLAG_SEPARATOR` рисует разделитель, `UI_FLAG_DISABLED` делает пункт неактивным.
- `hotkey` - ASCII-клавиша или scan-код внутри открытого dropdown.
- `hotkey_mods` - модификаторы/флаги shortcut. Для `Alt+X`: `hotkey="x"`, `hotkey_mods=UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC`. Для `F3`: `hotkey=UI_SCAN_F3`, `hotkey_mods=UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC`. `UI_SCAN_F*` использует DSS/TASM-style scan-коды (`F3 = #3D`), а не raw AT scancode.
- `command` - байт команды, который вернет `ui_menu_bar_run`.
- `label_ptr` - ASCIIZ-строка с опциональным `&` для явной позиции mnemonic. Если нужен shortcut без подсветки буквы (`F3`, `Alt+X`), не ставьте `&` и используйте `UI_HOTKEY_NO_MNEMONIC`.
- `hint_ptr` - ASCIIZ-подсказка для status line.

Цвета горизонтального и вертикального фокуса разделены в теме: `UI_THEME_MENU_BAR_FOCUS` и `UI_THEME_MENU_POPUP_FOCUS`. Disabled-пункты меню используют `UI_THEME_MENU_DISABLED`.

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

`TextField` хранит редактируемый текст в ASCIIZ-буфере приложения. Дескриптор и буфер должны быть в RAM. `UI_FLAG_PASSWORD` маскирует отображение символами `*`. Активное поле мигает знакоместом курсора, сохраняя символ под ним. `width` задает видимую ширину; `max_len` может быть больше, тогда поле горизонтально скроллится, чтобы курсор оставался видимым.

```asm
text_example:
        db      5, 6, 12, UI_FLAG_PASSWORD, "n"
        dw      text_buffer
        db      24, 0, 0            ; max_len, cursor, scroll
text_buffer:
        db      "demo", 0
        ds      21, 0

        ld      ix, window_desc
        ld      iy, text_example
        call    ui_draw_text_field
```

Формат: `x, y, width, flags, hotkey, buffer_ptr, max_len, cursor, scroll`.

## ItemSelector

`ItemSelector` хранит выбранный индекс в descriptor и показывает строку из таблицы ASCIIZ-указателей. Это компактный selector без выпадающего popup, рисуется с боковыми маркерами `<` и `>`. `Space`, `Enter`, hotkey или mouse click переключают следующий пункт по кругу, `Left` переключает в обратную сторону, `Right` - вперед.

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

`ComboBox` использует такую же таблицу строк, но открывает выпадающий список с отдельной рамкой и фоном. `Space`, `Enter`, hotkey или mouse click открывают popup. Правая dropdown-кнопка занимает 3 знакоместа внутри общей ширины виджета и рисуется как `[↓]`, поэтому текстовая область равна `width - 3`. Внутри popup работают `Up`/`Down`/`Home`/`End`, `Enter` или click выбирает пункт, `Esc` или click вне popup отменяет выбор. Если элементов больше высоты popup, правая колонка показывает scrollbar со стрелками вверх/вниз, фактурным track и thumb; click по стрелкам листает на один пункт.

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

## Window Background Save/Restore

По умолчанию окна ничего не сохраняют: приложение само перерисовывает фон после закрытия. Если перед сборкой определить `DEFINE UI_USE_DSS_WINDOW_BUFFER 1`, `ui_init` выделит одну DSS-страницу, а `ui_shutdown` освободит ее. `ui_dialog_run` автоматически сохраняет область диалога вместе с тенью перед выводом и восстанавливает ее при выходе.

Для прямого использования окна доступны `ui_window_save_under` и `ui_window_restore_under`. `IX` должен указывать на window descriptor при сохранении; восстановление работает как LIFO: последним закрывается последнее сохраненное окно. По умолчанию стек хранит до `UI_WINDOW_SAVE_DEPTH=4` областей в одной DSS-странице; глубину можно переопределить до подключения `window.asm`. Если суммарный размер сохраненных областей превышает 16 КБ, `ui_window_save_under` вернет `CF=1`, и приложение должно перерисовать фон самостоятельно.

## Dialog Navigation

`ui_dialog_run` поддерживает фокус для `TextField`, `CheckBox`, `RadioButton`, `ItemSelector`, `ComboBox` и `Button`. Порядок обхода: text field table, checkbox table, radio table, item selector table, combo box table, button table.

- `Tab` переводит фокус вперед.
- `Shift+Tab` или `Alt+Tab` переводит фокус назад.
- Печатные клавиши редактируют активное текстовое поле. `Backspace` удаляет символ перед курсором, `Delete` удаляет символ под курсором, `Left`/`Right`/`Home`/`End` двигают курсор.
- `Space` вводит пробел в активное текстовое поле или активирует другой элемент. `Enter` активирует текущий элемент. Для `ItemSelector` активация выбирает следующий пункт; для `ComboBox` открывает popup.
- Hotkey из descriptor активирует элемент напрямую.
- Мышь переводит фокус на элемент под курсором и активирует его. Для `TextField` click также переносит курсор в выбранное знакоместо с ограничением по текущей длине текста.
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
