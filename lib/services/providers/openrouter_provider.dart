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
        'openai/gpt-4-turbo',
        'openai/gpt-4o',
        'openai/gpt-4o-mini',
        'google/gemini-pro-1.5',
        'google/gemini-flash-1.5',
        'meta-llama/llama-3.1-70b',
        'meta-llama/llama-3.1-405b',
        'deepseek/deepseek-chat',
      ];

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
    };
  }
}
