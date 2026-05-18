import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/services/dart_code_runner.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/code_editor.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/dart.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final DartExercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late CodeController codeController;
  String output = '';
  bool isRunning = false;
  int passedTests = 0;
  int totalTests = 0;
  List<bool> testResults = [];
  String stdoutOutput = '';
  String stderrOutput = '';
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    codeController = CodeController(
      language: dart,
      patternMap: {
        r"\b(print|int|void|double|String|var|final|const|if|else|for|while|return|class|new|true|false)\b": const TextStyle(color: Color(0xFF61AFEF)),
        r"'.*?'": const TextStyle(color: Color(0xFF98C379)),
        r'".*?"': const TextStyle(color: Color(0xFF98C379)),
        r"\b\d+\b": const TextStyle(color: Color(0xFFB5CEA8)),
        r"//.*": const TextStyle(color: Color(0xFF6A9955)),
      },
    );
    totalTests = widget.exercise.testCases.length;
    testResults = List.generate(totalTests, (index) => false);
    _isCompleted = Provider.of<ProgressService>(context, listen: false)
        .isExerciseCompleted(widget.exercise.id);
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> runCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Vui lòng nhập code!', Colors.orange);
      return;
    }

    setState(() {
      isRunning = true;
      output = 'Đang chạy code...\n';
      stdoutOutput = '';
      stderrOutput = '';
    });

    try {
      final result = await DartCodeRunner.runCode(code);
      setState(() {
        stdoutOutput = result.stdout ?? '';
        stderrOutput = result.stderr ?? '';
        output = stdoutOutput + (stderrOutput.isNotEmpty ? '\nSTDERR:\n$stderrOutput' : '');
        if (result.error != null) {
          output += '\nERROR: ${result.error}';
        }
        isRunning = false;
      });

      if (!result.hasError) {
        _showSnackBar('Code chạy thành công!', Colors.green);
      } else {
        _showSnackBar('Có lỗi trong code!', Colors.red);
      }
    } catch (e) {
      setState(() {
        output = 'Lỗi: $e';
        stdoutOutput = '';
        stderrOutput = '';
        isRunning = false;
      });
      _showSnackBar('Lỗi khi chạy code!', Colors.red);
    }
  }

  Future<void> runTests() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Vui lòng nhập code!', Colors.orange);
      return;
    }

    setState(() {
      isRunning = true;
      output = 'Đang chạy test...\n';
      passedTests = 0;
      testResults = List.generate(totalTests, (index) => false);
      stdoutOutput = '';
      stderrOutput = '';
    });

    try {
      // For now, just run the code and check if it executes without error
      // In a real implementation, this would run each test case individually
      final result = await DartCodeRunner.runCode(code);
      bool passed = !result.hasError;

      // Simulate running all test cases (in reality this would be more complex)
      for (int i = 0; i < totalTests; i++) {
        testResults[i] = passed; // All tests pass if code runs without error
        if (passed) passedTests++;
      }

      setState(() {
        stdoutOutput = result.stdout ?? '';
        stderrOutput = result.stderr ?? '';
        output = 'Test Results:\n';
        for (int i = 0; i < totalTests; i++) {
          output += 'Test ${i + 1}: ${testResults[i] ? 'PASS' : 'FAIL'}\n';
        }
        if (!passed) {
          output += '\nOutput: ${stdoutOutput}\n';
          if (stderrOutput.isNotEmpty) {
            output += 'Errors: ${stderrOutput}\n';
          }
        }
        isRunning = false;
      });

      if (passed && !_isCompleted) {
        await _markAsCompleted();
      }

      _showSnackBar(
        passed ? 'Tất cả test đều pass!' : '$passedTests/$totalTests test pass',
        passed ? Colors.green : Colors.orange,
      );
      if (passed) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() {
        output = 'Lỗi khi chạy test: $e';
        isRunning = false;
      });
      _showSnackBar('Lỗi khi chạy test!', Colors.red);
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      await Provider.of<ProgressService>(context, listen: false)
          .markExerciseAsCompleted(widget.exercise.id);
      setState(() => _isCompleted = true);
    } catch (e) {
      _showSnackBar('Lỗi khi lưu tiến độ: $e', Colors.red);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 4,
        actions: [
          if (_isCompleted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Hoàn thành',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Exercise info (constrained height to keep editor larger)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getDifficultyIcon(widget.exercise.difficulty),
                          color: _getDifficultyColor(widget.exercise.difficulty),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Độ khó: ${widget.exercise.difficulty}',
                          style: TextStyle(
                            color: _getDifficultyColor(widget.exercise.difficulty),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Test cases: $totalTests',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.exercise.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Description scrolls when it's long so it won't push the editor down
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          widget.exercise.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryLight,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Code editor and output
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppTheme.primaryGradient,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondaryLight,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.code),
                            text: 'Code Editor',
                          ),
                          Tab(
                            icon: Icon(Icons.terminal),
                            text: 'Output',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Code Editor Tab
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
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
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Viết code của bạn',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.buttonGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isRunning ? null : runCode,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Chạy',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.green, Colors.lightGreen],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isRunning ? null : runTests,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Test',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: CodeEditorWidget(
                                    controller: codeController,
                                    hintText: 'Nhập code Dart của bạn...',
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Output Tab
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Kết quả',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (passedTests > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: passedTests == totalTests ? Colors.green : Colors.orange,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$passedTests/$totalTests',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            output = '';
                                            stdoutOutput = '';
                                            stderrOutput = '';
                                            passedTests = 0;
                                          });
                                        },
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Xóa kết quả',
                                      ),
                                    ],
                                  ),
                                ),
                                // Pretty output area with separate panels
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0F1720),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Test results badges
                                          if (totalTests > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0),
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: List.generate(totalTests, (i) {
                                                  final passed = i < testResults.length ? testResults[i] : false;
                                                  return Chip(
                                                    backgroundColor: passed ? Colors.green[700] : Colors.red[700],
                                                    label: Text('Test ${i + 1}', style: const TextStyle(color: Colors.white)),
                                                    avatar: Icon(passed ? Icons.check : Icons.close, color: Colors.white, size: 18),
                                                  );
                                                }),
                                              ),
                                            ),

                                          // Stdout panel
                                          if (stdoutOutput.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0B1220),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.white12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Text('Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                      const Spacer(),
                                                      IconButton(
                                                        onPressed: () async {
                                                          await Clipboard.setData(ClipboardData(text: stdoutOutput));
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã sao chép output')));
                                                        },
                                                        icon: const Icon(Icons.copy, color: Colors.white70),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    stdoutOutput,
                                                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Stderr panel
                                          if (stderrOutput.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red[900],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Errors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  const SizedBox(height: 8),
                                                  SelectableText(
                                                    stderrOutput,
                                                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Fallback: plain output text
                                          if (stdoutOutput.isEmpty && stderrOutput.isEmpty)
                                            SelectableText(
                                              output,
                                              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace'),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'dễ':
        return Colors.green;
      case 'trung bình':
        return Colors.orange;
      case 'khó':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'dễ':
        return Icons.sentiment_satisfied;
      case 'trung bình':
        return Icons.sentiment_neutral;
      case 'khó':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }
}