import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/providers/base_provider.dart';
import '../services/providers/provider_factory.dart';

/// Состояние настроек
class SettingsState {
  /// API ключ (замаскирован для отображения)
  final String maskedApiKey;

  /// Валиден ли API ключ
  final bool isValidApiKey;

  /// Размер шрифта для блоков кода
  final double codeFontSize;

  /// Таймаут запроса к API в секундах
  final int requestTimeout;

  /// ID выбранного провайдера ('glm' или 'openrouter')
  final String selectedProviderId;

  /// Название модели
  final String modelName;

  /// Маскированный API ключ OpenRouter
  final String? maskedOpenRouterApiKey;

  /// Валиден ли API ключ OpenRouter
  final bool isValidOpenRouterApiKey;

  SettingsState({
    this.maskedApiKey = '',
    this.isValidApiKey = false,
    this.codeFontSize = 20.0,
    this.requestTimeout = 120,
    this.selectedProviderId = 'glm',
    this.modelName = 'glm-4.7',
    this.maskedOpenRouterApiKey,
    this.isValidOpenRouterApiKey = false,
  });

  SettingsState copyWith({
    String? maskedApiKey,
    bool? isValidApiKey,
    double? codeFontSize,
    int? requestTimeout,
    String? selectedProviderId,
    String? modelName,
    String? maskedOpenRouterApiKey,
    bool? isValidOpenRouterApiKey,
  }) {
    return SettingsState(
      maskedApiKey: maskedApiKey ?? this.maskedApiKey,
      isValidApiKey: isValidApiKey ?? this.isValidApiKey,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      modelName: modelName ?? this.modelName,
      maskedOpenRouterApiKey: maskedOpenRouterApiKey ?? this.maskedOpenRouterApiKey,
      isValidOpenRouterApiKey: isValidOpenRouterApiKey ?? this.isValidOpenRouterApiKey,
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
      // Загружаем API ключ GLM
      final apiKey = await _storage.getApiKey();
      final codeFontSize = await _storage.getCodeFontSize();
      final requestTimeout = await _storage.getRequestTimeout();

      // Загружаем провайдер и модель
      final selectedProviderId = await _storage.getSelectedProvider();
      final modelName = await _storage.getModelName();
      print('[SettingsProvider._loadSettings] Загружен провайдер: $selectedProviderId, модель: "$modelName"');

      // Загружаем API ключ OpenRouter
      final openRouterApiKey = await _storage.getOpenRouterApiKey();

      state = state.copyWith(
        maskedApiKey: apiKey != null && apiKey.isNotEmpty ? _maskApiKey(apiKey) : '',
        isValidApiKey: apiKey != null && apiKey.isNotEmpty,
        codeFontSize: codeFontSize,
        requestTimeout: requestTimeout,
        selectedProviderId: selectedProviderId,
        modelName: modelName,
        maskedOpenRouterApiKey: openRouterApiKey != null && openRouterApiKey.isNotEmpty
            ? _maskApiKey(openRouterApiKey)
            : null,
        isValidOpenRouterApiKey: openRouterApiKey != null && openRouterApiKey.isNotEmpty,
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

  /// Установка таймаута запроса
  Future<void> setRequestTimeout(int seconds) async {
    try {
      await _storage.saveRequestTimeout(seconds);
      state = state.copyWith(requestTimeout: seconds);
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Установка выбранного провайдера
  Future<void> setProvider(String providerId) async {
    try {
      print('[SettingsProvider.setProvider] Установка провайдера: $providerId');
      await _storage.saveSelectedProvider(providerId);

      // Получаем провайдер
      final provider = ProviderFactory.getProvider(providerId);
      if (provider != null) {
        // Проверяем, есть ли уже сохранённая модель для этого провайдера
        final savedModel = await _storage.getModelName();
        print('[SettingsProvider.setProvider] Сохранённая модель: "$savedModel", дефолтная для провайдера: "${provider.defaultModel}"');

        // Определяем, какую модель использовать
        String modelToUse;
        final bool isDefaultGLMModel = savedModel == 'glm-4.7';
        final bool isCurrentProviderGLM = providerId == 'glm';

        // Если текущий провайдер не GLM, а сохранённая модель - дефолтная GLM, используем дефолтную модель нового провайдера
        if (!isCurrentProviderGLM && isDefaultGLMModel) {
          modelToUse = provider.defaultModel;
          print('[SettingsProvider.setProvider] Замена дефолтной GLM модели на: "$modelToUse"');
          await _storage.saveModelName(modelToUse);
        } else if (savedModel.isEmpty) {
          modelToUse = provider.defaultModel;
          print('[SettingsProvider.setProvider] Пустая модель, используем дефолтную: "$modelToUse"');
          await _storage.saveModelName(modelToUse);
        } else {
          modelToUse = savedModel;
          print('[SettingsProvider.setProvider] Используем сохранённую модель: "$modelToUse"');
        }

        state = state.copyWith(
          selectedProviderId: providerId,
          modelName: modelToUse,
        );
      } else {
        state = state.copyWith(selectedProviderId: providerId);
      }
    } catch (e) {
      print('[SettingsProvider.setProvider] Ошибка: $e');
    }
  }

  /// Установка названия модели
  Future<void> setModelName(String modelName) async {
    try {
      print('[SettingsProvider.setModelName] Сохранение модели: "$modelName"');
      await _storage.saveModelName(modelName);
      state = state.copyWith(modelName: modelName);
      print('[SettingsProvider.setModelName] Модель сохранена успешно');
    } catch (e) {
      print('[SettingsProvider.setModelName] Ошибка: $e');
    }
  }

  /// Сохранение API ключа OpenRouter
  Future<bool> setOpenRouterApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) {
      return false;
    }

    try {
      await _storage.saveOpenRouterApiKey(apiKey.trim());
      state = state.copyWith(
        maskedOpenRouterApiKey: _maskApiKey(apiKey.trim()),
        isValidOpenRouterApiKey: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Удаление API ключа OpenRouter
  Future<void> clearOpenRouterApiKey() async {
    try {
      await _storage.deleteOpenRouterApiKey();
      state = state.copyWith(
        maskedOpenRouterApiKey: null,
        isValidOpenRouterApiKey: false,
      );
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  /// Получение API ключа для текущего провайдера
  Future<String?> getApiKey() async {
    final providerId = state.selectedProviderId;
    if (providerId == 'openrouter') {
      return await _storage.getOpenRouterApiKey();
    } else {
      return await _storage.getApiKey();
    }
  }

  /// Получение объекта текущего провайдера
  AIProvider getCurrentProvider() {
    final providerId = state.selectedProviderId;
    return ProviderFactory.getProvider(providerId) ?? ProviderFactory.getDefaultProvider();
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
