import 'message.dart';

/// Модель запроса к GLM API
class ChatRequest {
  /// Название модели
  final String model;

  /// Список сообщений в диалоге
  final List<Message> messages;

  /// Температура генерации (0.0 - 1.0)
  final double temperature;

  /// Максимальное количество токенов в ответе
  final int maxTokens;

  /// Включить потоковый режим ответа
  final bool stream;

  ChatRequest({
    required this.model,
    required this.messages,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.stream = false,
  });

  /// Создание запроса с параметрами по умолчанию для GLM 4.7
  factory ChatRequest.glm47(List<Message> messages, {bool stream = false}) {
    return ChatRequest(
      model: 'glm-4.7',
      messages: messages,
      temperature: 0.7,
      maxTokens: 4096,
      stream: stream,
    );
  }

  /// Конвертация в JSON (поддерживает multimodal content)
  Future<Map<String, dynamic>> toJson() async {
    print('[ChatRequest.toJson] Начало конвертации. Сообщений: ${messages.length}');

    // Проверяем сообщения
    for (int i = 0; i < messages.length; i++) {
      print('[ChatRequest.toJson] Сообщение $i: role=${messages[i].role.name}, файлов=${messages[i].attachedFiles.length}');
    }

    // Конвертируем сообщения в JSON (асинхронно для поддержки файлов)
    final messagesJson = await Future.wait(
      messages.map((m) => m.toJson()),
    );

    print('[ChatRequest.toJson] Конвертировано ${messagesJson.length} сообщений');

    return {
      'model': model,
      'messages': messagesJson,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': stream,
    };
  }

  /// Синхронная конвертация в JSON (для обратной совместимости)
  Map<String, dynamic> toJsonSync() {
    return {
      'model': model,
      'messages': messages.map((m) => m.toJsonSync()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': stream,
    };
  }

  /// Создание копии с изменёнными полями
  ChatRequest copyWith({
    String? model,
    List<Message>? messages,
    double? temperature,
    int? maxTokens,
    bool? stream,
  }) {
    return ChatRequest(
      model: model ?? this.model,
      messages: messages ?? this.messages,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      stream: stream ?? this.stream,
    );
  }
}
