/// Импорт зависимостей
library;

import 'message.dart';
import 'package:uuid/uuid.dart';

/// Модель чат-сессии для управления историей разговоров
class ChatSession {
  /// Уникальный идентификатор сессии
  final String id;

  /// Заголовок сессии (автоматически генерируется из первого сообщения)
  final String title;

  /// Список сообщений в сессии
  final List<Message> messages;

  /// Дата и время создания сессии
  final DateTime createdAt;

  /// Дата и время последнего обновления сессии
  final DateTime updatedAt;

  ChatSession({
    String? id,
    String? title,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        title = title ?? _generateTitle(messages);

  /// Генерация заголовка из первого сообщения пользователя
  /// Если пользовательских сообщений нет, используется заголовок по умолчанию
  static String _generateTitle(List<Message> messages) {
    // Ищем первое сообщение пользователя
    final firstUserMessage =
        messages.where((m) => m.isUser).toList().firstOrNull;

    if (firstUserMessage != null && firstUserMessage.content.isNotEmpty) {
      // Обрезаем текст до 50 символов и добавляем многоточие если нужно
      final content = firstUserMessage.content.trim();
      final maxLength = 50;

      if (content.length <= maxLength) {
        return content;
      }

      // Разбиваем на слова и обрезаем до последнего полного слова
      final words = content.split(' ');
      String result = '';
      for (final word in words) {
        if ((result + word).length <= maxLength) {
          result += (result.isEmpty ? '' : ' ') + word;
        } else {
          break;
        }
      }

      return result.isEmpty ? content.substring(0, maxLength) : result + '...';
    }

    return 'Новый чат';
  }

  /// Конвертация в JSON для сохранения в хранилище
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJsonSync()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Создание сессии из JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Создание копии сессии с изменёнными полями
  ChatSession copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Создание копии с обновлённым списком сообщений и автоматически обновляемым updatedAt
  ChatSession withMessages(List<Message> newMessages) {
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Создание копии с новым заголовком (пересчитывается из первого сообщения)
  ChatSession withUpdatedTitle() {
    return copyWith(
      title: _generateTitle(messages),
    );
  }

  /// Получение превью последнего сообщения
  String get lastMessagePreview {
    if (messages.isEmpty) return 'Нет сообщений';

    final lastMessage = messages.last;
    final content = lastMessage.content.trim();

    // Обрезаем до 100 символов
    if (content.length <= 100) {
      return content;
    }

    return '${content.substring(0, 100)}...';
  }

  /// Проверка, является ли сессия пустой (нет сообщений)
  bool get isEmpty => messages.isEmpty;

  /// Количество сообщений в сессии
  int get messageCount => messages.length;

  /// Проверка, была ли сессия обновлена после создания
  bool get wasModified => updatedAt.isAfter(createdAt);
}
