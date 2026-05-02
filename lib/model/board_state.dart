import 'package:equatable/equatable.dart';
import 'package:test_trello_1/model/board_status.dart';

import 'board_error.dart';
import 'kanban_column.dart';

/// Полное состояние доски в одной модели.
///
/// Пары `status` + `errorMessage` + `columns` склонны рассинхронизироваться
/// (например, status=ready, но columns пустой; или status=error, но
/// errorMessage уже null). Здесь они собраны в неизменяемый объект,
/// и каждый «вариант» создаётся через factory.
class BoardState extends Equatable {
  final BoardStatus status;
  final List<KanbanColumn> columns;
  final BoardError? error;

  const BoardState._({
    required this.status,
    required this.columns,
    required this.error,
  });

  const BoardState.initial()
    : status = BoardStatus.initial,
      columns = const [],
      error = null;

  const BoardState.loading()
    : status = BoardStatus.loading,
      columns = const [],
      error = null;

  const BoardState.ready(this.columns)
    : status = BoardStatus.ready,
      error = null;

  const BoardState.failure(BoardError this.error)
    : status = BoardStatus.error,
      columns = const [];

  /// Удобный copyWith для апдейта columns без смены status (например,
  /// после оптимистичного перемещения карточки).
  BoardState withColumns(List<KanbanColumn> next) =>
      BoardState._(status: status, columns: next, error: error);

  bool get isReady => status == BoardStatus.ready;

  @override
  List<Object?> get props => [status, columns, error];
}
