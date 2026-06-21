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

## Window

`ui_draw_window` рисует статичное окно: черную тень, заливку тела серым, внешнюю рамку и опциональный заголовок. `IX` указывает на дескриптор окна:

- `+0` x, `+1` y, `+2` ширина, `+3` высота в знакоместах (`UI_WINDOW_X/Y/W/H`);
- `+4` слово заголовка (`UI_WINDOW_TITLE`): указатель на ASCIIZ-строку или `0`, если заголовка нет;
- `+6` тип рамки (`UI_WINDOW_FRAME`): `UI_FRAME_DOUBLE` (`0`, двойная рамка) или `UI_FRAME_SINGLE` (`1`, одинарная рамка).

`UI_WINDOW_SIZE` - длина дескриптора (7 байт). Байт рамки обязателен: `ui_draw_window` и `ui_draw_window_frame` всегда читают `+6`, поэтому его должен содержать каждый дескриптор. `UI_FRAME_DOUBLE` - двойная внешняя рамка по умолчанию из style guide.

```asm
        ld      ix, window_desc
        call    ui_draw_window
; ...
window_desc:
        db      15, 4, 50, 20
        dw      window_title
        db      UI_FRAME_DOUBLE
```

`ui_draw_window_shadow` и `ui_draw_window_frame` можно вызывать отдельно; `ui_draw_window_frame` выбирает набор символов рамки по типу из дескриптора. Тень рисуется через `ui_shade_rect`, который перекрашивает покрываемые ячейки в `UI_THEME_SHADOW` (чёрный фон, приглушённый текст), **сохраняя символ каждой ячейки** — как в TurboVision/TASM, где узор десктопа просвечивает сквозь тень приглушённым, а не затирается пустыми ячейками.

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
- `hotkey_mods` - `UI_HOTKEY_MOD_NONE`, `UI_HOTKEY_MOD_ALT`, `UI_HOTKEY_MOD_CTRL`, `UI_HOTKEY_USE_SCAN`, `UI_HOTKEY_NO_MNEMONIC`.
- `label_ptr` - ASCIIZ-строка; `&` явно задает подсвеченную букву. Если `&` нет, renderer подсветит первый символ, совпадающий с `hotkey`.
- `popup_ptr` - таблица пунктов dropdown, `0` если popup нет.
- `popup_width` - ширина dropdown вместе с рамкой.
- `hint_ptr` - ASCIIZ-подсказка для status line, `0` если не нужна.

Структура `Popup item`: `flags, hotkey, hotkey_mods, command, label_ptr, hint_ptr`.

- `flags` - `UI_FLAG_SEPARATOR` рисует разделитель, `UI_FLAG_DISABLED` делает пункт неактивным.
- `hotkey` - ASCII-клавиша или scan-код внутри открытого dropdown.
- `hotkey_mods` - модификаторы/флаги shortcut. Для `Alt+X`: `hotkey="x"`, `hotkey_mods=UI_HOTKEY_MOD_ALT | UI_HOTKEY_NO_MNEMONIC`. Для `Ctrl+P`: `hotkey="p"`, `hotkey_mods=UI_HOTKEY_MOD_CTRL` (подсветка буквы продолжает работать, поэтому `UI_HOTKEY_NO_MNEMONIC` необязателен). Для `F3`: `hotkey=UI_SCAN_F3`, `hotkey_mods=UI_HOTKEY_USE_SCAN | UI_HOTKEY_NO_MNEMONIC`. `UI_SCAN_F*` использует DSS/TASM-style scan-коды (`F3 = #3D`), а не raw AT scancode.
- `command` - байт команды, который вернет `ui_menu_bar_run`.
- `label_ptr` - ASCIIZ-строка с опциональным `&` для явной позиции mnemonic. Если нужен shortcut без подсветки буквы (`F3`, `Alt+X`), не ставьте `&` и используйте `UI_HOTKEY_NO_MNEMONIC`.
- `hint_ptr` - ASCIIZ-подсказка для status line.

Цвета горизонтального и вертикального фокуса разделены в теме: `UI_THEME_MENU_BAR_FOCUS` и `UI_THEME_MENU_POPUP_FOCUS`. Disabled-пункты меню используют `UI_THEME_MENU_DISABLED`.

