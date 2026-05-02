import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

@immutable
class Indicator extends Equatable {
  final int indicatorToMoId;
  final int parentId;
  final String name;
  final double order;

  const Indicator({
    required this.indicatorToMoId,
    required this.parentId,
    required this.name,
    required this.order,
  });

  Indicator copyWith({int? parentId, double? order}) => Indicator(
    indicatorToMoId: indicatorToMoId,
    parentId: parentId ?? this.parentId,
    name: name,
    order: order ?? this.order,
  );

  factory Indicator.fromJson(Map<String, dynamic> json) => Indicator(
    indicatorToMoId: _toInt(json['indicator_to_mo_id']),
    parentId: _toInt(json['parent_id']),
    name: (json['name'] ?? '').toString(),
    order: _toDouble(json['order']),
  );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [indicatorToMoId, parentId, name, order];
}
