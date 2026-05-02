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
- Виджеты разделить на независимые модули: core, draw, input, focus, menu, dialog, button, text_field, checkbox, radio_button, item_selector, combobox, group_box, separator, status_hint.
- Каждый модуль должен иметь отдельный `.asm` и `.inc`; подключение одного виджета не должно тянуть остальные.
- Описатели виджетов должны быть relocatable: координаты относительны окну, адреса буферов задает пользователь, callbacks/commands задаются через таблицу.
- Сохранение фона под окнами сделать опциональным: либо DSS page buffer через `ui_init`/`ui_shutdown`, либо пользовательский repaint без выделения памяти.

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
  - Статус: реализованы базовые char/attr write, fill rect, window frame, window/button shadow, hotkey highlight, `GroupBox`, `Separator`, цвета `TextField` и настраиваемая global theme; invert range еще не готов.

- [ ] Этап 4. Focus, events и подсказки
  - Реализовать Tab/Shift+Tab, arrows, Enter, Esc, F10, Alt/hotkeys, mouse click/release.
  - Добавить disabled/hidden/focused/pressed states.
  - Реализовать status hint line в нижней строке, опционально отключаемую.
  - Статус: реализована базовая dialog-навигация `Tab`, `Shift+Tab`/`Alt+Tab`, `Space`, `Enter`, `Esc`, hotkeys и mouse click для `Button`, `CheckBox`, `RadioButton`; `Left`/`Right`/`Home`/`End` и `Delete` работают для `TextField`; добавлен optional `UI_ENABLE_HINTS` status hint line с таблицей подсказок по focus index. F10 и menu hints еще не готовы.

- [ ] Этап 5. Базовые виджеты
  - Реализовать `Button`, `TextField` с password mask, `CheckBox`, `RadioButton`, `GroupBox`.
  - Для каждого виджета сделать draw/event module, descriptor format, command output и demo case.
  - Статус: реализованы `Button`, draw-only `GroupBox`, dialog-integrated `CheckBox`, `RadioButton`, базовый `TextField` с RAM-буфером, password-mask flag, hotkey-фокусом, mouse focus, мигающим курсором, вводом, Backspace/Delete и Left/Right/Home/End; добавлен `ItemSelector` без dropdown popup, с фокусом, hotkey, mouse click, циклическим выбором и обратным переключением через `Left`. Text selection/scrolling еще не готовы.

- [ ] Этап 6. Menu и ComboBox/dropdown
  - Реализовать menu bar с dropdown-окнами, hotkeys, mouse support, separators и optional hints.
  - Реализовать полноценный `ComboBox` на базе универсального list popup.
  - Проверить UX на уровне `fm`/`TASM`: навигация клавиатурой, мышью, закрытие по Esc/клику вне меню.
  - Статус: компактный `ItemSelector` выделен отдельно; добавлен первый настоящий `ComboBox` с framed dropdown popup, mouse/key выбором, `Up`/`Down`/`Home`/`End`, `Enter` commit, `Esc` cancel и scroll marker для длинных списков; начат `MenuBar` с descriptor tables, hotkey labels, separator/disabled descriptors, per-item hints, draw/dropdown primitives и отдельным `ui_menu_bar_run`: верхнее меню и dropdown разделены как `CurMenu`/`CurMBox` в TASM/FM, popup скрыт по умолчанию, `Enter` открывает, `Esc` закрывает. Цвета фокуса horizontal/dropdown menu разделены в теме; menu hotkey рисует только цвет символа поверх текущего фона; descriptor поддерживает ASCII shortcuts, глобальный поиск dropdown accelerators, `Alt+key`, DSS/TASM scan-code shortcuts вроде `F3` и режим без видимой mnemonic-подсветки. Универсальный list popup API и интеграция MenuBar в общий app/dialog dispatcher еще не готовы.

- [ ] Этап 7. Dialog/window manager
  - Реализовать окна и модальные диалоги с таблицами виджетов.
  - Добавить optional background save/restore через DSS page memory и fallback mode без сохранения.
  - Документировать требования к буферу, размер окна, вложенные окна и ошибки allocation.
  - Статус: добавлен optional save/restore API `ui_window_save_under`/`ui_window_restore_under` через DSS `WinCopy`/`WinRest` и страницу, выделяемую `ui_init` при `UI_USE_DSS_WINDOW_BUFFER=1`; `ui_dialog_run` автоматически сохраняет и восстанавливает область диалога с тенью. Сейчас буфер одинарный, вложенные окна требуют восстановления перед сохранением следующего окна или пользовательского repaint.

- [ ] Этап 8. Документация и примеры
  - Написать docs на русском и английском: API, descriptors, memory model, examples, integration guide.
  - Добавить demo-приложение, показывающее меню, подсказки, диалог, все базовые виджеты и mouse/hotkeys.
  - Добавить minimal-link examples: only button, only dialog, only menu.

- [ ] Этап 9. Оптимизация и приемка
  - Измерить размер кода и RAM по модулям, убрать лишние зависимости.
  - Проверить сборку demo после каждой итерации и подготовку disk image.
  - Сравнить поведение с `fformat`, `fm`, `TASM`; закрыть UX gaps перед первой версией API.
