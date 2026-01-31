import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/message.dart';
import '../data/models/attached_file.dart';
import '../data/models/chat_request.dart';
import '../data/models/chat_session.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';
import 'session_provider.dart';

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

  /// ID текущей сессии
  final String? currentSessionId;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.editingMessageId,
    this.editingMessageText,
    this.currentSessionId,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    String? editingMessageId,
    String? editingMessageText,
    String? currentSessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      editingMessageId: editingMessageId ?? this.editingMessageId,
      editingMessageText: editingMessageText ?? this.editingMessageText,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }
}

/// Notifier для управления состоянием чата
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService;
  final Ref _ref;
  StreamSubscription? _streamSubscription;

  ChatNotifier(this._apiService, this._ref) : super(ChatState()) {
    _initializeSession();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// Инициализация сессии при запуске
  Future<void> _initializeSession() async {
    final sessionManager = _ref.read(sessionManagerProvider.notifier);

    // Ждём завершения загрузки сессий (слушаем состояние)
    // Проверяем состояние пока не завершится загрузка
    int attempts = 0;
    const maxAttempts = 50; // 5 секунд максимум

    while (sessionManager.state.isLoading && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    print('[ChatNotifier._initializeSession] Ждали загрузки ${attempts * 100}ms');

    // Получаем активную сессию
    final activeSession = sessionManager.getActiveSession();

    if (activeSession != null) {
      // Загружаем сообщения из активной сессии
      state = state.copyWith(
        messages: activeSession.messages,
        currentSessionId: activeSession.id,
      );
      print('[ChatNotifier._initializeSession] Загружена сессия: ${activeSession.title}');
    } else {
      // Создаём новую сессию
      final sessionId = await sessionManager.createSession();
      state = state.copyWith(currentSessionId: sessionId);
      print('[ChatNotifier._initializeSession] Создана новая сессия: $sessionId');
    }
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
          // Автосохранение сессии после получения ответа
          _saveCurrentSession();
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Сохранение текущей сессии
  Future<void> _saveCurrentSession() async {
    final sessionId = state.currentSessionId;
    if (sessionId == null) {
      print('[ChatNotifier._saveCurrentSession] Нет sessionId, пропускаем сохранение');
      return;
    }

    try {
      final sessionManager = _ref.read(sessionManagerProvider.notifier);
      print('[ChatNotifier._saveCurrentSession] Сохранение сессии $sessionId, сообщений: ${state.messages.length}');

      final currentSession = sessionManager.state.sessions
          .firstWhere((s) => s.id == sessionId, orElse: () {
        // Если сессия не найдена, создаём новую
        print('[ChatNotifier._saveCurrentSession] Сессия не найдена в списке, создаём новую');
        return ChatSession(
          id: sessionId,
          messages: state.messages,
        );
      });

      // Если это первое сообщение пользователя, обновляем заголовок
      ChatSession updatedSession = currentSession.withMessages(state.messages);

      // Проверяем: если сессия была пустой и теперь есть сообщения - обновляем заголовок
      final wasEmpty = currentSession.messages.isEmpty ||
          !currentSession.messages.any((m) => m.isUser);
      final hasUserMessages = state.messages.any((m) => m.isUser);

      if (wasEmpty && hasUserMessages) {
        // Обновляем заголовок на основе первого сообщения пользователя
        updatedSession = updatedSession.withUpdatedTitle();
        print('[ChatNotifier._saveCurrentSession] Обновлён заголовок: ${updatedSession.title}');
      }

      await sessionManager.updateSession(updatedSession);
      print('[ChatNotifier._saveCurrentSession] Сессия сохранена успешно');
    } catch (e) {
      print('[ChatNotifier._saveCurrentSession] Ошибка при сохранении сессии: $e');
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

  /// Очистка истории чата и создание новой сессии
  Future<void> clearChat() async {
    _streamSubscription?.cancel();

    final sessionManager = _ref.read(sessionManagerProvider.notifier);

    // Создаём новую сессию
    final newSessionId = await sessionManager.createSession();

    state = ChatState(currentSessionId: newSessionId);
  }

  /// Загрузка сообщений из сессии
  Future<void> loadSession(String sessionId) async {
    final sessionManager = _ref.read(sessionManagerProvider.notifier);
    final session = sessionManager.state.sessions
        .firstWhere((s) => s.id == sessionId);

    // Устанавливаем активную сессию
    await sessionManager.setActiveSession(sessionId);

    // Загружаем сообщения
    state = state.copyWith(
      messages: session.messages,
      currentSessionId: sessionId,
    );
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
