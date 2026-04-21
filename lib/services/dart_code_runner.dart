import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DartCodeExecutionResult {
  final bool timedOut;
  final int? exitCode;
  final String stdout;
  final String stderr;
  final String? error;

  const DartCodeExecutionResult({
    required this.timedOut,
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
  static Future<DartCodeExecutionResult> runCode(
    String code, {
    String input = '',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    Directory? tempDir;

    try {
      tempDir = await Directory.systemTemp.createTemp('code_app_runner_');
      final scriptFile = File('${tempDir.path}${Platform.pathSeparator}main.dart');
      await scriptFile.writeAsString(code);

      final process = await Process.start(
        'dart',
        [scriptFile.path],
        workingDirectory: tempDir.path,
        runInShell: true,
      );

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      if (input.isNotEmpty) {
        process.stdin.write(input);
        if (!input.endsWith('\n')) {
          process.stdin.write('\n');
        }
      }
      await process.stdin.close();

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          process.kill();
          return -1;
        },
      );

      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;

      return DartCodeExecutionResult(
        timedOut: timedOut,
        exitCode: timedOut ? null : exitCode,
        stdout: stdout,
        stderr: stderr,
      );
    } on ProcessException catch (error) {
      return DartCodeExecutionResult(
        timedOut: false,
        exitCode: null,
        stdout: '',
        stderr: '',
        error: 'Không thể chạy Dart: ${error.message}',
      );
    } catch (error) {
      return DartCodeExecutionResult(
        timedOut: false,
        exitCode: null,
        stdout: '',
        stderr: '',
        error: 'Lỗi khi chạy code: $error',
      );
    } finally {
      if (tempDir != null && await tempDir.exists()) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {
          // Ignore cleanup errors.
        }
      }
    }
  }
}
