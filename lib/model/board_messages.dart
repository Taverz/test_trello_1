/// Все пользовательские сообщения собраны в одном месте — упрощает
/// локализацию и единообразие текстов.
abstract final class BoardMessages {
  // Состояния операций
  static const operationInProgress = 'Подождите завершения предыдущей операции';

  // Ошибки логики
  static const taskNotFound = 'Задача не найдена';
  static const columnNotFound = 'Колонка не найдена';
  static const saveFailed = 'Не удалось сохранить изменения';

  // Ошибки загрузки
  static const loadFailedFallback = 'Не удалось загрузить данные';
  static const unknownError = 'Неизвестная ошибка';
}
