import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int defaultPort = 8080;
const int maxCodeSize = 100000;
const int maxInputSize = 20000;
const int maxTimeoutSeconds = 15;

int _readPort() {
  final rawPort = Platform.environment['PORT'];
  if (rawPort == null) {
    return defaultPort;
  }

  final parsed = int.tryParse(rawPort);
  if (parsed == null || parsed <= 0 || parsed > 65535) {
    return defaultPort;
  }

  return parsed;
}

String _readHost() {
  return Platform.environment['HOST'] ?? '0.0.0.0';
}

int _normalizeTimeoutSeconds(dynamic value) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  if (parsed == null || parsed <= 0) {
    return 5;
  }
  return parsed.clamp(1, maxTimeoutSeconds);
}

void _sendJson(HttpResponse response, int statusCode, Map<String, dynamic> payload) {
  final body = jsonEncode(payload);
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
  response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  response.write(body);
  response.close();
}

Future<String> _readRequestBody(HttpRequest request) async {
  final buffer = StringBuffer();
  await for (final chunk in request) {
    buffer.write(utf8.decode(chunk, allowMalformed: true));
    if (buffer.length > 2 * maxCodeSize) {
      throw const HttpException('Request body too large');
    }
  }
  return buffer.toString();
}

Future<void> _removeDir(Directory directory) async {
  try {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  } catch (_) {
    // Best effort cleanup.
  }
}

Future<Map<String, dynamic>> _runDartCode({
  required String code,
  required String input,
  required int timeoutSeconds,
}) async {
  final tempRoot = await Directory.systemTemp.createTemp('dart-runner-');
  final scriptPath = '${tempRoot.path}${Platform.pathSeparator}main.dart';
  final safeCode = code;
  final safeInput = input;

  final blockedPatterns = <RegExp>[
    RegExp(r'Process\.', caseSensitive: false),
    RegExp(r'File\.', caseSensitive: false),
    RegExp(r'File\(', caseSensitive: false),
    RegExp(r'Directory\.', caseSensitive: false),
    RegExp(r'Directory\(', caseSensitive: false),
    RegExp(r'Socket\.', caseSensitive: false),
    RegExp(r'HttpClient\.', caseSensitive: false),
    RegExp(r'HttpServer\.', caseSensitive: false),
    RegExp(r'ServerSocket\.', caseSensitive: false),
    RegExp(r'RandomAccessFile\.', caseSensitive: false),
    RegExp(r'Platform\.', caseSensitive: false),
  ];

  if (blockedPatterns.any((pattern) => pattern.hasMatch(safeCode))) {
    await _removeDir(tempRoot);
    return {
      'stdout': '',
      'stderr': 'Code chứa API hệ thống bị chặn bởi server sandbox.',
      'exitCode': 1,
      'timedOut': false,
      'error': 'Security policy rejected the submitted code.',
    };
  }

  if (utf8.encode(safeCode).length > maxCodeSize) {
    await _removeDir(tempRoot);
    return {
      'stdout': '',
      'stderr': '',
      'exitCode': 1,
      'timedOut': false,
      'error': 'Code quá lớn.',
    };
  }

  if (utf8.encode(safeInput).length > maxInputSize) {
    await _removeDir(tempRoot);
    return {
      'stdout': '',
      'stderr': '',
      'exitCode': 1,
      'timedOut': false,
      'error': 'Input quá lớn.',
    };
  }

  await File(scriptPath).writeAsString(safeCode, flush: true);

  var stdout = '';
  var stderr = '';
  var timedOut = false;

  late final Process child;

  try {
    child = await Process.start(
      'dart',
      [scriptPath],
      workingDirectory: tempRoot.path,
      runInShell: false,
      mode: ProcessStartMode.normal,
      environment: {
        'PATH': Platform.environment['PATH'] ?? '',
        'HOME': tempRoot.path,
        'TMP': tempRoot.path,
        'TEMP': tempRoot.path,
        'TMPDIR': tempRoot.path,
      },
    );
  } on ProcessException catch (error) {
    await _removeDir(tempRoot);
    return {
      'stdout': '',
      'stderr': '',
      'exitCode': null,
      'timedOut': false,
      'error': 'Không thể khởi chạy Dart: ${error.message}',
    };
  }

  final stdoutFuture = child.stdout.transform(utf8.decoder).join().then((value) {
    stdout = value;
  });
  final stderrFuture = child.stderr.transform(utf8.decoder).join().then((value) {
    stderr = value;
  });

  if (safeInput.isNotEmpty) {
    child.stdin.write(safeInput);
    if (!safeInput.endsWith('\n')) {
      child.stdin.write('\n');
    }
  }
  await child.stdin.close();

  final timer = Timer(Duration(seconds: timeoutSeconds), () {
    timedOut = true;
    child.kill(ProcessSignal.sigkill);
  });

  try {
    final exitCode = await child.exitCode;
    await Future.wait([stdoutFuture, stderrFuture]);
    timer.cancel();
    await _removeDir(tempRoot);
    return {
      'stdout': stdout,
      'stderr': stderr,
      'exitCode': timedOut ? null : exitCode,
      'timedOut': timedOut,
      'error': timedOut ? 'Code chạy quá thời gian cho phép.' : null,
    };
  } catch (error) {
    timer.cancel();
    await _removeDir(tempRoot);
    return {
      'stdout': stdout,
      'stderr': stderr,
      'exitCode': null,
      'timedOut': false,
      'error': 'Không thể chạy code: $error',
    };
  }
}

Future<void> main(List<String> args) async {
  final port = _readPort();
  final host = _readHost();
  final server = await HttpServer.bind(host, port);

  server.listen((request) async {
    if (request.method == 'OPTIONS') {
      _sendJson(request.response, HttpStatus.noContent, {});
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/health') {
      _sendJson(request.response, HttpStatus.ok, {'ok': true});
      return;
    }

    if (request.method == 'POST' && request.uri.path == '/run_dart') {
      try {
        final body = await _readRequestBody(request);
        final payload = body.isEmpty ? <String, dynamic>{} : jsonDecode(body) as Map<String, dynamic>;
        final code = payload['code'];
        final input = payload['input'];
        final timeoutSeconds = _normalizeTimeoutSeconds(payload['timeout']);

        final result = await _runDartCode(
          code: code is String ? code : '',
          input: input is String ? input : '',
          timeoutSeconds: timeoutSeconds,
        );

        _sendJson(request.response, result['error'] == null ? HttpStatus.ok : HttpStatus.badRequest, result);
        return;
      } catch (error) {
        _sendJson(request.response, HttpStatus.internalServerError, {
          'stdout': '',
          'stderr': '',
          'exitCode': null,
          'timedOut': false,
          'error': error.toString(),
        });
        return;
      }
    }

    _sendJson(request.response, HttpStatus.notFound, {'error': 'Không tìm thấy endpoint'});
  });

  stdout.writeln('Dart runner server listening on http://$host:$port');
}