Если перед сборкой определить `DEFINE UI_USE_DSS_WINDOW_BUFFER 1` (и подключить `window.asm`), `MenuBar` сохраняет фон под каждым dropdown перед отрисовкой и восстанавливает его при закрытии, поэтому переход между пунктами верхнего меню не оставляет следов без перерисовки со стороны приложения. Без буфера поведение прежнее (область dropdown очищается при закрытии, приложение перерисовывает само).

### Модификаторы клавиатуры

`ui_poll_event` сохраняет состояние shift'ов из DSS `ScanKey` (регистр `B`) как есть в `ui_event_mods`. Раскладка бит (по DSS-мануалу / `sprinter_dss` KEYINTER): `bit7` Left Shift, `bit6` Right Shift, `bit5` Ctrl (any), `bit4` Alt (any), `bit3` Left Ctrl, `bit2` Left Alt, `bit1` Right Ctrl, `bit0` Right Alt. Используйте маски `UI_KEYMOD_ALT_ANY` (`0x15`), `UI_KEYMOD_CTRL_ANY` (`0x2A`) и `UI_KEYMOD_SHIFT_ANY` (`0xC0`) — каждая покрывает обобщённый бит плюс оба боковых, поэтому один `AND` ловит модификатор независимо от того, какая физическая клавиша нажата.

`Ctrl+буква` важен потому, что DSS возвращает для него ASCII `0` (не сворачивает в управляющий код), и приложение не может поймать `Ctrl+S`/`Ctrl+P`/`Ctrl+K` по одному `ui_event_key`. `UI_HOTKEY_MOD_CTRL` заставляет матчер акселераторов меню сравнивать DSS scan-код, ровно как это делает `UI_HOTKEY_MOD_ALT`, поэтому `db 0, "p", UI_HOTKEY_MOD_CTRL` срабатывает на `Ctrl+P`. DSS выставляет bit7 на позиционном коде для комбинаций с модификатором, поэтому матчер маскирует его (`and 7Fh`) перед сравнением; собственная обработка скан-кодов должна делать так же.

Для собственной обработки клавиш есть `ui_event_is_ctrl`, `ui_event_is_alt` и `ui_event_is_shift`: они проверяют `ui_event_mods` и возвращают `ZF=0` (NZ), если модификатор был зажат (портится `AF`, остальные регистры сохраняются).

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

Если `width` равен `0`, разделитель рисуется на всю ширину родительского окна
и стыкуется с рамкой. В этом режиме `x` игнорируется, `y` остается относительным
координате окна.

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

## ProgressBar

`ProgressBar` работает как draw-only виджет и может подключаться без модулей dialog/menu.
Пустая часть рисуется фактурным псевдографическим символом, заполненная часть
использует `ui_theme_progress_fill`.
Determinate-режим использует `value/max`; indeterminate-режим включает
`UI_FLAG_INDETERMINATE` и хранит фазу анимации в descriptor.

```asm
progress_done:
        db      8, 7, 28, 0, 0, 10, 0
progress_busy:
        db      8, 9, 28, UI_FLAG_INDETERMINATE, 0, 0, 0

        ld      ix, window_desc
        ld      iy, progress_done
        call    ui_draw_progress_bar

        ld      iy, progress_busy
        call    ui_progress_bar_tick
        call    ui_draw_progress_bar
```

Формат: `x, y, width, flags, value, max, phase`.

## ScrollBar

`ScrollBar` (`src/widgets/scrollbar.asm`) — вертикальная полоса со стрелками вверх/вниз, фактурным track и thumb. Используется самостоятельно и как колонка внутри `ListBox`. Координаты относительны родительскому окну.

`ui_draw_scrollbar` (`IX` = окно, `IY` = дескриптор) рисует из дескриптора; `ui_draw_vscrollbar` рисует по абсолютным координатам (`D` = строка, `E` = колонка, `B` = высота), используя общие переменные `ui_scroll_total`/`ui_scroll_visible`/`ui_scroll_top`. `ui_scrollbar_hit` (`D`/`E`/`B` = прямоугольник полосы) возвращает `UI_SCROLL_HIT_NONE/UP/DOWN/TRACK` для последнего события мыши.

