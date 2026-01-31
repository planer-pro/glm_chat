import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../providers/chat_provider.dart';
import '../../data/models/attached_file.dart';

/// Поле ввода сообщения с кнопкой отправки и прикрепления файлов
/// Поддерживает отправку по ENTER, перенос строки по SHIFT+ENTER и редактирование сообщений
class ChatInputField extends ConsumerStatefulWidget {
  const ChatInputField({super.key});

  @override
  ConsumerState<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends ConsumerState<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// ID сообщения, которое в последний раз загружали в контроллер
  String? _lastEditingMessageId;

  /// Список выбранных для прикрепления файлов
  List<AttachedFile> _selectedFiles = [];

  /// Индикатор загрузки файлов
  bool _isLoadingFiles = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Выбор файлов для прикрепления (любые форматы)
  Future<void> _pickFiles() async {
    try {
      // Используем file_picker для выбора любых файлов
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        print('[ChatInputField] Выбрано ${result.files.length} файлов');

        final files = result.files.map((platformFile) {
          print(
              '[ChatInputField] Файл: ${platformFile.name}, путь: ${platformFile.path}');
          final attachedFile = AttachedFile.fromXFile(
            XFile(platformFile.path!, name: platformFile.name),
          );
          print(
              '[ChatInputField] MIME: ${attachedFile.mimeType}, isTextFile: ${attachedFile.isTextFile}');
          return attachedFile;
        }).toList();

        print('[ChatInputField] Создано ${files.length} объектов AttachedFile');

        setState(() {
          _selectedFiles = [..._selectedFiles, ...files];
        });

        print(
            '[ChatInputField] Всего выбрано файлов: ${_selectedFiles.length}');
      } else {
        print('[ChatInputField] Файлы не выбраны');
      }
    } catch (e) {
      print('[ChatInputField] Ошибка при выборе файлов: $e');
      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при выборе файлов: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Удаление файла из списка прикреплённых
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  /// Отправка или обновление сообщения
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final hasFiles = _selectedFiles.isNotEmpty;

    print(
        '[ChatInputField] Отправка сообщения. Текст: "$text", файлов: ${_selectedFiles.length}');

    if (text.isEmpty && !hasFiles) {
      print('[ChatInputField] Нечего отправлять');
      return;
    }

    final chatState = ref.read(chatProvider);
    final isEditing = chatState.editingMessageId != null;

    if (isEditing) {
      // Очищаем флаг последнего редактирования перед отправкой
      _lastEditingMessageId = null;
      // При редактировании файлы не поддерживаем
      print('[ChatInputField] Режим редактирования, отправляем без файлов');
      ref.read(chatProvider.notifier).updateMessage(text);
    } else {
      // Показываем индикатор загрузки файлов
      setState(() {
        _isLoadingFiles = true;
      });

      print('[ChatInputField] Отправка ${_selectedFiles.length} файлов в API');

      for (final file in _selectedFiles) {
        print(
            '[ChatInputField] - ${file.name}, MIME: ${file.mimeType}, isTextFile: ${file.isTextFile}');
      }

      try {
        // Отправляем новое сообщение с файлами
        // Файлы будут прочитаны асинхронно в методе toJson()
        await ref.read(chatProvider.notifier).sendMessage(
              text,
              files: _selectedFiles.isNotEmpty ? _selectedFiles : null,
            );
        print('[ChatInputField] Сообщение отправлено успешно');
      } finally {
        // Скрываем индикатор загрузки
        if (mounted) {
          setState(() {
            _isLoadingFiles = false;
          });
        }
      }
    }

    _controller.clear();
    _selectedFiles.clear();
    setState(() {});
    _focusNode.requestFocus();
  }

  /// Отмена редактирования
  void _cancelEditing() {
    _lastEditingMessageId = null;
    ref.read(chatProvider.notifier).cancelEditing();
    _controller.clear();
  }

  /// Обработка нажатия клавиш
  void _handleKeyEvent(FocusNode node, RawKeyEvent event) {
    final isLoading = ref.watch(chatProvider).isLoading;

    // ESC - отмена редактирования
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      final chatState = ref.read(chatProvider);
      if (chatState.editingMessageId != null) {
        _cancelEditing();
      }
      return;
    }

    // Отправка по ENTER (без SHIFT)
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !event.isShiftPressed) {
      if ((_controller.text.trim().isNotEmpty || _selectedFiles.isNotEmpty) &&
          !isLoading) {
        _sendMessage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isLoading = chatState.isLoading;
    final isEditing = chatState.editingMessageId != null;

    // Если начинается редактирование НОВОГО сообщения, заполняем поле ввода
    // Проверяем, что ID сообщения отличается от последнего загруженного
    if (isEditing &&
        chatState.editingMessageText != null &&
        chatState.editingMessageId != _lastEditingMessageId) {
      _lastEditingMessageId = chatState.editingMessageId;
      _controller.text = chatState.editingMessageText!;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerTheme.color!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Индикатор режима редактирования
          if (isEditing)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF60A5FA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF60A5FA),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Режим редактирования (кнопка X - отмена)',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          // Превью прикреплённых файлов
          if (_selectedFiles.isNotEmpty && !isEditing)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2332),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _FilePreview(
                    file: file,
                    onRemove: () => _removeFile(index),
                  );
                }).toList(),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Кнопка прикрепления файла (скрыта в режиме редактирования)
              if (!isEditing) ...[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : _pickFiles,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLoading
                            ? Colors.white12
                            : const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.attach_file,
                        color: isLoading ? Colors.white24 : Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: RawKeyboardListener(
                  focusNode: _focusNode,
                  onKey: (event) => _handleKeyEvent(_focusNode, event),
                  child: TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: isEditing
                          ? 'Редактируйте сообщение...'
                          : 'Введите сообщение... (ENTER — отправить, SHIFT+ENTER — новая строка)',
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: isEditing
                          ? const Color(0xFF60A5FA).withOpacity(0.08)
                          : const Color(0xFF1A2332),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isEditing) ...[
                // Кнопка отмены редактирования
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading ? null : _cancelEditing,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (isLoading || _isLoadingFiles) ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isLoading || _isLoadingFiles)
                          ? Colors.white12
                          : isEditing
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF60A5FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: (isLoading || _isLoadingFiles)
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            )
                          : Icon(
                              isEditing ? Icons.refresh : Icons.arrow_upward,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения превью прикреплённого файла
class _FilePreview extends StatefulWidget {
  final AttachedFile file;
  final VoidCallback onRemove;

  const _FilePreview({
    required this.file,
    required this.onRemove,
  });

  @override
  State<_FilePreview> createState() => _FilePreviewState();
}

class _FilePreviewState extends State<_FilePreview> {
  late Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = Future.value(File(widget.file.path));
  }

  @override
  Widget build(BuildContext context) {
    const width = 80.0;
    final height = widget.file.isImage ? 80.0 : 70.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white12,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Превью файла
          if (widget.file.isImage)
            FutureBuilder<File>(
              future: _fileFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      snapshot.data!,
                      width: width - 2,
                      height: height - 2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFileIcon();
                      },
                    ),
                  );
                }
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white24,
                    ),
                  ),
                );
              },
            )
          else
            _buildFileIcon(),
          // Кнопка удаления
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Иконка для файла, который не является изображением
  Widget _buildFileIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getFileIcon(widget.file.mimeType),
          color: Colors.white54,
          size: 24,
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.file.name,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
            maxLines: 1,
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
}
