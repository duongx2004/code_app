import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_app/services/dart_code_runner.dart';

void main() {
  group('DartCodeRunner base URL resolution', () {
    test('uses Android emulator host by default on Android', () {
      expect(
        DartCodeRunner.resolveBaseUrl(platform: TargetPlatform.android),
        'http://10.0.2.2:8080',
      );
    });

    test('uses localhost by default on desktop platforms', () {
      expect(
        DartCodeRunner.resolveBaseUrl(platform: TargetPlatform.windows),
        'http://localhost:8081',
      );
    });

    test('explicit apiBaseUrl override wins over defaults', () {
      expect(
        DartCodeRunner.resolveBaseUrl(
          apiBaseUrl: 'http://192.168.1.10:8080',
          platform: TargetPlatform.android,
        ),
        'http://192.168.1.10:8080',
      );
    });
  });

  group('DartCodeExecutionResult flags', () {
    test('connectionFailed is false for normal server responses', () {
      const result = DartCodeExecutionResult(
        timedOut: false,
        connectionFailed: false,
        exitCode: 0,
        stdout: 'ok',
        stderr: '',
      );

      expect(result.connectionFailed, isFalse);
      expect(result.hasError, isFalse);
    });
  });
}
