/// Импорт модели прикреплённого файла
library;

import 'attached_file.dart';

import 'dart:developer' as developer;

/// Роль отправителя сообщения
enum MessageRole {
  user,
  assistant,
}

/// Модель сообщения чата
class Message {
  /// Роль отправителя
  final MessageRole role;

  /// Содержимое сообщения
  final String content;

  /// Временная метка создания
  final DateTime timestamp;

  /// Было ли сообщение отредактировано
  final bool isEdited;

  /// Уникальный идентификатор
  final String id;

  /// Список прикреплённых файлов (изображения, документы и т.д.)
  final List<AttachedFile> attachedFiles;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isEdited = false,
    String? id,
    this.attachedFiles = const [],
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Конвертация в JSON для API запроса
  /// Поддерживает multimodal content (текст + изображения + текстовые файлы)
  Future<Map<String, dynamic>> toJson() async {
    // Формируем полный текст сообщения с содержимым текстовых файлов
    String fullContent = content;

    print(
        '[Message.toJson] Начало конвертации. Файлов: ${attachedFiles.length}');

    developer.log(
        'toJson: сообщение имеет ${attachedFiles.length} прикреплённых файлов');

    // Если есть текстовые файлы, добавляем их содержимое к сообщению
    if (attachedFiles.any((f) => f.isTextFile)) {
      final textFiles = attachedFiles.where((f) => f.isTextFile).toList();
      developer.log('Найдено ${textFiles.length} текстовых файлов');
      print('[Message.toJson] Найдено ${textFiles.length} текстовых файлов');

      for (final file in textFiles) {
        developer.log(
            'Чтение файла: ${file.name}, MIME: ${file.mimeType}, isTextFile: ${file.isTextFile}');
        print(
            '[Message.toJson] Чтение файла: ${file.name}, MIME: ${file.mimeType}');
        final fileContent = await file.getTextContent();
        developer.log(
            'Файл ${file.name} прочитан, длина: ${fileContent.length} символов');
        print(
            '[Message.toJson] Файл ${file.name} прочитан, ${fileContent.length} символов');
        print(
            '[Message.toJson] Первые 100 символов: ${fileContent.substring(0, fileContent.length > 100 ? 100 : fileContent.length)}');

        fullContent +=
            '\n\n--- Файл: ${file.name} ---\n$fileContent\n--- Конец файла ---';
      }

      developer.log(
          'Итоговая длина сообщения с файлами: ${fullContent.length} символов');
      print('[Message.toJson] Итоговая длина: ${fullContent.length} символов');
    } else {
      print('[Message.toJson] Текстовых файлов не найдено');
      // Вывод информации о всех файлах для отладки
      for (final file in attachedFiles) {
        print(
            '[Message.toJson] Файл: ${file.name}, MIME: ${file.mimeType}, isTextFile: ${file.isTextFile}, isImage: ${file.isImage}');
      }
    }

    // Если есть изображения, используем multimodal формат
    if (attachedFiles.any((f) => f.isImage)) {
      final contentList = <Map<String, dynamic>>[];

      // Добавляем текст (включая содержимое текстовых файлов)
      if (fullContent.trim().isNotEmpty) {
        contentList.add({
          'type': 'text',
          'text': fullContent,
        });
      }

      // Добавляем изображения
      for (final file in attachedFiles) {
        if (file.isImage) {
          final base64Data = await file.getBase64Data();
          contentList.add({
            'type': 'image_url',
            'image_url': {
              'url': 'data:${file.mimeType};base64,$base64Data',
            },
          });
        }
      }

      return {
        'role': role.name,
        'content': contentList,
      };
    }

    // Если есть только текстовые файлы без изображений, отправляем как обычный текст
    // или если есть файлы других типов (не изображения и не текст)
    if (attachedFiles.isNotEmpty) {
      final nonImageFiles = attachedFiles.where((f) => !f.isImage).toList();
      if (nonImageFiles.isNotEmpty && !attachedFiles.any((f) => f.isTextFile)) {
        // Добавляем информацию о файлах, которые не были обработаны
        final fileNames = nonImageFiles.map((f) => f.name).join(', ');
        fullContent += '\n\n[Прикреплённые файлы: $fileNames]';
      }
    }

    // Обычный текстовый формат (с содержимым текстовых файлов)
    return {
      'role': role.name,
      'content': fullContent,
    };
  }

  /// Конвертация в JSON для API запроса (синхронная версия для совместимости)
  Map<String, dynamic> toJsonSync() {
    return {
      'role': role.name,
      'content': content,
    };
  }

  /// Создание сообщения из JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
      content: json['content'] as String,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Создание копии сообщения с изменёнными полями
  Message copyWith({
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isEdited,
    String? id,
    List<AttachedFile>? attachedFiles,
  }) {
    return Message(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      id: id ?? this.id,
      attachedFiles: attachedFiles ?? this.attachedFiles,
    );
  }

  /// Проверка, является ли сообщение от пользователя
  bool get isUser => role == MessageRole.user;

  /// Проверка, является ли сообщение от ассистента
  bool get isAssistant => role == MessageRole.assistant;
}
