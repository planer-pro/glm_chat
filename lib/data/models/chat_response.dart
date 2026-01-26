/// Модель ответа от GLM API
class ChatResponse {
  /// Уникальный идентификатор ответа
  final String id;

  /// Содержимое ответа ассистента
  final String content;

  /// Причина завершения (stop, length, error)
  final String? finishReason;

  /// Количество использованных токенов
  final int? usageTokens;

  ChatResponse({
    required this.id,
    required this.content,
    this.finishReason,
    this.usageTokens,
  });

  /// Парсинг JSON ответа от API
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Пустой ответ от API');
    }

    final firstChoice = choices[0] as Map<String, dynamic>;
    final message = firstChoice['message'] as Map<String, dynamic>?;

    if (message == null) {
      throw Exception('Не найдено сообщение в ответе API');
    }

    return ChatResponse(
      id: json['id'] as String? ?? '',
      content: message['content'] as String? ?? '',
      finishReason: firstChoice['finish_reason'] as String?,
      usageTokens: json['usage']?['total_tokens'] as int?,
    );
  }

  /// Создание копии с изменёнными полями
  ChatResponse copyWith({
    String? id,
    String? content,
    String? finishReason,
    int? usageTokens,
  }) {
    return ChatResponse(
      id: id ?? this.id,
      content: content ?? this.content,
      finishReason: finishReason ?? this.finishReason,
      usageTokens: usageTokens ?? this.usageTokens,
    );
  }
}
