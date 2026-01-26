import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/models/attached_file.dart';
import '../data/models/chat_request.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';

/// Состояние чата
class ChatState {
  /// Список сообщений в диалоге
  final List<Message> messages;

  /// Индикатор загрузки
  final bool isLoading;

  /// Текст ошибки
  final String? error;

  /// ID сообщения, которое редактируется (если есть)
  final String? editingMessageId;

  /// Текст редактируемого сообщения
  final String? editingMessageText;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.editingMessageId,
    this.editingMessageText,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    String? editingMessageId,
    String? editingMessageText,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      editingMessageId: editingMessageId ?? this.editingMessageId,
      editingMessageText: editingMessageText ?? this.editingMessageText,
    );
  }
}

/// Notifier для управления состоянием чата
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;
  final Ref _ref;
  StreamSubscription? _streamSubscription;

  ChatNotifier(this._apiService, this._ref) : super(ChatState());

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// Отправка сообщения в API с потоковым выводом
  Future<void> sendMessage(String content, {List<AttachedFile>? files}) async {
    if (content.trim().isEmpty && (files == null || files.isEmpty)) return;

    print('[ChatNotifier.sendMessage] Получено сообщение: "$content", файлов: ${files?.length ?? 0}');

    // Отменяем предыдущий поток, если есть
    await _streamSubscription?.cancel();

    // Получаем API ключ
    final apiKey = await _ref.read(settingsProvider.notifier).getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      state = state.copyWith(error: 'API ключ не настроен');
      return;
    }

    // Создаём сообщение пользователя с возможными файлами
    final userMessage = Message(
      role: MessageRole.user,
      content: content,
      attachedFiles: files ?? [],
    );

    print('[ChatNotifier.sendMessage] Создано сообщение с ${userMessage.attachedFiles.length} файлами');

    // Создаём пустое сообщение ассистента, которое будет заполняться
    final assistantMessage = Message(
      role: MessageRole.assistant,
      content: '',
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Формируем запрос с историей сообщений (без пустого сообщения ассистента)
      final messagesWithoutAssistant = [...state.messages]..removeLast();
      print('[ChatNotifier.sendMessage] Всего сообщений для отправки: ${messagesWithoutAssistant.length}');

      // Проверяем последнее сообщение
      final lastUserMsg = messagesWithoutAssistant.lastWhere((m) => m.role == MessageRole.user);
      print('[ChatNotifier.sendMessage] Последнее сообщение пользователя имеет ${lastUserMsg.attachedFiles.length} файлов');

      // Создаём ГЛУБУКУЮ копию списка, чтобы файлы не потерялись при изменении состояния
      final messagesCopy = messagesWithoutAssistant.map((m) => Message(
        role: m.role,
        content: m.content,
        timestamp: m.timestamp,
        isEdited: m.isEdited,
        id: m.id,
        attachedFiles: List.from(m.attachedFiles), // Копируем список файлов
      )).toList();

      print('[ChatNotifier.sendMessage] Создана копия сообщений, файлов в последнем: ${messagesCopy.last.attachedFiles.length}');

      final request = ChatRequest.glm47(messagesCopy, stream: true);

      // Подписываемся на потоковый ответ
      _streamSubscription = _apiService
          .createStreamingChatCompletion(apiKey, request)
          .listen(
        (event) {
          // Обновляем содержимое последнего сообщения (ассистента)
          final lastMessage = state.messages.last;
          if (lastMessage.role == MessageRole.assistant) {
            final updatedContent = lastMessage.content + event.delta;
            final updatedMessage = lastMessage.copyWith(content: updatedContent);

            final updatedMessages = [...state.messages];
            updatedMessages[updatedMessages.length - 1] = updatedMessage;

            state = state.copyWith(
              messages: updatedMessages,
              isLoading: !event.isDone,
            );
          }
        },
        onError: (error) {
          state = state.copyWith(
            isLoading: false,
            error: error.toString(),
          );
        },
        onDone: () {
          state = state.copyWith(isLoading: false);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Начало редактирования сообщения
  void startEditing(Message message) {
    state = state.copyWith(
      editingMessageId: message.id,
      editingMessageText: message.content,
    );
  }

  /// Отмена редактирования
  void cancelEditing() {
    _clearEditingState();
  }

  /// Очистка состояния редактирования (вспомогательный метод)
  void _clearEditingState() {
    state = ChatState(
      messages: state.messages,
      isLoading: state.isLoading,
      error: state.error,
      editingMessageId: null,
      editingMessageText: null,
    );
  }

  /// Обновление сообщения и повторная отправка
  Future<void> updateMessage(String newContent) async {
    if (state.editingMessageId == null) return;

    final messageId = state.editingMessageId!;
    final index = state.messages.indexWhere((m) => m.id == messageId);

    if (index == -1) return;

    // Сохраняем список сообщений до сброса состояния
    final newMessages = state.messages.sublist(0, index);

    // Сначала сбрасываем состояние редактирования (синхронно)
    _clearEditingState();

    // Обновляем список сообщений
    state = state.copyWith(messages: newMessages);

    // Отправляем обновлённый запрос (sendMessage создаст новое сообщение)
    await sendMessage(newContent);
  }

  /// Очистка истории чата
  void clearChat() {
    _streamSubscription?.cancel();
    state = ChatState();
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Провайдер ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Провайдер состояния чата
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService, ref);
});
