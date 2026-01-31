import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Провайдер ApiService для использования в других провайдерах
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
