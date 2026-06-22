# План разработки UI библиотеки для Sprinter Peters Plus

## Цель

Разработать компактную универсальную UI библиотеку на Z80 ASM для текстового режима Sprinter Peters Plus 80x32. Библиотека должна выглядеть и работать в стиле Borland Pascal 7 под MS-DOS: верхнее меню, модальные диалоги, рамки, горячие клавиши, подсказки в нижней строке, визуальный фокус, нажатие кнопок, отключенные состояния и управление мышью.

Код не должен требовать фиксированного адреса размещения. Целевая программа решает сама: подключать библиотеку inline, собирать ее под отдельный адрес или вызывать из отдельной страницы памяти. Все требования к памяти, страницам DSS, стеку, буферам и clobber-регистрам должны быть явно описаны.

## Выводы из анализа reference-проектов

- `fformat`: взять компактную dialog/event модель, таблицы объектов, обработку `Button`, `InputLine`, `Radio`, `CheckBox`, `ListBox`, фокус через перестановку/маркировку объекта и save/restore области окна.
- `fm`: взять более развитые и читаемые реализации `HMENU`, `UMENU`, `DIALOG`, `BUTTON`, `INLINE`, `LISTBOX`, палитры, тени, разделители, обработку мыши и hotkey-метку `&`.
- `TASM`: взять UX-паттерны menu bar, status line с контекстными подсказками, диалоговые описатели, клавиатурную навигацию и mouse driver для текстового режима.
- `texteditor`: использовать как дополнительный простой reference для псевдографического UI, окон, меню и печати через `Dss.WrChar`, `Dss.Clear`, `Bios.Lp_Print_Ln`; важный вывод: исполняемый код demo лучше размещать ниже `#8000`, как `#4180`, чтобы не конфликтовать с переключаемым окном памяти `#8000-#BFFF`.
- `sprinter_ai_doc/manual`: использовать как основной источник документации и include-файлов с константами DSS/BIOS; зафиксировать `GETMEM #3D`, `FREEMEM #3E`, `SETWIN #38/#39/#3A/#3B`, `WINCOPY #59`, `WINREST #5A`, `SCANKEY #31`, mouse API через `RST #30`, экранный формат `char, attr`.
- `sprinter_dss`/`sprinter_bios`: использовать как вторичный источник для сверки с оригинальными реализациями, портами, EXE/memory model и ограничениями DSS.

## Архитектурные решения

- Публичный API строить вокруг контекста `ui_context`, descriptor tables и единых событий: key, hotkey, mouse, command, message.
- Виджеты разделить на независимые модули: core, draw, input, focus, menu, dialog, button, text_field, checkbox, radio_button, item_selector, list_box, combobox, progress_bar, group_box, separator, status_hint.
- Каждый модуль должен иметь отдельный `.asm` и `.inc`; подключение одного виджета не должно тянуть остальные.
- Описатели виджетов должны быть relocatable: координаты относительны окну, адреса буферов задает пользователь, callbacks/commands задаются через таблицу.
- Сохранение фона под окнами сделать опциональным: либо DSS page buffer через `ui_init`/`ui_shutdown`, либо пользовательский repaint без выделения памяти.
- Для экономии размера использовать модульное подключение и, где sjasmplus это позволяет, условную сборку процедур через `IFUSED`/аналогичные guards: редко используемые helper-процедуры не должны попадать в целевой EXE без вызовов.

## Этапы

- [x] Этап 0. Первичный анализ исходников и документации
  - Изучены UI-related модули в `TASM`, `fformat`, `fm`, DSS/BIOS/manual.
  - Зафиксированы источники для адаптации и ключевые требования к API, UX, памяти и сборке.

- [x] Этап 1. Каркас репозитория и сборки
  - Создать `src/`, `include/`, `examples/`, `docs/ru/`, `docs/en/`, `tools/` или `run/`.
  - Добавить `sjasmplus` build scripts, listing output, demo build и disk image script по образцу `/Users/dmitry/dev/zx/sprinter/kode/run`.
  - Подготовить минимальный demo EXE и образ диска.

