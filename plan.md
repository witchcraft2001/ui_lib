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

- Публичный API строить вокруг контекста `ui_context`, descriptor tables и единых событий: key, combo key, mouse, command, message.
- Виджеты разделить на независимые модули: core, draw, input, focus, menu, dialog, button, text_field, checkbox, radio_button, combobox, group_box, separator, status_hint.
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
  - Статус: начаты `ui_init`, `ui_shutdown`, `ui_poll_event`, DSS keyboard polling и BIOS mouse polling; полная документация contract еще не готова.

- [ ] Этап 3. Отрисовка и тема Borland Pascal 7
  - Реализовать draw primitives: char/attr write, fill rect, frame, shadow, invert range, hotkey highlight.
  - Добавить стандартную палитру BP7-style и возможность пользовательской палитры.
  - Добавить separator: горизонтальная линия для меню и диалогов.

- [ ] Этап 4. Focus, events и подсказки
  - Реализовать Tab/Shift+Tab, arrows, Enter, Esc, F10, Alt/hotkeys, mouse click/release.
  - Добавить disabled/hidden/focused/pressed states.
  - Реализовать status hint line в нижней строке, опционально отключаемую.

- [ ] Этап 5. Базовые виджеты
  - Реализовать `Button`, `TextField` с password mask, `CheckBox`, `RadioButton`, `GroupBox`.
  - Для каждого виджета сделать draw/event module, descriptor format, command output и demo case.

- [ ] Этап 6. Menu и item selector
  - Реализовать menu bar с dropdown-окнами, hotkeys, mouse support, separators и optional hints.
  - Реализовать `ComboBox`/item selector на базе универсального list popup.
  - Проверить UX на уровне `fm`/`TASM`: навигация клавиатурой, мышью, закрытие по Esc/клику вне меню.

- [ ] Этап 7. Dialog/window manager
  - Реализовать окна и модальные диалоги с таблицами виджетов.
  - Добавить optional background save/restore через DSS page memory и fallback mode без сохранения.
  - Документировать требования к буферу, размер окна, вложенные окна и ошибки allocation.

- [ ] Этап 8. Документация и примеры
  - Написать docs на русском и английском: API, descriptors, memory model, examples, integration guide.
  - Добавить demo-приложение, показывающее меню, подсказки, диалог, все базовые виджеты и mouse/hotkeys.
  - Добавить minimal-link examples: only button, only dialog, only menu.

- [ ] Этап 9. Оптимизация и приемка
  - Измерить размер кода и RAM по модулям, убрать лишние зависимости.
  - Проверить сборку demo после каждой итерации и подготовку disk image.
  - Сравнить поведение с `fformat`, `fm`, `TASM`; закрыть UX gaps перед первой версией API.
