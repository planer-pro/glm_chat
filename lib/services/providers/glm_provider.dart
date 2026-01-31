import '../../data/models/chat_request.dart';
import 'base_provider.dart';

/// Провайдер для Zhipu GLM API.
///
/// Реализует взаимодействие с API Zhipu AI (GLM-4.x).
class GLMProvider implements AIProvider {
  @override
  String get providerId => 'glm';

  @override
  String get displayName => 'GLM (Zhipu AI)';

  @override
  String get baseUrl => 'https://open.bigmodel.cn/api/paas/v4';

  @override
  String get chatEndpoint => '/chat/completions';

  @override
  String? get modelsEndpoint => null;

  @override
  String get defaultModel => 'glm-4.7';

  @override
  List<String> get modelExamples => [
        'glm-4.7',
        'glm-4-plus',
        'glm-4-flash',
        'glm-4-air',
      ];

  @override
  Map<String, String> buildHeaders(String apiKey) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  bool isValidApiKey(String apiKey) {
    // GLM API ключи обычно начинаются с определённого префикса
    // Проверяем на пустоту и минимальную длину
    if (apiKey.isEmpty) return false;
    return apiKey.trim().length >= 20;
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
