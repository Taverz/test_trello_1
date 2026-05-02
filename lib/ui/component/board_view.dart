import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:test_trello_1/model/kanban_column.dart';

import '../../model/indicator.dart';
import '../app_theme.dart';
import 'column_header.dart';
import 'task_card.dart';

class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.columns,
    required this.isBusy,
  });

  final AppFlowyBoardController controller;
  final AppFlowyBoardScrollController scrollController;
  final List<KanbanColumn> columns;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    const config = AppFlowyBoardConfig(
      groupBackgroundColor: KpiPalette.surface,
      stretchGroupHeight: false,
      groupBodyPadding: EdgeInsets.symmetric(horizontal: 8),
    );

    final board = Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: AppFlowyBoard(
        controller: controller,
        boardScrollController: scrollController,
        groupConstraints: const BoxConstraints.tightFor(width: 300),
        config: config,
        headerBuilder: (context, group) {
          final idx = columns.indexWhere(
            (col) => col.id.toString() == group.id,
          );
          return ColumnHeader(
            title: group.headerData.groupName,
            count: group.items.length,
            accent: KpiPalette.columnAccent(idx < 0 ? 0 : idx),
          );
        },
        cardBuilder: (context, group, item) {
          final ti = item as TaskItem;
          final idx = columns.indexWhere(
            (col) => col.id.toString() == group.id,
          );
          return AppFlowyGroupCard(
            key: ValueKey(ti.id),
            decoration: const BoxDecoration(color: Colors.transparent),
            margin: EdgeInsets.zero,
            child: TaskCard(
              task: ti.task,
              accent: KpiPalette.columnAccent(idx < 0 ? 0 : idx),
            ),
          );
        },
      ),
    );

    return Stack(
      children: [
        IgnorePointer(ignoring: isBusy, child: board),
        if (isBusy)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.04)),
            ),
          ),
      ],
    );
  }
}

class TaskItem extends AppFlowyGroupItem {
  TaskItem(this.task);
  final Indicator task;

  @override
  String get id => task.indicatorToMoId.toString();
}
