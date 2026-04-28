import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApi {
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
    return 'http://localhost:8080';
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
    final baseUrl = resolveBaseUrl(apiBaseUrl: apiBaseUrl);
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

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    String? apiBaseUrl,
  }) async {
    final baseUrl = resolveBaseUrl(apiBaseUrl: apiBaseUrl);
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
    final baseUrl = resolveBaseUrl(apiBaseUrl: apiBaseUrl);
    final uri = Uri.parse(baseUrl).resolve(path);
    final response = await http.delete(uri).timeout(const Duration(seconds: 15));
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

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => 'HttpException($statusCode): $message';
}
