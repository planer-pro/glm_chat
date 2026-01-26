import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:markdown/markdown.dart' as md;
import '../code/code_block_widget.dart';
import '../../data/models/message.dart';
import '../../providers/chat_provider.dart';

/// Пузырь сообщения в чате (минималистичный дизайн)
class MessageBubble extends ConsumerWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final chatState = ref.watch(chatProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF60A5FA) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isUser
                ? _buildUserContent()
                : _buildAssistantContent(context, chatState),
          ),
          if (isUser) ...[
            const SizedBox(height: 4),
            // Кнопка редактирования
            InkWell(
              onTap: () =>
                  ref.read(chatProvider.notifier).startEditing(message),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited)
                      const Text(
                        'изменено · ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.white38,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Содержимое сообщения пользователя (простой текст + файлы)
  Widget _buildUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображаем все прикреплённые файлы
        if (message.attachedFiles.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: message.attachedFiles
                .map((file) => _buildAttachedFile(file))
                .toList(),
          ),
        // Текст сообщения (если есть)
        if (message.content.isNotEmpty) ...[
          if (message.attachedFiles.isNotEmpty) const SizedBox(height: 8),
          Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// Виджет для отображения прикреплённого файла (изображение или документ)
  Widget _buildAttachedFile(dynamic file) {
    const width = 150.0;
    final height = file.isImage ? 150.0 : 80.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: file.isImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.file(
                File(file.path),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFileIcon(file);
                },
              ),
            )
          : _buildFileIcon(file),
    );
  }

  /// Иконка для файла, который не является изображением
  Widget _buildFileIcon(dynamic file) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getFileIcon(file.mimeType),
          color: Colors.white54,
          size: 32,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            file.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Получение иконки в зависимости от типа файла
  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.videocam;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description;
    } else if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart;
    } else if (mimeType.contains('presentation') ||
        mimeType.contains('powerpoint')) {
      return Icons.slideshow;
    } else if (mimeType.startsWith('text/')) {
      return Icons.text_snippet;
    } else if (mimeType.contains('zip') ||
        mimeType.contains('rar') ||
        mimeType.contains('tar') ||
        mimeType.contains('archive')) {
      return Icons.archive;
    }
    return Icons.insert_drive_file;
  }

  /// Содержимое сообщения ассистента (Markdown + подсветка кода + кнопки действий)
  Widget _buildAssistantContent(BuildContext context, ChatState chatState) {
    final isLastMessage = chatState.messages.isNotEmpty &&
        chatState.messages.last.id == message.id;
    final isResponseComplete =
        isLastMessage && !chatState.isLoading && message.content.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: message.content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              color: Color(0xDDFFFFFF),
              fontSize: 15,
              height: 1.5,
            ),
            code: const TextStyle(
              backgroundColor: Color(0xFF0F172A),
              color: Color(0xFF60A5FA),
              fontSize: 14,
              fontFamily: 'monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            h1: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            h2: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            h3: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            strong: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            em: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
            a: const TextStyle(
              color: Color(0xFF60A5FA),
              decoration: TextDecoration.underline,
            ),
            listBullet: const TextStyle(
              color: Colors.white70,
            ),
            blockquote: const TextStyle(
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
            blockquoteDecoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.white24,
                  width: 3,
                ),
              ),
            ),
          ),
          builders: {
            'code': CodeElementBuilder(),
          },
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Кнопки действий (копировать, ответ окончен)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Кнопка копирования
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ответ скопирован'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.copy_outlined,
                        size: 12,
                        color: Colors.white38,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Копировать',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Индикатор завершения ответа
              if (isResponseComplete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ответ окончен',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Кастомный билдер для блоков кода
class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Получаем класс из атрибутов
    final String? className = element.attributes['class'];

    // Проверяем, является ли элемент кодовым блоком
    if (element.tag == 'pre' ||
        (className != null && className.startsWith('language-'))) {
      final String code = element.textContent;
      final String? language = className?.replaceFirst('language-', '');

      return CodeBlockWidget(
        code: code,
        language: language ?? 'plaintext',
      );
    }
    return null;
  }
}
