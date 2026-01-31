import 'base_provider.dart';
import 'glm_provider.dart';
import 'openrouter_provider.dart';

/// Фабрика для создания и получения AI-провайдеров.
///
/// Управляет всеми зарегистрированными провайдерами и предоставляет
/// удобный интерфейс для их получения.
class ProviderFactory {
  /// Приватный реестр всех зарегистрированных провайдеров.
  static final Map<String, AIProvider> _providers = {
    'glm': GLMProvider(),
    'openrouter': OpenRouterProvider(),
  };

  /// Возвращает провайдер по его ID.
  ///
  /// Параметр [id] - уникальный идентификатор провайдера.
  /// Возвращает объект провайдера или null, если провайдер не найден.
  static AIProvider? getProvider(String id) {
    return _providers[id];
  }

  /// Возвращает список всех зарегистрированных провайдеров.
  ///
  /// Возвращает список объектов AIProvider.
  static List<AIProvider> getAllProviders() {
    return _providers.values.toList();
  }

  /// Возвращает провайдер по умолчанию (GLM).
  ///
  /// Используется при первом запуске приложения.
  static AIProvider getDefaultProvider() {
    return _providers['glm']!;
  }

  /// Проверяет существование провайдера по ID.
  ///
  /// Параметр [id] - идентификатор провайдера для проверки.
  /// Возвращает true, если провайдер существует, иначе false.
  static bool hasProvider(String id) {
    return _providers.containsKey(id);
  }
}
