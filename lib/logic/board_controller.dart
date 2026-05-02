import 'package:flutter/foundation.dart';
import 'package:test_trello_1/model/board_status.dart';

import '../model/period.dart';
import '../api/kpi_drive_api.dart';
import '../model/board_error.dart';
import '../model/board_messages.dart';
import '../model/board_state.dart';
import '../model/indicator.dart';
import '../model/kanban_column.dart';

/// Состояние и логика канбан-доски.
class BoardController extends ChangeNotifier {
  BoardController(this._api);

  final KpiDriveApi _api;

  BoardState _state = const BoardState.initial();
  BoardState get state => _state;

  List<KanbanColumn> get columns => _state.columns;
  BoardStatus get status => _state.status;
  BoardError? get error => _state.error;

  bool _busy = false;
  bool get isBusy => _busy;

  @override
  void dispose() {
    _api.cancelInFlight();
    super.dispose();
  }

  DateTime? _lastLoadedAt;
  DateTime? get lastLoadedAt => _lastLoadedAt;

  Future<void> reloadIfStale({
    Duration staleAfter = const Duration(seconds: 30),
  }) async {
    if (_busy) return;
    final last = _lastLoadedAt;
    if (last != null && DateTime.now().difference(last) < staleAfter) {
      return;
    }
    await load();
  }

  Future<void> load() async {
    _setState(const BoardState.loading());

    final res = await _api.fetchIndicators();
    if (!res.ok) {
      _setState(
        BoardState.failure(
          BoardError.fromApiMessage(
            res.error ?? BoardMessages.loadFailedFallback,
          ),
        ),
      );
      return;
    }

    final indicators = res.data!.map(Indicator.fromJson).toList();
    _setState(BoardState.ready(_buildColumns(indicators)));
    _lastLoadedAt = DateTime.now();
  }