```asm
scrollbar_desc:
        db      40, 2, 10, 64, 8, 0   ; x, y, height, total, visible, top
        ld      ix, window_desc
        ld      iy, scrollbar_desc
        call    ui_draw_scrollbar
```

Формат: `x, y, height (>=3), total, visible, top`. Позиция thumb — `top`, отображённый на диапазон `total - visible`; при `total <= visible` thumb стоит вверху.

## ListBox

`ListBox` (`src/widgets/list_box.asm`, требует `scrollbar.asm`) — обрамлённый прокручиваемый список с одиночным выбором. В правой внутренней колонке автоматически появляется `ScrollBar`, когда `count > видимых строк`; иначе вся внутренняя ширина отдаётся под текст. Видимых строк — `height - 2` (рамка), текст пункта обрезается/дополняется до внутренней ширины.

`ui_draw_list_box` (`IX` = окно, `IY` = дескриптор) рисует список и держит `selected`/`top` в допустимых пределах. `ui_list_box_run` — модальный цикл: `Up`/`Down`/`PgUp`/`PgDn`/`Home`/`End` двигают выбор (страница — один экран строк viewport), `Enter`/`Space` подтверждают, клик мышью по строке выбирает её (клик по уже выбранной — подтверждает), клики по стрелкам scrollbar прокручивают, `Esc` отменяет. Возвращает `CF=0` и `A` = индекс выбора при подтверждении, либо `CF=1` и `A=UI_CMD_CANCEL` при `Esc`.

Перемещение выбора перерисовывает только изменившиеся строки; сдвиг viewport на одну строку использует DSS `Scroll` вместо перерисовки списка, и строки не залезают в колонку scrollbar. Чтобы это оставалось бесшовным между подтверждениями, нарисуйте список один раз через `ui_draw_list_box` и перевходите в `ui_list_box_loop` (событийный цикл без начальной отрисовки) вместо повторных вызовов `ui_list_box_run`. `ui_list_box_item` (`A` = индекс) возвращает `HL` = указатель на ASCIIZ пункта.

```asm
list_desc:
        db      4, 6, 24, 14, 0       ; x, y, width, height, flags
        dw      list_items            ; таблица указателей на пункты
        db      16, 0, 0              ; count, selected, top

        ld      ix, window_desc
        ld      iy, list_desc
        call    ui_list_box_run
        jr      c, .cancelled         ; Esc
        ; A = индекс выбора
```

Формат: `x, y, width, height, flags, items_ptr (word), count, selected, top`. `items_ptr` — таблица word-указателей на ASCIIZ-строки. `selected` и `top` обновляются на месте. Пример `list_only` (`LIST.EXE`) демонстрирует клавиатуру, мышь и прокрутку.

## MessageBox

`ui_message_box` (`src/widgets/message_box.asm`, требует `window.asm`, `button.asm`, `button_events.asm`) показывает модальный диалог-уведомление с переносом текста по словам и одной–тремя кнопками, автоматически рассчитывая размер и центрируя окно.

- `HL` = текст ASCIIZ (обязателен). Переносится по словам; окно растёт в высоту для длинного текста (до предела), а ширина тела ужимается до самой длинной строки.
- `DE` = заголовок ASCIIZ или `0`, если заголовка нет.
- `A` = набор кнопок: `UI_MSG_OK`, `UI_MSG_OKCANCEL`, `UI_MSG_YESNO`, `UI_MSG_YESNOCANCEL`, `UI_MSG_ABORTRETRYIGNORE`.
- `B` = атрибут фона тела или `0` для значения из темы (`UI_THEME_WINDOW`). Кастомный цвет тела также перекрашивает рамку и тень кнопок под тот же фон, чтобы не проступал серый по умолчанию.
- Возвращает `A` = результат: `UI_MSG_RESULT_OK/CANCEL/YES/NO/ABORT/RETRY/IGNORE`.

По умолчанию активна первая кнопка. `Tab`/`Left`/`Right` двигают фокус, `Enter`/`Space` активируют кнопку в фокусе, буква кнопки — её hotkey, клик мышью активирует, `Esc` возвращает «отменяющий» результат набора (`Cancel`, `No`, `OK` для OK-only; игнорируется для `AbortRetryIgnore`). При `UI_USE_DSS_WINDOW_BUFFER` фон под окном сохраняется и восстанавливается.

