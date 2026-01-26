import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'copy_button.dart';
import '../../providers/settings_provider.dart';

/// Виджет для отображения блока кода с подсветкой синтаксиса
class CodeBlockWidget extends ConsumerWidget {
  final String code;
  final String? language;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Получаем размер шрифта из настроек
    final fontSize = ref.watch(settingsProvider).codeFontSize;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок с названием языка и кнопкой копирования
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language?.toUpperCase() ?? 'CODE',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                CopyButton(code: code),
              ],
            ),
          ),
          // Подсвеченный код с сохранением пробелов
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language ?? 'plaintext',
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: TextStyle(
                fontFamily: 'JetBrainsMono, Consolas, Monaco, monospace',
                fontSize: fontSize,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