- [ ] Этап 2. Core API и системный слой
  - Реализовать `ui_init`, `ui_shutdown`, `ui_poll_event`, `ui_dispatch`, `ui_set_theme`, `ui_set_context_hint`.
  - Описать register contract, memory contract, compile-time options и модель подключения inline/page-call.
  - Сделать адаптеры DSS/BIOS: keyboard, mouse, window copy/restore, page allocation.
  - Статус: начаты `ui_init`, `ui_shutdown`, `ui_poll_event`, DSS keyboard polling, BIOS mouse polling и runtime theme API `ui_set_theme`; полная документация contract еще не готова.

- [ ] Этап 3. Отрисовка и тема Borland Pascal 7
  - Реализовать draw primitives: char/attr write, fill rect, frame, shadow, invert range, hotkey highlight.
  - Добавить стандартную палитру BP7-style и возможность пользовательской палитры.
  - Добавить separator: горизонтальная линия для меню и диалогов.
  - Добавить frame style в descriptor/theme: double frame для BP/TASM style, single frame для dropdown/dialog/list popup, без дублирования кода отрисовки.
  - Улучшить `Separator`: режим full-width от внутреннего края до внутреннего края окна и стыковка с рамкой через специальные junction-символы псевдографики, чтобы разделитель визуально сливался с рамкой.
  - Статус: реализованы базовые char/attr write, fill rect, window frame, window/button shadow, hotkey highlight, `GroupBox`, `Separator`, `ui_print_wrapped_z` с ограничением ширины/строк и принудительным `0Ah` newline, `ui_invert_range` для однострочной инверсии атрибутов, цвета `TextField` и настраиваемая global theme. `Separator` поддерживает режим `width=0` для линии от рамки до рамки с junction-символами. Single/double frame style еще не готов.

- [ ] Этап 4. Focus, events и подсказки
  - Реализовать Tab/Shift+Tab, arrows, Enter, Esc, F10, Alt/hotkeys, mouse click/release.
  - Добавить disabled/hidden/focused/pressed states.
  - Реализовать status hint line в нижней строке, опционально отключаемую.
  - Статус: реализована базовая dialog-навигация `Tab`, `Shift+Tab`/`Alt+Tab`, `Space`, `Enter`, `Esc`, hotkeys и mouse click для `Button`, `CheckBox`, `RadioButton`; `Left`/`Right`/`Home`/`End` и `Delete` работают для `TextField`; добавлен optional `UI_ENABLE_HINTS` status hint line с таблицей подсказок по focus index; `F10` открывает/закрывает dropdown в `MenuBar`. Общий app-level dispatcher для вызова меню из любого состояния еще не готов.

- [ ] Этап 5. Базовые виджеты
  - Реализовать `Button`, `TextField` с password mask, `CheckBox`, `RadioButton`, `GroupBox`.
  - Добавить `ProgressBar`: determinate mode с заданным value/max и indeterminate/busy mode для бесконечного прогресса, с отдельными theme attributes.
  - Добавить `ListBox`/`ItemList` как scrollable selector по аналогии с TASM color/dialog lists: fixed viewport, scrollbar, selected row, disabled rows, mouse/key navigation, command on Enter/double click. Существующий `ItemSelector` оставить компактным inline-переключателем значений (`< value >`) без popup.
  - Для каждого виджета сделать draw/event module, descriptor format, command output и demo case.
  - Статус: реализованы `Button`, draw-only `GroupBox`, dialog-integrated `CheckBox`, `RadioButton`, базовый `TextField` с RAM-буфером, password-mask flag, hotkey-фокусом, mouse focus, мигающим курсором, вводом, Backspace/Delete, Left/Right/Home/End и descriptor-owned горизонтальным скроллингом при `max_len > width`; добавлен `ItemSelector` без dropdown popup, с фокусом, hotkey, mouse click, циклическим выбором и обратным переключением через `Left`; добавлен draw-only `ProgressBar` с determinate и indeterminate режимами. TASM-style scrollable `ListBox`/`ItemList` еще не готов.