```asm
        ld      hl, message_text
        ld      de, dialog_title        ; или 0, если заголовка нет
        ld      a, UI_MSG_YESNOCANCEL
        ld      b, 0                     ; цвет тела по умолчанию
        call    ui_message_box
        cp      UI_MSG_RESULT_YES
        jr      z, .confirmed
```

Пример `msgbox` (`MSGBOX.EXE`) показывает все наборы кнопок (клавиши `1`–`5`).

## Window Background Save/Restore

По умолчанию окна ничего не сохраняют: приложение само перерисовывает фон после закрытия. Если перед сборкой определить `DEFINE UI_USE_DSS_WINDOW_BUFFER 1`, `ui_init` выделит одну DSS-страницу, а `ui_shutdown` освободит ее. `ui_dialog_run` автоматически сохраняет область диалога вместе с тенью перед выводом и восстанавливает ее при выходе.

Для прямого использования окна доступны `ui_window_save_under` и `ui_window_restore_under`. `IX` должен указывать на window descriptor при сохранении; восстановление работает как LIFO: последним закрывается последнее сохраненное окно. По умолчанию стек хранит до `UI_WINDOW_SAVE_DEPTH=4` областей в одной DSS-странице; глубину можно переопределить до подключения `window.asm`. Если суммарный размер сохраненных областей превышает 16 КБ, `ui_window_save_under` вернет `CF=1`, и приложение должно перерисовать фон самостоятельно.

## Соглашение о вызовах DSS/BIOS

Все обращения к прошивке идут через `ui_call_dss` (`src/core/init.asm`) и `ui_call_bios` (`src/draw/text.asm`). Соглашение выбирается на этапе сборки, поэтому библиотека не навязывает модель памяти. Варианты ниже — в порядке приоритета; значения по умолчанию объявлены в `include/ui_defs.inc` и сохраняют legacy-поведение, так что существующие потребители не затрагиваются.

**1. Hook приложения (максимально гибко).** Определите `UI_CALL_DSS_HOOK` и/или `UI_CALL_BIOS_HOOK` как метку собственной процедуры. Враппер превращается в один `jp` в неё, и ui_lib вообще не навязывает соглашение об окнах и стеке — пейджинг и стек на время вызова контролирует ваша процедура. Регистры и флаги проходят насквозь без изменений, и hook должен вернуть их так же, как сделал бы враппер (`C` = функция на входе, результат прошивки на выходе). Хуки независимы, поэтому можно переопределить только DSS или только BIOS.

```asm
        DEFINE UI_CALL_DSS_HOOK  my_dss
        DEFINE UI_CALL_BIOS_HOOK my_bios
        include "include/ui.inc"
; ...
my_dss:                 ; In: C=функция, ... ; Out: результат DSS и флаги
        rst     10h     ; через собственный RST-трамплин приложения
        ret
my_bios:
        rst     08h
        ret
```

**2. Plain RST.** `DEFINE UI_SYSCALL_PLAIN_RST 1` делает врапперы голым `rst 10h`/`rst 08h` плюс `ret`, без захвата окна и без временного стека. Для приложений, которые владеют WIN0 и пропускают каждый `rst 08/10/30/38` через собственные RST-трамплины (трамплин делает swap WIN0 и не трогает WIN1/WIN2/WIN3).

**3. Legacy WIN2-borrow (по умолчанию, `UI_SYSCALL_PLAIN_RST 0`).** На время вызова берётся WIN2 (`P2 := P1`) и временный стек по адресу `UI_SAFE_STACK` (по умолчанию `0x8040`), затем WIN2 восстанавливается. Соответствует коду в стиле texteditor/fformat и предполагает, что приложение живёт в WIN1, а WIN2 свободен под scratch (как в примерах из комплекта). Нужен потому, что некоторые функции DSS/BIOS перекладывают страницы в окнах прямо во время вызова, что испортило бы стек, оставленный в задетом окне. Если WIN2 `0x8000..0x8040` не свободен в вашей модели памяти, переопределите `UI_SAFE_STACK` через `DEFINE`.

Hook имеет приоритет над `UI_SYSCALL_PLAIN_RST`.

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
