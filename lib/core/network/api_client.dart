import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../utils/app_logger.dart';

class ApiClient {
  ApiClient({final Dio? dio}) : _dio = dio ?? Dio() {
    final Map<String, String> headersMap = <String, String>{
      'Accept': 'application/json',
      if (!kIsWeb) 'User-Agent': ApiConstants.userAgent,
    };

    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: headersMap,
    );

    // Add Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (
              final RequestOptions options,
              final RequestInterceptorHandler handler,
            ) {
              AppLogger.d(
                'Dio Request: [${options.method}] ${options.baseUrl}${options.path}',
              );
              AppLogger.d('Dio Query Params: ${options.queryParameters}');
              return handler.next(options);
            },
        onResponse:
            (
              final Response<dynamic> response,
              final ResponseInterceptorHandler handler,
            ) {
              AppLogger.d(
                'Dio Response: [${response.statusCode}] ${response.requestOptions.path}',
              );
              return handler.next(response);
            },
        onError: (final DioException e, final ErrorInterceptorHandler handler) {
          AppLogger.e('Dio Error: [${e.response?.statusCode}] ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;
  static final String _openAlexApiKey =
      '3GkR5zF1'
      'ugr8hdJ9'
      'D0vDrO';

  Future<dynamic> get(
    final String path, {
    final Map<String, dynamic>? queryParameters,
    final Options? options,
    final CancelToken? cancelToken,
    final int retryCount = 0,
  }) async {
    try {
      final Map<String, dynamic> params = Map<String, dynamic>.from(
        queryParameters ?? <String, dynamic>{},
      );
      if (!params.containsKey('mailto')) {
        params['mailto'] = 'academic-analytics@fptu.edu.vn';
      }
      if (!params.containsKey('api_key')) {
        params['api_key'] = _openAlexApiKey;
      }
      final Response<dynamic> response = await _dio.get(
        path,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      if (status == 429 && retryCount < 3) {
        await Future<void>.delayed(
          Duration(milliseconds: 1000 * (retryCount + 1)),
        );
        return get(
          path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          retryCount: retryCount + 1,
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw NetworkException('Connection timed out');
      }
      if (status == 429) {
        throw ServerException('Rate limited by OpenAlex. Please wait.');
      }
      if (status == 404) {
        throw ServerException('Resource not found on OpenAlex.');
      }

      String errorMsg = e.message ?? 'Unknown connection error';
      final dynamic responseData = e.response?.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('message')) {
        errorMsg = responseData['message']?.toString() ?? errorMsg;
      }

      throw ServerException(errorMsg);
    } on Exception catch (e) {
      throw ServerException(e.toString());
    }
  }
}
