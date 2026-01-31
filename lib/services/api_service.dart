import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/chat_request.dart';
import '../data/models/chat_response.dart';
import '../services/providers/base_provider.dart';
import '../services/providers/provider_factory.dart';

/// Исключения для API ошибок
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (код: $statusCode)' : ''}';
}

/// Событие потокового ответа от API
class StreamedChatEvent {
  /// Порция текста (delta)
  final String delta;

  /// Завершён ли ответ
  final bool isDone;

  StreamedChatEvent({
    required this.delta,
    this.isDone = false,
  });
}

/// Сервис для работы с GLM API
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Отправка запроса к API с использованием провайдера.
  ///
  /// [provider] - провайдер API (GLM, OpenRouter и др.)
  /// [apiKey] - API ключ для авторизации
  /// [request] - объект с параметрами запроса
  /// [timeout] - таймаут запроса (по умолчанию 60 секунд)
  ///
  /// Возвращает [ChatResponse] с ответом от модели
  Future<ChatResponse> createChatCompletion(
    AIProvider provider,
    String apiKey,
    ChatRequest request, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? const Duration(seconds: 60);

    try {
      // Используем асинхронную конвертацию для поддержки multimodal content
      final requestBody = await request.toJson();
      final url = Uri.parse('${provider.baseUrl}${provider.chatEndpoint}');

      final response = await _client
          .post(
            url,
            headers: provider.buildHeaders(apiKey),
            body: jsonEncode(requestBody),
          )
          .timeout(effectiveTimeout);

      // Обработка ошибок по статус коду
      if (response.statusCode == 401) {
        throw ApiException('Неверный API ключ', statusCode: 401);
      } else if (response.statusCode == 429) {
        throw ApiException('Слишком много запросов. Попробуйте позже.', statusCode: 429);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw ApiException(
          error['error']?['message'] ?? 'Неверный запрос',
          statusCode: 400,
        );
      } else if (response.statusCode != 200) {
        throw ApiException(
          'Ошибка сервера: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // Парсинг успешного ответа
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatResponse.fromJson(jsonData);
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// Закрытие HTTP клиента
  void dispose() {
    _client.close();
  }

  /// Потоковая отправка запроса к API с использованием провайдера.
  ///
  /// [provider] - провайдер API (GLM, OpenRouter и др.)
  /// [apiKey] - API ключ для авторизации
  /// [request] - объект с параметрами запроса
  /// [timeout] - таймаут запроса (по умолчанию 60 секунд)
  ///
  /// Возвращает [Stream] с событиями, содержащими порции текста
  Stream<StreamedChatEvent> createStreamingChatCompletion(
    AIProvider provider,
    String apiKey,
    ChatRequest request, {
    Duration? timeout,
  }) async* {
    final effectiveTimeout = timeout ?? const Duration(seconds: 60);

    try {
      // Создаём потоковый запрос
      final requestStream = request.copyWith(stream: true);

      // Используем асинхронную конвертацию для поддержки multimodal content
      final requestBody = await requestStream.toJson();
      final url = Uri.parse('${provider.baseUrl}${provider.chatEndpoint}');

      final stream = _client
          .send(http.Request('POST', url)
            ..headers.addAll(provider.buildHeaders(apiKey))
            ..body = jsonEncode(requestBody))
          .timeout(effectiveTimeout);

      // Проверяем статус ответа
      final response = await stream;

      if (response.statusCode == 401) {
        throw ApiException('Неверный API ключ', statusCode: 401);
      } else if (response.statusCode == 429) {
        throw ApiException('Слишком много запросов. Попробуйте позже.', statusCode: 429);
      } else if (response.statusCode == 400) {
        final body = await response.stream.bytesToString();
        final error = jsonDecode(body);
        throw ApiException(
          error['error']?['message'] ?? 'Неверный запрос',
          statusCode: 400,
        );
      } else if (response.statusCode != 200) {
        throw ApiException(
          'Ошибка сервера: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      // Читаем поток SSE
      yield* response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.isNotEmpty && line.startsWith('data: '))
          .map((line) {
        try {
          final jsonStr = line.substring(6); // Удаляем "data: "
          if (jsonStr.trim() == '[DONE]') {
            return StreamedChatEvent(delta: '', isDone: true);
          }

          final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;
          final choices = jsonData['choices'] as List?;

          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0] as Map<String, dynamic>;
            final delta = firstChoice['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String? ?? '';
            final finishReason = firstChoice['finish_reason'];

            return StreamedChatEvent(
              delta: content,
              isDone: finishReason != null,
            );
          }

          return StreamedChatEvent(delta: '', isDone: false);
        } catch (e) {
          return StreamedChatEvent(delta: '', isDone: false);
        }
      });
    } on http.ClientException catch (e) {
      throw ApiException('Ошибка сети: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Неизвестная ошибка: ${e.toString()}');
    }
  }

  /// @deprecated
  /// Устаревший метод для обратной совместимости.
  /// Используйте версию с параметром [provider].
  Future<ChatResponse> createChatCompletionLegacy(
    String apiKey,
    ChatRequest request, {
    Duration? timeout,
  }) async {
    final glmProvider = ProviderFactory.getProvider('glm')!;
    return createChatCompletion(glmProvider, apiKey, request, timeout: timeout);
  }

  /// @deprecated
  /// Устаревший метод для обратной совместимости.
  /// Используйте версию с параметром [provider].
  Stream<StreamedChatEvent> createStreamingChatCompletionLegacy(
    String apiKey,
    ChatRequest request, {
    Duration? timeout,
  }) async* {
    final glmProvider = ProviderFactory.getProvider('glm')!;
    yield* createStreamingChatCompletion(
      glmProvider,
      apiKey,
      request,
      timeout: timeout,
    );
  }
}
