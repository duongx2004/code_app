import 'package:flutter/material.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/code_editor.dart';
import 'package:code_app/services/dart_code_runner.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/dart.dart';

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen>
    with AutomaticKeepAliveClientMixin {
  late CodeController _codeController;
  String _output = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: "void main() {\n  print('Chào mừng bạn đến với Dart!');\n  int a = 10;\n  int b = 20;\n  print('Tổng của \$a và \$b là: \${a + b}');\n}",
      language: dart,
      patternMap: {
        r"\b(print|int|void|double|String|var|final|const|if|else|for|while|return|class|new|true|false)\b": const TextStyle(color: Color(0xFF61AFEF)),
        r"'.*?'": const TextStyle(color: Color(0xFF98C379)),
        r'".*?"': const TextStyle(color: Color(0xFF98C379)),
        r"\b\d+\b": const TextStyle(color: Color(0xFFB5CEA8)),
        r"//.*": const TextStyle(color: Color(0xFF6A9955)),
      },
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
      _output = '';
    });

    try {
      final executionResult = await DartCodeRunner.runCode(code);
      if (!mounted) return;
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
      if (!mounted) return;
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.05),
              AppTheme.lightBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompactHeader = constraints.maxWidth < 560;
                        final runButton = Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.buttonGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: isCompactHeader
                              ? IconButton(
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
                                      : const Icon(Icons.play_arrow, size: 18, color: Colors.white),
                                  tooltip: 'Chạy code',
                                )
                              : ElevatedButton.icon(
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
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                        );

                        if (isCompactHeader) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.code, color: AppTheme.primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Sân chơi Dart',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryLight,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: runButton,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.code, color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Sân chơi Dart',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            runButton,
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 900;
                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: _buildEditorCard()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildOutputCard()),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              Expanded(flex: 3, child: _buildEditorCard()),
                              const SizedBox(height: 12),
                              Expanded(flex: 2, child: _buildOutputCard()),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorCard() {
    return Container(
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
                Expanded(
                  child: Text(
                    'Trình soạn thảo code',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildOutputCard() {
    return Container(
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
                Expanded(
                  child: Text(
                    'Kết quả',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
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
                  _output.isEmpty ? 'Output....' : _output,
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
    );
  }
}
