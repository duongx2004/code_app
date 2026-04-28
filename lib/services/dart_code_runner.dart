import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DartCodeExecutionResult {
  final bool timedOut;
  final bool connectionFailed;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final String? error;

  const DartCodeExecutionResult({
    required this.timedOut,
    required this.connectionFailed,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.error,
  });

  bool get hasError {
    return error != null ||
        stderr.trim().isNotEmpty ||
        timedOut ||
        (exitCode != null && exitCode != 0);
  }
}

class DartCodeRunner {
  static String resolveBaseUrl({String? apiBaseUrl, TargetPlatform? platform}) {
    final configuredBaseUrl = apiBaseUrl?.trim();
    if (configuredBaseUrl != null && configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    const envBaseUrl = String.fromEnvironment(
      'DART_RUNNER_API_BASE_URL',
      defaultValue: '',
    );

    if (envBaseUrl.isNotEmpty) {
      return envBaseUrl;
    }

    final effectivePlatform = platform ?? defaultTargetPlatform;
    if (effectivePlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }

    return 'http://localhost:8080';
  }

  static Future<DartCodeExecutionResult> runCode(
    String code, {
    String input = '',
    Duration timeout = const Duration(seconds: 5),
    String? apiBaseUrl,
  }) async {
    try {
      final baseUrl = resolveBaseUrl(apiBaseUrl: apiBaseUrl);
      final requestUri = Uri.parse(baseUrl).resolve('/run_dart');
      final response = await http
          .post(
            requestUri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'code': code,
              'input': input,
              'timeout': timeout.inSeconds,
            }),
          )
          .timeout(timeout + const Duration(seconds: 8));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint('DartCodeRunner: Received response - stdout: "${decoded['stdout']}", stderr: "${decoded['stderr']}", error: "${decoded['error']}", timedOut: ${decoded['timedOut']}, exitCode: ${decoded['exitCode']}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return DartCodeExecutionResult(
          timedOut: false,
          connectionFailed: false,
          exitCode: decoded['exitCode'] as int?,
          stdout: (decoded['stdout'] as String?) ?? '',
          stderr: (decoded['stderr'] as String?) ?? '',
          error: (decoded['error'] as String?) ??
              'Server trả về lỗi HTTP ${response.statusCode}',
        );
      }

      return DartCodeExecutionResult(
        timedOut: decoded['timedOut'] as bool? ?? false,
        connectionFailed: false,
        exitCode: decoded['exitCode'] as int?,
        stdout: (decoded['stdout'] as String?) ?? '',
        stderr: (decoded['stderr'] as String?) ?? '',
        error: decoded['error'] as String?,
      );
    } on http.ClientException catch (error) {
      debugPrint('DartCodeRunner: Connection failed: ${error.message}');
      return DartCodeExecutionResult(
        timedOut: false,
        connectionFailed: true,
        exitCode: null,
        stdout: '',
        stderr: '',
        error: 'Không thể kết nối server chạy code: ${error.message}',
      );
    } on TimeoutException {
      return DartCodeExecutionResult(
        timedOut: true,
        connectionFailed: true,
        exitCode: null,
        stdout: '',
        stderr: '',
        error: 'Yêu cầu chạy code bị hết thời gian chờ mạng hoặc server phản hồi chậm.',
      );
    } catch (error) {
      return DartCodeExecutionResult(
        timedOut: false,
        connectionFailed: false,
        exitCode: null,
        stdout: '',
        stderr: '',
        error: 'Lỗi khi gửi code lên server: $error',
      );
    }
  }
}
