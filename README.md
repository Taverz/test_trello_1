# KPI-DRIVE · Канбан-доска

Тестовое задание на Flutter (web). Канбан-доска с задачами из API
KPI-DRIVE, drag-and-drop между колонками с сохранением на сервер.

## Стек

- **Flutter Web**
- **appflowy_board** — UI канбан-доски с drag-and-drop
- **dio** — HTTP-клиент с поддержкой повторяющихся ключей в FormData
- **provider** — DI и подписка на ChangeNotifier
- **equatable** — корректное сравнение моделей
- **shelf + shelf_proxy** — локальный CORS-прокси (только dev)
