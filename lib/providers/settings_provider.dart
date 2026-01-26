import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Состояние настроек
class SettingsState {
  /// API ключ (замаскирован для отображения)
  final String maskedApiKey;

  /// Валиден ли API ключ
  final bool isValidApiKey;

  /// Размер шрифта для блоков кода
  final double codeFontSize;

  SettingsState({
    this.maskedApiKey = '',
    this.isValidApiKey = false,
    this.codeFontSize = 20.0,
  });

  SettingsState copyWith({
    String? maskedApiKey,
    bool? isValidApiKey,
    double? codeFontSize,
  }) {
    return SettingsState(
      maskedApiKey: maskedApiKey ?? this.maskedApiKey,
      isValidApiKey: isValidApiKey ?? this.isValidApiKey,
      codeFontSize: codeFontSize ?? this.codeFontSize,
    );
  }
}

/// Notifier для управления настройками
class SettingsNotifier extends StateNotifier<SettingsState> {
  final StorageService _storage;

  SettingsNotifier(this._storage) : super(SettingsState()) {
    _loadSettings();
  }

  /// Загрузка настроек при запуске
  Future<void> _loadSettings() async {
    try {
      // Загружаем API ключ
      final apiKey = await _storage.getApiKey();
      final codeFontSize = await _storage.getCodeFontSize();

      state = state.copyWith(
        maskedApiKey: apiKey != null && apiKey.isNotEmpty ? _maskApiKey(apiKey) : '',
        isValidApiKey: apiKey != null && apiKey.isNotEmpty,
        codeFontSize: codeFontSize,
      );
    } catch (e) {
      // Игнорируем ошибки при загрузке
    }
  }

  /// Маскирование API ключа для отображения
  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return '****';
    return '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}';
  }

  /// Сохранение API ключа
  Future<bool> setApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      return false;
    }

    try {
      await _storage.saveApiKey(apiKey.trim());
      state = state.copyWith(
        maskedApiKey: _maskApiKey(apiKey.trim()),
        isValidApiKey: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Удаление API ключа
  Future<void> clearApiKey() async {
    try {
      await _storage.deleteApiKey();
      state = SettingsState();
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Получение API ключа для API запросов
  Future<String?> getApiKey() async {
    return await _storage.getApiKey();
  }

  /// Проверка наличия API ключа
  Future<bool> hasApiKey() async {
    return await _storage.hasApiKey();
  }

  /// Установка размера шрифта кода
  Future<void> setCodeFontSize(double size) async {
    try {
      await _storage.saveCodeFontSize(size);
      state = state.copyWith(codeFontSize: size);
    } catch (e) {
      // Игнорируем ошибки
    }
  }
}

/// Провайдер StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Провайдер настроек
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});
