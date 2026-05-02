import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_trello_1/ui/app_theme.dart';

import '../../logic/board_controller.dart';

/// Перенос задачи между/внутри колонок + показ результата пользователю.
/// Отделено от UI-виджета, чтобы логика была переиспользуемой и тестируемой.
mixin BoardMoveHandler<T extends StatefulWidget> on State<T> {
  Future<void> handleMove({
    required String fromGroupId,
    required int fromIndex,
    required String toGroupId,
    required int toIndex,
  }) async {
    final c = context.read<BoardController>();

    final fromColumn = c.columns.firstWhere(
      (col) => col.id.toString() == fromGroupId,
      orElse: () => c.columns.first,
    );
    if (fromIndex < 0 || fromIndex >= fromColumn.tasks.length) return;

    final task = fromColumn.tasks[fromIndex];
    final result = await c.moveTask(
      taskId: task.indicatorToMoId,
      toColumnId: int.parse(toGroupId),
      toIndex: toIndex,
    );

    if (!mounted) return;

    switch (result) {
      case MoveNoop():
        break;
      case MoveSuccess():
        _showSnack('Задача «${task.name}» перемещена', isError: false);
      case MoveFailure(:final error):
        _showSnack(error.message, isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: isError ? KpiPalette.accentRed : KpiPalette.accentGreen,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: KpiPalette.surfaceAlt,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
        dismissDirection: DismissDirection.up,
      ),
    );
  }
}
