import 'dart:io';

import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:dio/dio.dart';

final publicRequest = Options(extra: const {'public': true});

Dio buildDio({required String baseUrl, required Future<String?> Function() token}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final value = options.extra['public'] == true ? null : await token();
        if (value != null && value.isNotEmpty) options.headers['Authorization'] = 'Bearer $value';
        handler.next(options);
      },
    ),
  );
  return dio;
}

AppException httpFailure(int? status, String message, {String? code}) {
  if (status == 401 && code != ErrorCodes.invalidCredentials) {
    return AppException(FailureType.unauthorized, message, code: code);
  }
  if (status != null && status >= 400 && status < 500 && status != 408 && status != 429) {
    return AppException(FailureType.rejected, message, code: code);
  }
  return AppException(FailureType.server, message, code: code);
}

Future<T> guardRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw _fromDio(e);
  } on TypeError {
    throw httpFailure(500, 'Unexpected response from the server');
  }
}

AppException _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const AppException.network();
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      final code = data is Map ? data['error'] as String? : null;
      final message = data is Map ? data['message'] as String? : null;
      return httpFailure(e.response?.statusCode, message ?? code ?? 'Server error', code: code);
    default:
      if (e.error is SocketException) return const AppException.network();
      return httpFailure(null, e.message ?? 'Request failed');
  }
}
