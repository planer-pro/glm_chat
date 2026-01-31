import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/chat_provider.dart';
import 'session_list_item.dart';

/// Боковое меню с историей сессий
class SessionDrawer extends ConsumerWidget {
  const SessionDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessionState = ref.watch(sessionManagerProvider);
    final sessions = sessionState.sessions;
    final activeSessionId = sessionState.activeSessionId;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'История чатов',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Кнопка закрытия
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Кнопка "Новый чат"
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _createNewChat(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Новый чат'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Список сессий
            Expanded(
              child: sessions.isEmpty
                  ? _buildEmptyState(theme)
                  : _buildSessionsList(
                      context,
                      ref,
                      sessions,
                      activeSessionId,
                    ),
            ),

            const Divider(height: 1),

            // Кнопка "Удалить всю историю"
            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                  onPressed: () => _showDeleteAllDialog(context, ref),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Удалить всю историю',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

            // Информация о количестве сессий
            if (sessions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${sessions.length} ${_getSessionsCountText(sessions.length)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Построение пустого состояния
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет сохранённых чатов',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Начните новый разговор',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Построение списка сессий
  Widget _buildSessionsList(
    BuildContext context,
    WidgetRef ref,
    sessions,
    activeSessionId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isActive = session.id == activeSessionId;

        return SessionListItem(
          session: session,
          isActive: isActive,
          onTap: () => _loadSession(context, ref, session.id),
        );
      },
    );
  }

  /// Создание нового чата
  void _createNewChat(BuildContext context, WidgetRef ref) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.clearChat();

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Загрузка сессии
  void _loadSession(BuildContext context, WidgetRef ref, String sessionId) async {
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.loadSession(sessionId);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Показ диалога удаления всех сессий
  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить всю историю?'),
        content: const Text(
          'Вы уверены, что хотите удалить все сохранённые чаты? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final sessionManager = ref.read(sessionManagerProvider.notifier);
              await sessionManager.deleteAllSessions();

              // Создаём новую сессию
              final chatNotifier = ref.read(chatProvider.notifier);
              await chatNotifier.clearChat();

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );
  }

  /// Получение текста для количества сессий
  String _getSessionsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'чат';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'чата';
    } else {
      return 'чатов';
    }
  }
}
