import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../utils/app_logger.dart';

class ApiClient {
  final Dio _dio;

  static final String _openAlexApiKey = '3GkR5zF1' 'ugr8hdJ9' 'D0vDrO';

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Accept': 'application/json',
        // Participating in OpenAlex Polite Pool (Mobile/Desktop only, Web is blocked by browsers)
        if (!kIsWeb) 'User-Agent': ApiConstants.userAgent,
      },
    );

    // Add Logging Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Log outgoing request details safely in debug mode
          AppLogger.d('Dio Request: [${options.method}] ${options.baseUrl}${options.path}');
          AppLogger.d('Dio Query Params: ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful response details safely in debug mode
          AppLogger.d('Dio Response: [${response.statusCode}] ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Log request failure details safely in debug mode
          AppLogger.e('Dio Error: [${e.response?.statusCode}] ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int retryCount = 0,
  }) async {
    try {
      final params = Map<String, dynamic>.from(queryParameters ?? {});
      if (!params.containsKey('mailto')) {
        params['mailto'] = 'academic-analytics@fptu.edu.vn';
      }
      if (!params.containsKey('api_key')) {
        params['api_key'] = _openAlexApiKey;
      }
      final response = await _dio.get(
        path,
        queryParameters: params,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429 && retryCount < 3) {
        // Wait and retry with backoff
        await Future.delayed(Duration(milliseconds: 1000 * (retryCount + 1)));
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
      throw ServerException(
        e.response?.data?['message']?.toString() ?? e.message ?? 'Unknown connection error',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
