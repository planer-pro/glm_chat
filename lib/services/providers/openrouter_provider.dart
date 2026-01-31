import '../../data/models/chat_request.dart';
import 'base_provider.dart';

/// Провайдер для OpenRouter API.
///
/// Реализует взаимодействие с OpenRouter - агрегатором AI моделей.
/// OpenRouter обеспечивает доступ к множеству моделей через единый API.
class OpenRouterProvider implements AIProvider {
  @override
  String get providerId => 'openrouter';

  @override
  String get displayName => 'OpenRouter';

  @override
  String get baseUrl => 'https://openrouter.ai/api/v1';

  @override
  String get chatEndpoint => '/chat/completions';

  @override
  String? get modelsEndpoint => '/models';

  @override
  String get defaultModel => 'anthropic/claude-3.5-sonnet';

  @override
  List<String> get modelExamples => [
        'anthropic/claude-3.5-sonnet',
        'anthropic/claude-3.5-sonnet:beta',
        'openai/gpt-4o',
        'openai/gpt-4o-mini',
        'google/gemini-pro-1.5',
        'google/gemini-flash-1.5',
        'meta-llama/llama-3.1-70b',
        'deepseek/deepseek-chat',
      ];

  @override
  List<String> get supportedModels => [
        'anthropic/claude-3.5-sonnet',
        'anthropic/claude-3.5-sonnet:beta',
        'anthropic/claude-3-haiku',
        'openai/gpt-4o',
        'openai/gpt-4o-mini',
        'openai/chatgpt-4o',
        'openai/gpt-4-turbo',
        'google/gemini-pro-1.5',
        'google/gemini-flash-1.5',
        'meta-llama/llama-3.1-70b',
        'meta-llama/llama-3.1-405b',
        'meta-llama/llama-3.3-70b',
        'deepseek/deepseek-chat',
        'mistralai/mistral-7b',
      ];

  @override
  bool isModelSupported(String modelName) {
    // Проверяем формат: должен содержать '/'
    if (!modelName.contains('/')) {
      return false;
    }

    // Проверяем, что модель есть в списке популярных или соответствует формату
    if (supportedModels.contains(modelName)) {
      return true;
    }

    // Базовая проверка формата: provider/model-name
    final parts = modelName.split('/');
    if (parts.length != 2) return false;

    final provider = parts[0];
    final model = parts[1];

    // Проверяем, что провайдер валидный
    final validProviders = [
      'anthropic', 'openai', 'google', 'meta-llama',
      'deepseek', 'mistralai', 'cohere', 'perplexity',
      '01-ai', 'nebius', 'nvidia', 'microsoft',
    ];

    if (!validProviders.contains(provider)) {
      return false;
    }

    // Проверяем, что название модели не пустое
    if (model.trim().isEmpty) {
      return false;
    }

    return true;
  }

  @override
  String getModelErrorMessage(String modelName) {
    if (!modelName.contains('/')) {
      return 'Модель OpenRouter должна иметь формат "провайдер/модель".\n'
          'Пример: anthropic/claude-3.5-sonnet, openai/gpt-4o';
    }

    final parts = modelName.split('/');
    if (parts.length != 2) {
      return 'Неверный формат модели. Используйте формат "провайдер/модель".\n'
          'Пример: anthropic/claude-3.5-sonnet';
    }

    return 'Модель "$modelName" не найдена в списке поддерживаемых.\n'
        'Популярные модели: ${modelExamples.join(", ")}';
  }

  @override
  Map<String, String> buildHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/planerm/flutter-glm-chat',
      'X-Title': 'GLM Chat Flutter App',
    };
  }

  @override
  bool isValidApiKey(String apiKey) {
    // OpenRouter API ключи обычно начинаются с 'sk-or-v1-'
    if (apiKey.isEmpty) return false;
    final trimmed = apiKey.trim();
    return trimmed.length >= 20; // Минимальная длина ключа
  }

  @override
  Map<String, dynamic> formatRequest(ChatRequest request) {
    return {
      'model': request.model,
      'messages': request.messages,
      'temperature': request.temperature,
      'max_tokens': request.maxTokens,
      if (request.stream) 'stream': request.stream,
      // OpenRouter: предотвращаем добавление префиксов и модификацию ответа
      'include_reasoning': false,
      'provider': {
        'order': ['DeepSeek', 'Google', 'Anthropic'],
        'allow_fallbacks': false,
      },
    };
  }
}
