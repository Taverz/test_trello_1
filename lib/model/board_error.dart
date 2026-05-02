import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum BoardErrorKind { network, server, validation, unknown }

@immutable
class BoardError extends Equatable {
  final BoardErrorKind kind;
  final String message;

  const BoardError({required this.kind, required this.message});

  const BoardError.network(this.message) : kind = BoardErrorKind.network;
  const BoardError.server(this.message) : kind = BoardErrorKind.server;
  const BoardError.validation(this.message) : kind = BoardErrorKind.validation;
  const BoardError.unknown(this.message) : kind = BoardErrorKind.unknown;

  factory BoardError.fromApiMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('сеть') ||
        lower.contains('timeout') ||
        lower.contains('соединени') ||
        lower.contains('отвечает')) {
      return BoardError.network(raw);
    }
    return BoardError.server(raw);
  }

  @override
  List<Object?> get props => [kind, message];
}