- [ ] Этап 6. Menu и ComboBox/dropdown
  - Реализовать menu bar с dropdown-окнами, hotkeys, mouse support, separators и optional hints.
  - Реализовать полноценный `ComboBox` на базе универсального list popup.
  - Вынести общий scrollable list popup/list viewport API, чтобы `ComboBox`, dropdown menu и будущий `ListBox` переиспользовали одну навигацию, scrollbar, partial redraw и DSS scroll/copy primitives.
  - Проверить UX на уровне `fm`/`TASM`: навигация клавиатурой, мышью, закрытие по Esc/клику вне меню.
  - Статус: компактный `ItemSelector` выделен отдельно; добавлен первый настоящий `ComboBox` с framed dropdown popup, mouse/key выбором, `Up`/`Down`/`Home`/`End`, `Enter` commit и `Esc` cancel. ComboBox обновляет только изменившиеся строки при перемещении фокуса внутри видимой области, а при прокрутке на одну строку использует `Dss.Scroll #55` через `ui_call_dss` для внутренней области dropdown и дорисовывает только новую строку; для длинных списков добавлен scrollbar со стрелками, patterned track, thumb и mouse-scroll по стрелкам. Начат `MenuBar` с descriptor tables, hotkey labels, separator/disabled descriptors, per-item hints, draw/dropdown primitives и отдельным `ui_menu_bar_run`: верхнее меню и dropdown разделены как `CurMenu`/`CurMBox` в TASM/FM, popup скрыт по умолчанию, `Enter`/`F10` открывают dropdown, `F10`/`Esc` закрывают. Цвета фокуса horizontal/dropdown menu разделены в теме; menu hotkey рисует только цвет символа поверх текущего фона; descriptor поддерживает ASCII shortcuts, глобальный поиск dropdown accelerators, `Alt+key`, DSS/TASM scan-code shortcuts вроде `F3` и режим без видимой mnemonic-подсветки. Универсальный list popup API и интеграция MenuBar в общий app/dialog dispatcher еще не готовы.

- [x] Этап 7. Dialog/window manager
  - Реализовать окна и модальные диалоги с таблицами виджетов.
  - Добавить optional background save/restore через DSS page memory и fallback mode без сохранения.
  - Документировать требования к буферу, размер окна, вложенные окна и ошибки allocation.
  - Статус: закрыт. Добавлен optional save/restore API `ui_window_save_under`/`ui_window_restore_under` через DSS `WinCopy`/`WinRest` и страницу, выделяемую `ui_init` при `UI_USE_DSS_WINDOW_BUFFER=1`; `ui_dialog_run` автоматически сохраняет и восстанавливает область диалога с тенью. Буфер работает как LIFO-стек в одной DSS-странице (`UI_WINDOW_SAVE_DEPTH`, по умолчанию 4) и возвращает `CF=1`, если глубина или суммарный размер сохраненных областей превышены.

- [ ] Этап 8. Документация и примеры
  - Написать docs на русском и английском: API, descriptors, memory model, examples, integration guide.
  - Добавить demo-приложение, показывающее меню, подсказки, диалог, все базовые виджеты и mouse/hotkeys.
  - Добавить minimal-link examples: only button, only dialog, only menu.
  - Статус: добавлены `examples/button_only/button_only.asm`, `examples/menu_only/menu_only.asm` и `run/make_examples.sh`; button-only подключает только core/theme/events, draw/text, window, button и button_events, а menu-only подключает только core/theme/events/hint, draw/text и menu_bar, чтобы проверить модульное подключение без остальных виджетов. `run/make.sh` собирает примеры вместе с основным demo, а дефолтный `run/create_floppy_image.sh` кладет в `build/demo/ui_demo.img` три файла: `UI_DEMO.EXE`, `BUTTON.EXE` и `MENU.EXE`.

