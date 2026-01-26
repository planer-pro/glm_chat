import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Кнопка копирования кода в буфер обмена
class CopyButton extends StatefulWidget {
  final String code;

  const CopyButton({
    super.key,
    required this.code,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    // Сбрасываем состояние через 2 секунды
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check_circle : Icons.copy,
                size: 16,
                color: _copied ? Colors.green : Colors.white70,
              ),
              if (_copied) ...[
                const SizedBox(width: 4),
                const Text(
                  'Скопировано!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
