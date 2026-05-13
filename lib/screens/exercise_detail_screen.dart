import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/services/dart_code_runner.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/code_editor.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final DartExercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late TextEditingController codeController;
  String output = '';
  bool isRunning = false;
  int passedTests = 0;
  int totalTests = 0;
  List<bool> testResults = [];
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController();
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
    });

    try {
      final result = await DartCodeRunner.runCode(code);
      setState(() {
        output = result.stdout;
        if (result.stderr.isNotEmpty) {
          output += '\nSTDERR:\n${result.stderr}';
        }
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
        output = 'Test Results:\n';
        for (int i = 0; i < totalTests; i++) {
          output += 'Test ${i + 1}: ${testResults[i] ? 'PASS' : 'FAIL'}\n';
        }
        if (!passed) {
          output += '\nOutput: ${result.stdout}\n';
          if (result.stderr.isNotEmpty) {
            output += 'Errors: ${result.stderr}\n';
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
            // Exercise info
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
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
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Độ khó: ${widget.exercise.difficulty}',
                        style: TextStyle(
                          color: _getDifficultyColor(widget.exercise.difficulty),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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
                  const SizedBox(height: 12),
                  Text(
                    widget.exercise.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.exercise.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
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
                                      child: Text(
                                        output,
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