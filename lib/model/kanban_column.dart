import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:test_trello_1/model/indicator.dart';

@immutable
class KanbanColumn extends Equatable {
  final int id;
  final String title;
  final List<Indicator> tasks;

  const KanbanColumn({
    required this.id,
    required this.title,
    required this.tasks,
  });

  KanbanColumn copyWith({String? title, List<Indicator>? tasks}) =>
      KanbanColumn(
        id: id,
        title: title ?? this.title,
        tasks: tasks ?? this.tasks,
      );

  @override
  List<Object?> get props => [id, title, tasks];
}