  Future<MoveResult> moveTask({
    required int taskId,
    required int toColumnId,
    required int toIndex,
  }) async {
    if (_busy) {
      return const MoveResult.failure(
        BoardError.validation(BoardMessages.operationInProgress),
      );
    }
    _setBusy(true);
    try {
      return await _doMove(
        taskId: taskId,
        toColumnId: toColumnId,
        toIndex: toIndex,
      );
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  /// 1. Пользователь дропает карточку
  /// 2. Сразу обновляем UI ← карточка уже на новом месте
  /// 3. В фоне шлём POST
  /// 4. Если ОК → ничего не делаем, всё уже правильно
  /// 5. Если ошибка → откат к снапшоту, snackbar с ошибкой
  Future<MoveResult> _doMove({
    required int taskId,
    required int toColumnId,
    required int toIndex,
  }) async {
    final snapshot = _cloneColumns(columns);
    final mutable = _cloneColumns(columns);

    // Извлечь задачу
    final origin = _extractTask(mutable, taskId);
    if (origin == null) {
      return const MoveResult.failure(
        BoardError.validation(BoardMessages.taskNotFound),
      );
    }

    // Найти целевую колонку
    final toColumnIdx = mutable.indexWhere((c) => c.id == toColumnId);
    if (toColumnIdx == -1) {
      return const MoveResult.failure(
        BoardError.validation(BoardMessages.columnNotFound),
      );
    }

    // No-op: уронили туда же, откуда взяли
    final clampedIndex = toIndex.clamp(0, mutable[toColumnIdx].tasks.length);
    final isSameColumn = origin.columnIdx == toColumnIdx;
    if (isSameColumn && clampedIndex == origin.index) {
      return const MoveResult.noop();
    }

    // Дробный order между соседями
    final newOrder = _computeOrderBetween(
      targetTasks: mutable[toColumnIdx].tasks,
      insertIndex: clampedIndex,
    );

    // Локальная вставка
    final updatedTask = origin.task.copyWith(
      parentId: mutable[toColumnIdx].id,
      order: newOrder,
    );
    mutable[toColumnIdx].tasks.insert(clampedIndex, updatedTask);

    // Оптимистичный апдейт - чтобы показать что переместили, в случае ошибки откат
    _setState(_state.withColumns(mutable));

    // API запрос
    final r = await _api.saveTaskPosition(
      TaskPositionUpdate(
        taskId: updatedTask.indicatorToMoId,
        parentId: updatedTask.parentId,
        order: updatedTask.order,
      ),
    );

    if (!r.ok) {
      _setState(_state.withColumns(snapshot));
      return MoveResult.failure(
        BoardError.fromApiMessage(r.error ?? BoardMessages.saveFailed),
      );
    }

    return const MoveResult.success();
  }

  /// Дробный order для вставки на [insertIndex] в [targetTasks].
  ///
  /// Пустая колонка     → 1
  /// В начало           → first.order / 2
  /// В конец            → last.order + 1
  /// Между prev и next  → (prev.order + next.order) / 2
  double _computeOrderBetween({
    required List<Indicator> targetTasks,
    required int insertIndex,
  }) {
    if (targetTasks.isEmpty) return 1;

    if (insertIndex <= 0) {
      return targetTasks.first.order / 2;
    }
    if (insertIndex >= targetTasks.length) {
      return targetTasks.last.order + 1;
    }
    final prev = targetTasks[insertIndex - 1].order;
    final next = targetTasks[insertIndex].order;
    return (prev + next) / 2;
  }

  void _setState(BoardState next) {
    _state = next;
    notifyListeners();
  }

  List<KanbanColumn> _cloneColumns(List<KanbanColumn> src) =>
      src.map((c) => c.copyWith(tasks: List.of(c.tasks))).toList();

  /// Удаляет задачу из колонок и возвращает её вместе с координатами,
  /// откуда её взяли. Если не нашли — возвращает null.
  _TaskOrigin? _extractTask(List<KanbanColumn> columns, int taskId) {
    for (var ci = 0; ci < columns.length; ci++) {
      final idx = columns[ci].tasks.indexWhere(
        (t) => t.indicatorToMoId == taskId,
      );
      if (idx != -1) {
        final task = columns[ci].tasks.removeAt(idx);
        return _TaskOrigin(task: task, columnIdx: ci, index: idx);
      }
    }
    return null;
  }

  /// Группирует плоский список indicator + kpi_task в колонки.
  /// Папка — это элемент, чей id встречается как parent_id у других.
  List<KanbanColumn> _buildColumns(List<Indicator> all) {
    final referencedAsParent = all.map((e) => e.parentId).toSet();
    final folders =
        all
            .where((e) => referencedAsParent.contains(e.indicatorToMoId))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

    final folderIds = folders.map((f) => f.indicatorToMoId).toSet();
    final tasks = all.where((e) => !folderIds.contains(e.indicatorToMoId));

    return folders.map((folder) {
      final inside =
          tasks.where((t) => t.parentId == folder.indicatorToMoId).toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      return KanbanColumn(
        id: folder.indicatorToMoId,
        title: folder.name,
        tasks: inside,
      );
    }).toList();
  }
}

class _TaskOrigin {
  final Indicator task;
  final int columnIdx;
  final int index;
  const _TaskOrigin({
    required this.task,
    required this.columnIdx,
    required this.index,
  });
}

/// Результат попытки переместить задачу.
///
/// Три явных исхода вместо `BoardError?`, где null был перегружен:
///   - [MoveResult.success]  — задача переехала, сервер подтвердил.
///   - [MoveResult.noop]     — пользователь уронил задачу туда же,
///                             откуда взял; запрос не отправлялся.
///   - [MoveResult.failure]  — что-то пошло не так, есть [error].
sealed class MoveResult {
  const MoveResult();

  const factory MoveResult.success() = MoveSuccess;
  const factory MoveResult.noop() = MoveNoop;
  const factory MoveResult.failure(BoardError error) = MoveFailure;

  bool get isSuccess => this is MoveSuccess;
  bool get isNoop => this is MoveNoop;
  bool get isFailure => this is MoveFailure;
}

final class MoveSuccess extends MoveResult {
  const MoveSuccess();
}

final class MoveNoop extends MoveResult {
  const MoveNoop();
}

final class MoveFailure extends MoveResult {
  final BoardError error;
  const MoveFailure(this.error);
}
