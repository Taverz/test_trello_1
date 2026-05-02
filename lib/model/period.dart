import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

@immutable
class Period extends Equatable {
  final String start; // YYYY-MM-DD
  final String end; // YYYY-MM-DD
  final String interval; // 'month' | 'week' | ...

  const Period({
    required this.start,
    required this.end,
    required this.interval,
  });

  /// Период по умолчанию из ТЗ .
  static const defaultPeriod = Period(
    start: '2026-04-01',
    end: '2026-04-30',
    interval: 'month',
  );

  Map<String, String> toFields() => {
    'period_start': start,
    'period_end': end,
    'period_key': interval,
  };

  @override
  List<Object?> get props => [start, end, interval];
}

@immutable
class TaskPositionUpdate extends Equatable {
  final int taskId;
  final int parentId;
  final double order;

  const TaskPositionUpdate({
    required this.taskId,
    required this.parentId,
    required this.order,
  });

  @override
  List<Object?> get props => [taskId, parentId, order];
}