- [ ] Этап 9. Оптимизация и приемка
  - Измерить размер кода и RAM по модулям, убрать лишние зависимости.
  - Проверить поддержку `IFUSED`/условной сборки sjasmplus и обернуть редко используемые helper routines так, чтобы неиспользуемые процедуры не попадали в EXE.
  - Проверить сборку demo после каждой итерации и подготовку disk image.
  - Сравнить поведение с `fformat`, `fm`, `TASM`; закрыть UX gaps перед первой версией API.

- [ ] Этап 10. Недостающие TUI-примитивы (полноценный TUI уровня Turbo Vision)

  Критичные (фундамент для прокручиваемого контента и редакторов):
  - [x] `ScrollBar` как самостоятельный виджет (`src/widgets/scrollbar.asm`): стрелки + track + thumb, расчёт позиции thumb, mouse hit-test (up/down/track). Осталось: горизонтальный режим и jump-on-track-click.
  - [x] `ListBox`/`ItemList` (`src/widgets/list_box.asm`) на базе `ScrollBar`: клавиатура (Up/Down/Home/End/PgUp/PgDn), мышь, partial redraw + DSS-scroll, бесшовный `ui_list_box_loop`. Осталось: disabled rows, double-click-commit, интеграция в табличный `ui_dialog_run`.
  - [ ] `Memo`/многострочный редактор: multi-line edit с переносом, курсором по строкам и вертикальным скроллом (расширение `TextField`).
  - [x] `MessageBox`/`InputBox`: готовые модальные хелперы. `ui_message_box` — перенос текста по словам, авто-размер/центрирование, заголовок, выбор цвета фона, наборы кнопок (OK / OKCancel / YesNo / YesNoCancel / AbortRetryIgnore). `ui_input_box` — запрос строки: prompt + однострочное `TextField` + OK/Cancel, фокус между полем и кнопками, мигающий курсор, возврат строки в буфер вызывающего.

  Важные (оконный менеджер и навигация):
  - [ ] `TextView`: read-only прокручиваемый просмотр текста (viewport поверх `ui_print_wrapped_z`).
  - [ ] Подвижные/перекрывающиеся окна: drag, resize, close-кнопка в заголовке, Z-order поверх текущего LIFO save/restore.
  - [ ] Контекстное (popup) меню в произвольной точке, вложенные подменю, checkable/radio пункты.
  - [ ] File open/save dialog: `ListBox` + чтение каталога через DSS `F_First`/`F_Next`.

  Полезные:
  - [ ] `Spin`/numeric input (поле с ↑/↓), маска/валидация ввода в `TextField`.
  - [ ] Полноценный `StatusBar` с несколькими кликабельными полями (сейчас одна `hint`-строка).
  - [ ] `TabControl`/Notebook (вкладки-страницы), `Splitter` (панели), multi-select/checklist.
  - [ ] Обобщённые `ui_draw_hline`/`vline`/`box` с выбором глифа (унификация через `ui_window_load_frame_glyphs`).

  Порядок реализации (актуальный, по зависимостям и ROI):
  1. [сделано] ScrollBar → ListBox → MessageBox → InputBox.
  2. [сделано] `TextView` (`src/widgets/text_view.asm`): read-only прокручиваемый просмотр, word-wrap + постоянный ScrollBar, DSS-scroll для Up/Down, redraw-in-place для PgUp/PgDn/Home/End.
  3. Обобщённые `ui_draw_hline`/`vline`/`box` (рефакторинг рамок window/group_box/list_box/textview).
  4. File open/save dialog (`ListBox` + DSS `F_First`/`F_Next` + `InputBox`).
  5. Интеграция `ListBox` в табличный `ui_dialog_run`.
  6. `Memo`/многострочный редактор.
  7. Подвижные окна (drag/resize/close/Z-order) / контекстное меню / `TabControl`.
