import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/chat_provider.dart';

/// Экран настроек приложения
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await ref.read(settingsProvider.notifier).getApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    }
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showErrorSnackBar('API ключ не может быть пустым');
      return;
    }

    final success = await ref.read(settingsProvider.notifier).setApiKey(apiKey);
    if (success) {
      _showSuccessSnackBar('API ключ сохранён');
      ref.read(chatProvider.notifier).clearChat();
    } else {
      _showErrorSnackBar('Ошибка при сохранении API ключа');
    }
  }

  Future<void> _clearApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Вы уверены, что хотите удалить API ключ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsProvider.notifier).clearApiKey();
      _apiKeyController.clear();
      _showSuccessSnackBar('API ключ удалён');
      ref.read(chatProvider.notifier).clearChat();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Карточка с информацией о GLM 4.7
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GLM 4.7',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Модель от Zhipu AI',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'GLM 4.7 — это современная языковая модель, способная вести диалог, писать код, отвечать на вопросы и выполнять множество других задач.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Для получения API ключа посетите: https://open.bigmodel.cn/',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Карточка настроек API ключа
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Ключ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'Введите API ключ',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveApiKey,
                          icon: const Icon(Icons.save),
                          label: const Text('Сохранить'),
                        ),
                      ),
                      if (settingsState.isValidApiKey) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearApiKey,
                            icon: const Icon(Icons.delete),
                            label: const Text('Удалить'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (settingsState.isValidApiKey) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Текущий ключ: ${settingsState.maskedApiKey}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Карточка настроек размера шрифта кода
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_fields, color: Color(0xFF60A5FA)),
                      const SizedBox(width: 12),
                      Text(
                        'Размер шрифта кода',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Текущий размер: ${settingsState.codeFontSize.toInt()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: settingsState.codeFontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    label: settingsState.codeFontSize.toInt().toString(),
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setCodeFontSize(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FontSizeButton(
                        label: 'Мелкий',
                        size: 14,
                        currentSize: settingsState.codeFontSize,
                        onTap: () => ref.read(settingsProvider.notifier).setCodeFontSize(14),
                      ),
                      _FontSizeButton(
                        label: 'Средний',
                        size: 20,
                        currentSize: settingsState.codeFontSize,
                        onTap: () => ref.read(settingsProvider.notifier).setCodeFontSize(20),
                      ),
                      _FontSizeButton(
                        label: 'Крупный',
                        size: 26,
                        currentSize: settingsState.codeFontSize,
                        onTap: () => ref.read(settingsProvider.notifier).setCodeFontSize(26),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Карточка настроек таймаута
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF60A5FA)),
                      const SizedBox(width: 12),
                      Text(
                        'Таймаут ответа API',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Текущий таймаут: ${settingsState.requestTimeout} сек',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Большее значение позволяет модели отвечать дольше на сложные вопросы',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: settingsState.requestTimeout.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 27,
                    label: '${settingsState.requestTimeout} сек',
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setRequestTimeout(value.toInt());
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TimeoutButton(
                        label: '30 сек',
                        value: 30,
                        currentValue: settingsState.requestTimeout,
                        onTap: () => ref.read(settingsProvider.notifier).setRequestTimeout(30),
                      ),
                      _TimeoutButton(
                        label: '60 сек',
                        value: 60,
                        currentValue: settingsState.requestTimeout,
                        onTap: () => ref.read(settingsProvider.notifier).setRequestTimeout(60),
                      ),
                      _TimeoutButton(
                        label: '120 сек',
                        value: 120,
                        currentValue: settingsState.requestTimeout,
                        onTap: () => ref.read(settingsProvider.notifier).setRequestTimeout(120),
                      ),
                      _TimeoutButton(
                        label: '5 мин',
                        value: 300,
                        currentValue: settingsState.requestTimeout,
                        onTap: () => ref.read(settingsProvider.notifier).setRequestTimeout(300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Карточка с информацией
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'О приложении',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Версия'),
                    subtitle: Text('1.0.0'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.code),
                    title: Text('Особенности'),
                    subtitle: Text('Подсветка синтаксиса кода, редактирование сообщений, тёмная тема'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка для быстрого выбора размера шрифта
class _FontSizeButton extends StatelessWidget {
  final String label;
  final double size;
  final double currentSize;
  final VoidCallback onTap;

  const _FontSizeButton({
    required this.label,
    required this.size,
    required this.currentSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentSize == size;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: isSelected ? Colors.white : null,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(label),
    );
  }
}

/// Кнопка для быстрого выбора таймаута
class _TimeoutButton extends StatelessWidget {
  final String label;
  final int value;
  final int currentValue;
  final VoidCallback onTap;

  const _TimeoutButton({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentValue == value;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
        foregroundColor: isSelected ? Colors.white : null,
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(label),
    );
  }
}
