import '../../data/models/chat_request.dart';

/// Базовый абстрактный класс для всех AI-провайдеров.
///
/// Определяет общий интерфейс для работы с различными AI API.
/// Позволяет использовать паттерн Strategy для переключения между провайдерами.
abstract class AIProvider {
  /// Уникальный идентификатор провайдера.
  String get providerId;

  /// Отображаемое название провайдера для UI.
  String get displayName;

  /// Базовый URL API.
  String get baseUrl;

  /// Endpoint для отправки сообщений чата.
  String get chatEndpoint;

  /// Endpoint для получения списка моделей (опционально).
  String? get modelsEndpoint;

  /// Модель по умолчанию для этого провайдера.
  String get defaultModel;

  /// Примеры названий моделей для автозаполнения в UI.
  List<String> get modelExamples;

  /// Строит заголовки HTTP-запроса с авторизацией.
  ///
  /// Параметр [apiKey] - API ключ для авторизации.
  /// Возвращает карту заголовков для HTTP-запроса.
  Map<String, String> buildHeaders(String apiKey);

  /// Проверяет валидность API ключа для этого провайдера.
  ///
  /// Параметр [apiKey] - API ключ для проверки.
  /// Возвращает true, если ключ валиден, иначе false.
  bool isValidApiKey(String apiKey);

  /// Форматирует запрос к API провайдера.
  ///
  /// Параметр [request] - исходный запрос чата.
  /// Возвращает карту параметров для отправки в API.
  Map<String, dynamic> formatRequest(ChatRequest request);
}
