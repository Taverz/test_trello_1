import 'package:flutter/widgets.dart';

@immutable
class ApiResult<T> {
  final bool ok;
  final T? data;
  final String? error;

  const ApiResult.success(this.data) : ok = true, error = null;
  const ApiResult.failure(this.error) : ok = false, data = null;
}
