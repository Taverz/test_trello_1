import 'package:flutter/material.dart';

import '../../model/board_error.dart';
import '../app_theme.dart';

class BoardErrorView extends StatelessWidget {
  const BoardErrorView({super.key, required this.error, required this.onRetry});

  final BoardError error;
  final VoidCallback onRetry;

  IconData get _icon => switch (error.kind) {
    BoardErrorKind.network => Icons.cloud_off,
    BoardErrorKind.server => Icons.error_outline,
    BoardErrorKind.validation => Icons.warning_amber_outlined,
    BoardErrorKind.unknown => Icons.help_outline,
  };

  String get _title => switch (error.kind) {
    BoardErrorKind.network => 'Нет соединения',
    BoardErrorKind.server => 'Ошибка сервера',
    BoardErrorKind.validation => 'Некорректные данные',
    BoardErrorKind.unknown => 'Ошибка',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 36, color: KpiPalette.accentRed),
            const SizedBox(height: 12),
            Text(
              _title,
              style: const TextStyle(
                color: KpiPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: KpiPalette.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
