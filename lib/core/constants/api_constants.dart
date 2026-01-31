class ApiConstants {
  /// GLM 4.7 API endpoint
  static const String baseUrl = 'https://open.bigmodel.cn/api/paas/v4';

  /// Chat completions endpoint
  static const String chatCompletions = '$baseUrl/chat/completions';

  /// Model name
  static const String model = 'glm-4.7';

  /// Request timeout duration (увеличен для сложных запросов)
  static const Duration requestTimeout = Duration(seconds: 120);

  /// Temperature for response generation
  static const double defaultTemperature = 0.7;

  /// Maximum tokens in response
  static const int maxTokens = 4096;
}
