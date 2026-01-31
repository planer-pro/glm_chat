import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/providers/provider_factory.dart';

/// Экран настроек приложения
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelNameController = TextEditingController();
  bool _obscureText = true;
  String? _previousProviderId;

  @override
  void initState() {
    super.initState();
    // Загружаем начальные значения асинхронно
    Future.microtask(() async {
      _loadCurrentApiKey();
      await _loadModelName();
      // Загружаем список доступных моделей для текущего провайдера
      await ref.read(settingsProvider.notifier).loadAvailableModels();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Получаем текущие настройки
    final settingsState = ref.read(settingsProvider);
    print('[SettingsScreen.didChangeDependencies] Провайдер: ${settingsState.selectedProviderId}, Модель в state: "${settingsState.modelName}", Текст в контроллере: "${_modelNameController.text}"');

    // Обновляем контроллер модели только если:
    // 1. Текст контроллера отличается от состояния
    // 2. И контроллер пустой ИЛИ содержит дефолтную модель другого провайдера
    final controllerText = _modelNameController.text.trim();
    final stateModel = settingsState.modelName.trim();

    bool needsUpdate = controllerText != stateModel;

    // Если контроллер уже содержит правильное значение, не перезаписываем
    if (controllerText.isNotEmpty && controllerText == stateModel) {
      needsUpdate = false;
    }

    if (needsUpdate) {
      print('[SettingsScreen.didChangeDependencies] Обновление контроллера: "$controllerText" -> "$stateModel"');
      _modelNameController.text = stateModel;
    }

    // Обновляем API ключ только при переключении провайдера
    if (_previousProviderId != settingsState.selectedProviderId) {
      print('[SettingsScreen.didChangeDependencies] Переключение провайдера: $_previousProviderId -> ${settingsState.selectedProviderId}');
      _loadCurrentApiKey();
      _previousProviderId = settingsState.selectedProviderId;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentApiKey() async {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final apiKey = await settingsNotifier.getApiKey();
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
    } else {
      _apiKeyController.clear();
    }
  }

  Future<void> _loadModelName() async {
    final modelName = ref.read(settingsProvider).modelName;
    _modelNameController.text = modelName;
    print('[SettingsScreen._loadModelName] Загружена модель: "$modelName"');
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showErrorSnackBar('API ключ не может быть пустым');
      return;
    }

    final settingsNotifier = ref.read(settingsProvider.notifier);
    final providerId = ref.read(settingsProvider).selectedProviderId;

    final success = providerId == 'openrouter'
        ? await settingsNotifier.setOpenRouterApiKey(apiKey)
        : await settingsNotifier.setApiKey(apiKey);

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
      final settingsNotifier = ref.read(settingsProvider.notifier);
      final providerId = ref.read(settingsProvider).selectedProviderId;

      if (providerId == 'openrouter') {
        await settingsNotifier.clearOpenRouterApiKey();
      } else {
        await settingsNotifier.clearApiKey();
      }

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
    final currentProvider = ref.read(settingsProvider.notifier).getCurrentProvider();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Информационная карточка о провайдере
          _buildProviderInfoCard(currentProvider),

          const SizedBox(height: 24),

          // Карточка настроек API
          _buildApiSettingsCard(settingsState, currentProvider),

          const SizedBox(height: 24),

          // Карточка настроек размера шрифта кода
          _buildFontSettingsCard(settingsState),

          const SizedBox(height: 24),

          // Карточка настроек таймаута
          _buildTimeoutSettingsCard(settingsState),

          const SizedBox(height: 24),

          // Карточка с информацией о приложении
          _buildAboutCard(),
        ],
      ),
    );
  }

  /// Строит информационную карточку о провайдере
  Widget _buildProviderInfoCard(dynamic provider) {
    final isGLM = provider.providerId == 'glm';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGLM ? Icons.psychology : Icons.hub,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGLM ? 'Модель от Zhipu AI' : 'Агрегатор AI моделей',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isGLM
                  ? 'GLM 4.7 — это современная языковая модель, способная вести диалог, писать код, отвечать на вопросы и выполнять множество других задач.'
                  : 'OpenRouter предоставляет доступ к множеству AI моделей (Claude, GPT-4, Gemini и др.) через единый API.',
            ),
            const SizedBox(height: 12),
            Text(
              isGLM
                  ? 'Для получения API ключа посетите: https://open.bigmodel.cn/'
                  : 'Для получения API ключа посетите: https://openrouter.ai/',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит карточку настроек API
  Widget _buildApiSettingsCard(SettingsState settingsState, dynamic provider) {
    final isGLM = provider.providerId == 'glm';
    final isValidApiKey = isGLM ? settingsState.isValidApiKey : settingsState.isValidOpenRouterApiKey;
    final maskedApiKey = isGLM ? settingsState.maskedApiKey : settingsState.maskedOpenRouterApiKey ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор провайдера
            Text(
              'AI Провайдер',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: settingsState.selectedProviderId,
              decoration: const InputDecoration(
                labelText: 'Провайдер',
                border: OutlineInputBorder(),
              ),
              items: ProviderFactory.getAllProviders().map((p) {
                return DropdownMenuItem(
                  value: p.providerId,
                  child: Text(p.displayName),
                );
              }).toList(),
              onChanged: (value) async {
                if (value != null) {
                  await ref.read(settingsProvider.notifier).setProvider(value);
                  _apiKeyController.clear();
                  _loadCurrentApiKey();
                  _loadModelName();
                  // Загружаем список моделей для нового провайдера
                  await ref.read(settingsProvider.notifier).loadAvailableModels();
                }
              },
            ),
            const SizedBox(height: 24),

            // Название модели
            Text(
              'Название модели',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: settingsState.modelName.isNotEmpty ? settingsState.modelName : null,
              decoration: const InputDecoration(
                labelText: 'Выберите модель',
                border: OutlineInputBorder(),
              ),
              items: settingsState.availableModels.isEmpty
                  ? []
                  : settingsState.availableModels.map((model) {
                      // Проверяем, является ли модель разделителем группы (начинается с ───)
                      final bool isSeparator = model.startsWith('──');
                      return DropdownMenuItem<String>(
                        value: isSeparator ? null : model,
                        enabled: !isSeparator,
                        child: isSeparator
                            ? Text(
                                model,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(model),
                      );
                    }).toList(),
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  _modelNameController.text = value;
                  ref.read(settingsProvider.notifier).setModelName(value);
                  print('[SettingsScreen] Выбрана модель: "$value"');
                }
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Всего доступно моделей: ${settingsState.availableModels.where((m) => !m.startsWith('──')).length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 24),

            // API ключ
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
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                    ),
                  ],
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
                if (isValidApiKey) ...[
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
            if (isValidApiKey) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Текущий ключ: $maskedApiKey',
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Строит карточку настроек шрифта
  Widget _buildFontSettingsCard(SettingsState settingsState) {
    return Card(
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
    );
  }

  /// Строит карточку настроек таймаута
  Widget _buildTimeoutSettingsCard(SettingsState settingsState) {
    return Card(
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
    );
  }

  /// Строит информационную карточку о приложении
  Widget _buildAboutCard() {
    return Card(
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
              subtitle: Text('Поддержка GLM и OpenRouter, подсветка синтаксиса, редактирование сообщений'),
            ),
          ],
        ),
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
