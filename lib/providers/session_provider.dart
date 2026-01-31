import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_session.dart';
import '../services/storage_service.dart';

/// Состояние менеджера сессий
class SessionManagerState {
  /// Список всех сессий
  final List<ChatSession> sessions;

  /// ID активной сессии
  final String? activeSessionId;

  /// Индикатор загрузки
  final bool isLoading;

  /// Текст ошибки
  final String? error;

  SessionManagerState({
    this.sessions = const [],
    this.activeSessionId,
    this.isLoading = false,
    this.error,
  });

  /// Получение активной сессии
  ChatSession? get activeSession {
    if (activeSessionId == null) return null;
    try {
      return sessions.firstWhere((s) => s.id == activeSessionId);
    } catch (e) {
      return null;
    }
  }

  SessionManagerState copyWith({
    List<ChatSession>? sessions,
    String? activeSessionId,
    bool? isLoading,
    String? error,
  }) {
    return SessionManagerState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier для управления сессиями
class SessionManagerNotifier extends StateNotifier<SessionManagerState> {
  final StorageService _storage;

  SessionManagerNotifier(this._storage) : super(SessionManagerState()) {
    // Загружаем сессии при создании
    loadSessions();
  }

  /// Загрузка сессий из хранилища
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);

    try {
      // Загружаем список сессий
      final sessionsJson = await _storage.getSessions();

      List<ChatSession> sessions = [];
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(sessionsJson);
        sessions = decoded
            .map((json) => ChatSession.fromJson(json as Map<String, dynamic>))
            .toList();

        // Сортируем по updatedAt (сначала новые)
        sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }

      // Загружаем ID активной сессии
      final activeSessionId = await _storage.getActiveSessionId();

      state = state.copyWith(
        sessions: sessions,
        activeSessionId: activeSessionId,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ошибка при загрузке сессий: $e',
      );
    }
  }

  /// Создание новой сессии
  Future<String> createSession({String? initialTitle}) async {
    try {
      final newSession = ChatSession(
        title: initialTitle,
        messages: [],
      );

      final updatedSessions = [newSession, ...state.sessions];

      // Сохраняем в хранилище
      await _saveSessionsToStorage(updatedSessions);

      // Устанавливаем как активную
      await _storage.saveActiveSessionId(newSession.id);

      state = state.copyWith(
        sessions: updatedSessions,
        activeSessionId: newSession.id,
      );

      return newSession.id;
    } catch (e) {
      state = state.copyWith(error: 'Ошибка при создании сессии: $e');
      rethrow;
    }
  }

  /// Обновление существующей сессии
  Future<void> updateSession(ChatSession updatedSession) async {
    try {
      final index =
          state.sessions.indexWhere((s) => s.id == updatedSession.id);

      if (index == -1) {
        // Если сессия не найдена, добавляем её
        final updatedSessions = [updatedSession, ...state.sessions];
        await _saveSessionsToStorage(updatedSessions);

        state = state.copyWith(sessions: updatedSessions);
        return;
      }

      // Обновляем сессию в списке
      final updatedSessions = List<ChatSession>.from(state.sessions);
      updatedSessions[index] = updatedSession;

      // Пересортировываем по updatedAt
      updatedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      await _saveSessionsToStorage(updatedSessions);

      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка при обновлении сессии: $e');
    }
  }

  /// Удаление сессии
  Future<void> deleteSession(String sessionId) async {
    try {
      final updatedSessions =
          state.sessions.where((s) => s.id != sessionId).toList();

      await _saveSessionsToStorage(updatedSessions);

      // Если удаляли активную сессию, сбрасываем activeSessionId
      final newActiveSessionId =
          state.activeSessionId == sessionId ? null : state.activeSessionId;

      if (state.activeSessionId == sessionId) {
        await _storage.deleteActiveSessionId();
      }

      state = state.copyWith(
        sessions: updatedSessions,
        activeSessionId: newActiveSessionId,
      );
    } catch (e) {
      state = state.copyWith(error: 'Ошибка при удалении сессии: $e');
    }
  }

  /// Удаление всех сессий
  Future<void> deleteAllSessions() async {
    try {
      await _storage.saveSessions('[]');
      await _storage.deleteActiveSessionId();

      state = state.copyWith(
        sessions: [],
        activeSessionId: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Ошибка при удалении сессий: $e');
    }
  }

  /// Установка активной сессии
  Future<void> setActiveSession(String sessionId) async {
    try {
      // Проверяем, что сессия существует
      final sessionExists =
          state.sessions.any((s) => s.id == sessionId);

      if (!sessionExists) {
        state = state.copyWith(error: 'Сессия не найдена');
        return;
      }

      await _storage.saveActiveSessionId(sessionId);

      state = state.copyWith(activeSessionId: sessionId);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка при установке активной сессии: $e');
    }
  }

  /// Получение активной сессии
  ChatSession? getActiveSession() {
    return state.activeSession;
  }

  /// Сохранение списка сессий в хранилище (вспомогательный метод)
  Future<void> _saveSessionsToStorage(List<ChatSession> sessions) async {
    final encoded =
        json.encode(sessions.map((s) => s.toJson()).toList());
    await _storage.saveSessions(encoded);
  }

  /// Очистка ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Провайдер StorageService для SessionManager
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Провайдер менеджера сессий
final sessionManagerProvider =
    StateNotifierProvider<SessionManagerNotifier, SessionManagerState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SessionManagerNotifier(storage);
});
