import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ключ для хранения API ключа
const String _apiKeyKey = 'glm_api_key';

/// Ключ для хранения размера шрифта кода
const String _codeFontSizeKey = 'code_font_size';

/// Ключ для хранения таймаута запроса
const String _requestTimeoutKey = 'request_timeout';

/// Ключ для хранения списка сессий
const String _sessionsKey = 'chat_sessions';

/// Ключ для хранения ID активной сессии
const String _activeSessionIdKey = 'active_session_id';

/// Сервис для безопасного хранения API ключа
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  /// Получение сохранённого API ключа
  ///
  /// Возвращает null если ключ не найден
  Future<String?> getApiKey() async {
    try {
      return await _storage.read(key: _apiKeyKey);
    } catch (e) {
      throw Exception('Ошибка при чтении API ключа: $e');
    }
  }

  /// Сохранение API ключа
  ///
  /// [apiKey] - API ключ для сохранения
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.write(key: _apiKeyKey, value: apiKey);
    } catch (e) {
      throw Exception('Ошибка при сохранении API ключа: $e');
    }
  }

  /// Удаление сохранённого API ключа
  Future<void> deleteApiKey() async {
    try {
      await _storage.delete(key: _apiKeyKey);
    } catch (e) {
      throw Exception('Ошибка при удалении API ключа: $e');
    }
  }

  /// Проверка наличия сохранённого API ключа
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Очистка всех сохранённых данных
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Ошибка при очистке данных: $e');
    }
  }

  /// Получение размера шрифта кода
  ///
  /// Возвращает 20.0 по умолчанию если значение не найдено
  Future<double> getCodeFontSize() async {
    try {
      final value = await _storage.read(key: _codeFontSizeKey);
      return value != null ? double.tryParse(value) ?? 20.0 : 20.0;
    } catch (e) {
      return 20.0;
    }
  }

  /// Сохранение размера шрифта кода
  ///
  /// [size] - размер шрифта для сохранения
  Future<void> saveCodeFontSize(double size) async {
    try {
      await _storage.write(key: _codeFontSizeKey, value: size.toString());
    } catch (e) {
      throw Exception('Ошибка при сохранении размера шрифта: $e');
    }
  }

  // ========== Методы для работы с сессиями ==========

  /// Сохранение списка сессий в формате JSON
  ///
  /// [sessionsJson] - JSON строка с массивом сессий
  Future<void> saveSessions(String sessionsJson) async {
    try {
      await _storage.write(key: _sessionsKey, value: sessionsJson);
    } catch (e) {
      throw Exception('Ошибка при сохранении сессий: $e');
    }
  }

  /// Получение списка сессий в формате JSON
  ///
  /// Возвращает null если сессии не найдены
  Future<String?> getSessions() async {
    try {
      return await _storage.read(key: _sessionsKey);
    } catch (e) {
      throw Exception('Ошибка при чтении сессий: $e');
    }
  }

  /// Сохранение ID активной сессии
  ///
  /// [sessionId] - ID сессии для сохранения
  Future<void> saveActiveSessionId(String sessionId) async {
    try {
      await _storage.write(key: _activeSessionIdKey, value: sessionId);
    } catch (e) {
      throw Exception('Ошибка при сохранении ID активной сессии: $e');
    }
  }

  /// Получение ID активной сессии
  ///
  /// Возвращает null если активная сессия не установлена
  Future<String?> getActiveSessionId() async {
    try {
      return await _storage.read(key: _activeSessionIdKey);
    } catch (e) {
      throw Exception('Ошибка при чтении ID активной сессии: $e');
    }
  }

  /// Удаление ID активной сессии
  Future<void> deleteActiveSessionId() async {
    try {
      await _storage.delete(key: _activeSessionIdKey);
    } catch (e) {
      throw Exception('Ошибка при удалении ID активной сессии: $e');
    }
  }

  // ========== Методы для работы с таймаутом ==========

  /// Получение таймаута запроса в секундах
  ///
  /// Возвращает 120 по умолчанию если значение не найдено
  Future<int> getRequestTimeout() async {
    try {
      final value = await _storage.read(key: _requestTimeoutKey);
      return value != null ? int.tryParse(value) ?? 120 : 120;
    } catch (e) {
      return 120;
    }
  }

  /// Сохранение таймаута запроса
  ///
  /// [seconds] - таймаут в секундах для сохранения
  Future<void> saveRequestTimeout(int seconds) async {
    try {
      await _storage.write(key: _requestTimeoutKey, value: seconds.toString());
    } catch (e) {
      throw Exception('Ошибка при сохранении таймаута: $e');
    }
  }
}
