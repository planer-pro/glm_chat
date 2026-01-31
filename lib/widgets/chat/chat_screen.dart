import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';
import '../chat/message_bubble.dart';
import '../chat/chat_input_field.dart';
import '../settings/settings_screen.dart';
import '../sessions/session_drawer.dart';

/// Главный экран чата
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  /// GlobalKey для управления Drawer (боковым меню)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Используем SchedulerBinding вместо Future.delayed для безопасной прокрутки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Получение названия приложения для AppBar на основе провайдера и модели
  String _getAppTitle(String providerId, String modelName) {
    // Короткое название модели для заголовка
    final shortModel = modelName.split('/').last; // Убираем "provider/" если есть
    final shortModel2 = shortModel.split('-').first; // Берем первую часть до дефиса

    // Карта коротких названий провайдеров
    // Для GLM показываем GLM Chat, для других - модель + Chat
    if (providerId == 'glm') {
      return 'GLM Chat';
    } else {
      return '$shortModel2 Chat';
    }
  }

  /// Получение отображаемого названия модели
  String _getModelDisplayName(String modelName) {
    // Убираем часть провайдера если есть (например, "anthropic/" -> "")
    if (modelName.contains('/')) {
      final parts = modelName.split('/');
      return parts.last; // Возвращаем только имя модели
    }
    return modelName;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final settingsState = ref.watch(settingsProvider);

    // Подписываемся на изменения сообщений для автопрокрутки
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    // Если API ключ не настроен, показываем экран настроек
    if (!settingsState.isValidApiKey) {
      return const NoApiKeyScreen();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SessionDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'История чатов',
        ),
        title: Text(
          _getAppTitle(settingsState.selectedProviderId, settingsState.modelName),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
          ),
          // Индикатор загрузки/завершения (улучшенный с анимацией)
          if (chatState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getModelDisplayName(settingsState.modelName)} думает...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'Это может занять время для сложных запросов',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Ошибка (минималистичная)
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3D1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B2B2B),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF5350),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(chatProvider.notifier).clearError();
                    },
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFEF5350),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          // Поле ввода
          const ChatInputField(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _getModelDisplayName(ref.watch(settingsProvider).modelName),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Начните диалог',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Экран "API ключ не настроен" (минималистичный дизайн)
class NoApiKeyScreen extends StatelessWidget {
  const NoApiKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF5350).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_off,
                  size: 48,
                  color: Color(0xFFEF5350),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'API ключ не настроен',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Для работы приложения необходим API ключ от Zhipu AI',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Перейти к настройкам'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
