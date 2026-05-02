import 'package:appflowy_board/appflowy_board.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_trello_1/logic/board_move_handler_mixin.dart';
import 'package:test_trello_1/model/board_error.dart';
import 'package:test_trello_1/model/board_messages.dart';

import '../logic/board_controller.dart';
import '../model/board_status.dart';
import 'component/board_app_bar.dart';
import 'component/board_error_view.dart';
import 'component/board_view.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with BoardMoveHandler, WidgetsBindingObserver {
  late final AppFlowyBoardController _board;
  final AppFlowyBoardScrollController _scroll = AppFlowyBoardScrollController();
  BoardController? _controller;

  /// Сравниваем хэш текущего набора колонок с предыдущим. Если визуально для _board ничего не изменилось — выходим,
  /// не трогаем appflowy_board. Для того чтобы не делать лишний перерисовок.
  String _keyTasks = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _board = AppFlowyBoardController(
      onMoveGroupItem: (groupId, fromIndex, toIndex) => handleMove(
        fromGroupId: groupId,
        fromIndex: fromIndex,
        toGroupId: groupId,
        toIndex: toIndex,
      ),
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) =>
          handleMove(
            fromGroupId: fromGroupId,
            fromIndex: fromIndex,
            toGroupId: toGroupId,
            toIndex: toIndex,
          ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<BoardController>();
      _controller = c;
      c.addListener(_onControllerChanged);
      c.load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  /// Срабатывает при смене состояния приложения (свернули, развернули,
  /// перешли на другую вкладку и обратно).
  ///
  /// Если пользователь вернулся на вкладку и данные старше 30 секунд —
  /// тихо перезагружаем, чтобы видеть актуальное состояние доски.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller?.reloadIfStale(staleAfter: const Duration(seconds: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BoardController>(
      builder: (context, c, _) => Scaffold(
        appBar: BoardAppBar(isBusy: c.isBusy, onRefresh: c.load),
        body: _buildBody(c),
      ),
    );
  }

  void _onControllerChanged() {
    // _board.enableGroupDragging(false);
    final c = _controller;
    if (c == null || c.status != BoardStatus.ready) return;

    final sig = c.columns
        .map(
          (col) =>
              '${col.id}:${col.tasks.map((t) => t.indicatorToMoId).join(",")}',
        )
        .join('|');
    if (sig == _keyTasks) return;
    _keyTasks = sig;

    _board.clear();
    for (final col in c.columns) {
      _board.addGroup(
        AppFlowyGroupData(
          id: col.id.toString(),
          name: col.title,
          items: col.tasks.map<AppFlowyGroupItem>(TaskItem.new).toList(),
        ),
      );
    }
    // _board.enableGroupDragging(false);
  }

  Widget _buildBody(BoardController c) {
    return switch (c.status) {
      BoardStatus.initial ||
      BoardStatus.loading => const Center(child: CircularProgressIndicator()),
      BoardStatus.error => BoardErrorView(
        error: c.error ?? const BoardError.unknown(BoardMessages.unknownError),
        onRetry: c.load,
      ),
      BoardStatus.ready => BoardView(
        controller: _board,
        scrollController: _scroll,
        columns: c.columns,
        isBusy: c.isBusy,
      ),
    };
  }
}
