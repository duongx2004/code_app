import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class BackendApi {
  static Dio? _dio;
  static String? _userEmail;

  static Dio get _dioInstance {
    _dio ??= Dio(BaseOptions(
      baseUrl: resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add interceptors
    if (!_dio!.interceptors.any((interceptor) => interceptor is _AuthInterceptor)) {
      _dio!.interceptors.add(_AuthInterceptor());
    }
    if (!_dio!.interceptors.any((interceptor) => interceptor is _ErrorInterceptor)) {
      _dio!.interceptors.add(_ErrorInterceptor());
    }

    return _dio!;
  }

  static Future<void> setUserEmail(String? email) async {
    _userEmail = email;
  }

  static String resolveBaseUrl({String? apiBaseUrl}) {
    final configuredBaseUrl = apiBaseUrl?.trim();
    if (configuredBaseUrl != null && configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    const envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    const runnerBaseUrl = String.fromEnvironment('DART_RUNNER_API_BASE_URL', defaultValue: '');
    if (runnerBaseUrl.isNotEmpty) {
      return runnerBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8081';
  }

  static Future<Map<String, dynamic>> get(String path, {String? apiBaseUrl}) async {
    final baseUrl = resolveBaseUrl(apiBaseUrl: apiBaseUrl);
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
  }) async {
    final baseUrl = apiBaseUrl ?? resolveBaseUrl();
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  // New Dio-based methods with better error handling
  static Future<Map<String, dynamic>> getWithDio(String path) async {
    try {
      final response = await _dioInstance.get(path);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Silently handle 401 - don't throw error for progress loading
        debugPrint('401 Unauthorized for $path - user not logged in');
        return {};
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> postWithDio(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dioInstance.post(path, data: body);
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Silently handle 401 - don't throw error for progress saving
        debugPrint('401 Unauthorized for $path - user not logged in');
        return {'success': false, 'error': 'Not logged in'};
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
  }) async {
    final baseUrl = apiBaseUrl ?? resolveBaseUrl();
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http
        .put(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    String? apiBaseUrl,
  }) async {
    final baseUrl = apiBaseUrl ?? resolveBaseUrl();
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http.delete(uri).timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> deleteWithBody(
    String path,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
  }) async {
    final baseUrl = apiBaseUrl ?? resolveBaseUrl();
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http
        .delete(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          response.statusCode,
          decoded['error'] as String? ?? 'Lỗi server HTTP ${response.statusCode}',
        );
      }
      return decoded;
    } catch (error) {
      if (error is HttpException) rethrow;
      throw HttpException(response.statusCode, 'Invalid JSON response from backend');
    }
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add user email to headers if available
    if (BackendApi._userEmail != null) {
      options.headers['user-email'] = BackendApi._userEmail;
    }
    super.onRequest(options, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Don't show error dialog for 401 - handle silently
      debugPrint('401 error intercepted: ${err.requestOptions.path}');
      return handler.resolve(Response(
        requestOptions: err.requestOptions,
        statusCode: 401,
        statusMessage: 'Unauthorized',
        data: {'error': 'Not logged in'},
      ));
    }
    handler.next(err);
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => 'HttpException($statusCode): $message';
}