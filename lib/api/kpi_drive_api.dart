import 'package:dio/dio.dart';
import 'package:test_trello_1/model/period.dart';

import '../model/api_reult.dart';
import '../utils/api_config.dart';

/// Клиент KPI-DRIVE API.
///
/// Особенности реализации:
///   • Период выборки параметризуется через [Period] — не зашит в константы.
///   • Все ошибки нормализованы к [ApiResult] (исключения не пробрасываются).
///   • Парсинг ответа централизован в [_unwrap] — единая точка интерпретации
///     поля STATUS, формата DATA и сообщений об ошибках.
///   • CancelToken позволяет отменить активные запросы при dispose,
///     что важно при быстрых переключениях UI и предотвращает «гонки».
///   • Никаких автоматических retry: если запрос вызывается «по кругу» —
///     это проблема вызывающей стороны (debounce/dedup делается в контроллере).
class KpiDriveApi {
  KpiDriveApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Authorization': 'Bearer ${ApiConfig.bearerToken}'},
          validateStatus: (_) => true,
        ),
      );

  final Dio _dio;
  CancelToken _cancelToken = CancelToken();

  void cancelInFlight() {
    _cancelToken.cancel('cancelled by client');
    _cancelToken = CancelToken();
  }

  void dispose() {
    cancelInFlight();
    _dio.close(force: true);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchIndicators({
    Period period = Period.defaultPeriod,
  }) {
    final form = FormData.fromMap({
      ...period.toFields(),
      'requested_mo_id': ApiConfig.requestedMoId,
      'behaviour_key': 'task,kpi_task',
      'with_result': 'false',
      'response_fields': 'name,indicator_to_mo_id,parent_id,order',
      'auth_user_id': ApiConfig.authUserId,
    });

    return _post<List<Map<String, dynamic>>>(
      '/indicators/get_mo_indicators',
      form,
      mapData: (data) {
        final rows = (data?['rows'] as List?) ?? const [];
        return rows
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(growable: false);
      },
    );
  }

  String _formatOrder(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Future<ApiResult<void>> saveTaskPosition(
    TaskPositionUpdate update, {
    Period period = Period.defaultPeriod,
  }) {
    final form = FormData()
      ..fields.addAll([
        ...period.toFields().entries.map((e) => MapEntry(e.key, e.value)),
        MapEntry('indicator_to_mo_id', update.taskId.toString()),
        const MapEntry('field_name', 'parent_id'),
        MapEntry('field_value', update.parentId.toString()),
        const MapEntry('field_name', 'order'),
        MapEntry('field_value', _formatOrder(update.order)),
        MapEntry('auth_user_id', ApiConfig.authUserId),
      ]);

    return _post<void>(
      '/indicators/save_indicator_instance_field',
      form,
      mapData: (_) {},
    );
  }

  Future<ApiResult<T>> _post<T>(
    String path,
    FormData form, {
    required T Function(Map<String, dynamic>? data) mapData,
  }) async {
    try {
      final res = await _dio.post(path, data: form, cancelToken: _cancelToken);
      return _unwrap<T>(res, mapData);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return ApiResult<T>.failure('Запрос отменён');
      }
      return ApiResult<T>.failure(_describeDioError(e));
    } catch (e) {
      return ApiResult<T>.failure('Неожиданная ошибка: $e');
    }
  }

  /// Разбор ответа KPI-DRIVE.
  ///
  /// Сервер часто отвечает 200 OK даже при логических ошибках,
  /// поэтому источник истины — поле `STATUS` в теле:
  ///   { "STATUS": "OK",    "DATA": {...} }            → success
  ///   { "STATUS": "ERROR", "error_message": "..." }   → failure
  ApiResult<T> _unwrap<T>(
    Response<dynamic> res,
    T Function(Map<String, dynamic>? data) mapData,
  ) {
    final body = res.data;

    if (body is! Map) {
      return ApiResult<T>.failure(
        'Неожиданный формат ответа (HTTP ${res.statusCode})',
      );
    }

    if (body['STATUS'] != 'OK') {
      final msg =
          body['error_message']?.toString() ??
          body['message']?.toString() ??
          'Сервер вернул ошибку (HTTP ${res.statusCode})';
      return ApiResult<T>.failure(msg);
    }

    final data = body['DATA'];
    final mapped = mapData(
      data is Map ? Map<String, dynamic>.from(data) : null,
    );
    return ApiResult<T>.success(mapped);
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Сервер не отвечает (connection timeout)';
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает (receive timeout)';
      case DioExceptionType.sendTimeout:
        return 'Сервер не отвечает (send timeout)';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером';
      case DioExceptionType.badCertificate:
        return 'Ошибка сертификата';
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return 'Сеть: ${e.message ?? e.type.name}';
    }
  }
}
