import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/dart.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen>
    with AutomaticKeepAliveClientMixin {
  late CodeController _codeController;
  String _output = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: "void main() {\n  print('Chào mừng bạn đến với Dart!');\n  int a = 10;\n  int b = 20;\n  print('Tổng của \$a và \$b là: \${a + b}');\n}",
      language: dart,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _runCode() async {
    final code = _codeController.text;
    if (code.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _output = "";
    });

    // Giả lập thời gian chạy code
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Phân tích code đơn giản: tìm các dòng print('...') hoặc print("...")
      final lines = code.split('\n');
      final outputs = <String>[];

      for (var line in lines) {
        // Tìm vị trí của print(
        int printIndex = line.indexOf('print(');
        if (printIndex != -1) {
          // Tìm nội dung bên trong ngoặc
          int start = printIndex + 6; // sau 'print('
          int end = line.indexOf(')', start);
          if (end != -1) {
            String content = line.substring(start, end).trim();
            // Loại bỏ dấu nháy đơn hoặc kép ở đầu và cuối
            if ((content.startsWith("'") && content.endsWith("'")) ||
                (content.startsWith('"') && content.endsWith('"'))) {
              content = content.substring(1, content.length - 1);
              outputs.add(content);
            } else {
              // Nếu là biểu thức, thông báo
              outputs.add("[Biểu thức] $content");
            }
          }
        }
      }

      if (outputs.isEmpty) {
        _output = "Code chạy thành công (không có lệnh print nào).";
      } else {
        _output = outputs.join('\n');
      }
    } catch (e) {
      _output = "Lỗi: $e";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sân chơi Dart"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _codeController.text = "void main() {\n  \n}",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CodeTheme(
                  data: const CodeThemeData(styles: monokaiSublimeTheme),
                  child: CodeField(
                    controller: _codeController,
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                    expands: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runCode,
                icon: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? "Đang thực thi..." : "CHẠY CODE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Kết quả (Console):", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output.isEmpty ? "> Chờ thực thi..." : _output,
                    style: TextStyle(
                      color: _output.startsWith("Lỗi") ? Colors.redAccent : Colors.greenAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}