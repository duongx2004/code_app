import 'package:flutter/material.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/code_editor.dart';
import 'package:code_app/services/dart_code_runner.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _codeController;
  String _output = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: "void main() {\n  print('Chào mừng bạn đến với Dart!');\n  int a = 10;\n  int b = 20;\n  print('Tổng của \$a và \$b là: \${a + b}');\n}",
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
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Vui lòng nhập code!', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _output = "";
    });

    try {
      final executionResult = await DartCodeRunner.runCode(code);
      setState(() {
        _output = executionResult.stdout;
        if (executionResult.stderr.isNotEmpty) {
          _output += '\nSTDERR:\n${executionResult.stderr}';
        }
        if (executionResult.error != null) {
          _output += '\nERROR: ${executionResult.error}';
        }
        _isLoading = false;
      });

      if (!executionResult.hasError) {
        _showSnackBar('Code chạy thành công!', Colors.green);
      } else {
        _showSnackBar('Có lỗi trong code!', Colors.red);
      }
    } catch (e) {
      setState(() {
        _output = 'Lỗi: $e';
        _isLoading = false;
      });
      _showSnackBar('Lỗi khi chạy code!', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.code, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('CodeLearn'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _codeController.clear();
              setState(() => _output = "");
            },
            tooltip: 'Xóa code',
          ),
        ],
      ),
      body: Container(
        color: AppTheme.lightBackground,
        child: Column(
          children: [
            // Admin toolbar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const Text(
                    'Sân chơi Dart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runCode,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.play_arrow, size: 16),
                      label: Text(_isLoading ? 'Đang chạy...' : 'Chạy code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Code editor and output
            Expanded(
              child: Row(
                children: [
                  // Code editor
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Trình soạn thảo code',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CodeEditorWidget(
                              controller: _codeController,
                              hintText: 'Nhập code Dart của bạn...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Output
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.terminal, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Text(
                                  'Kết quả',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _output.isEmpty ? 'Output sẽ hiển thị ở đây...' : _output,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}