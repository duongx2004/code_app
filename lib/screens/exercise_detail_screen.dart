import 'package:flutter/material.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/services/exercise_service.dart';
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

  @override
  void initState() {
    super.initState();
    codeController = TextEditingController();
    totalTests = widget.exercise.testCases.length;
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  void runCode() {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('Vui lòng nhập code!', Colors.orange);
      return;
    }

    setState(() {
      isRunning = true;
      output = '';
      testResults = [];
      passedTests = 0;
    });

    // Mô phỏng chạy code - trong thực tế bạn cần dùng Dart VM hoặc server backend
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _simulateCodeExecution(code);
      }
    });
  }

  void _simulateCodeExecution(String code) {
    // Đây là mô phỏng - thực tế cần backend để chạy code Dart
    List<bool> results = [];
    int passedTestsCount = 0;

    for (var testCase in widget.exercise.testCases) {
      // Kiểm tra xem code có chứa các keyword cần thiết không
      bool codeContainsKey = code.contains('void main') ||
          code.contains('main()') ||
          code.contains('print');

      if (codeContainsKey) {
        // Mô phỏng đơn giản - trong thực tế cần chạy code thực
        bool passed = _checkTestCase(code, testCase);
        results.add(passed);
        if (passed) passedTestsCount++;
      } else {
        results.add(false);
      }
    }

    final builtOutput = _buildOutputText(results, passedTestsCount);

    setState(() {
      testResults = results;
      passedTests = passedTestsCount;
      isRunning = false;
      output = builtOutput;
    });

    if (passedTests == totalTests) {
      _showSnackBar('🎉 Chúc mừng! Bạn đã hoàn thành bài tập này!',
          Colors.green);
    } else if (passedTests > 0) {
      _showSnackBar('Tốt lắm! Bạn đã pass $passedTests/$totalTests test',
          Colors.blue);
    } else {
      _showSnackBar('Chưa đúng, hãy thử lại!', Colors.red);
    }
  }

  bool _checkTestCase(String code, TestCase testCase) {
    if (!_hasExerciseSpecificLogic(code)) {
      return false;
    }

    // Đây là kiểm tra đơn giản dựa trên nội dung code
    // Trong ứng dụng thực, bạn nên:
    // 1. Gửi code tới backend
    // 2. Chạy code trên server với input: testCase.input
    // 3. So sánh output real với testCase.expectedOutput

    // Kiểm tra đơn giản cho một số bài tập cơ bản
    if (widget.exercise.id == 'ex1') {
      // Bài tập tính tổng
      try {
        int input = int.parse(testCase.input);
        int expected = int.parse(testCase.expectedOutput);
        int sum = 0;
        while (input > 0) {
          sum += input % 10;
          input ~/= 10;
        }
        return sum.toString() == testCase.expectedOutput;
      } catch (e) {
        return false;
      }
    }

    if (widget.exercise.id == 'ex2') {
      // Bài tập hình tam giác sao
      try {
        int n = int.parse(testCase.input);
        StringBuffer result = StringBuffer();
        for (int i = 1; i <= n; i++) {
          result.writeln('*' * i);
        }
        String userOutput = result.toString().trimRight();
        String expectedOutput = testCase.expectedOutput;
        return userOutput == expectedOutput;
      } catch (e) {
        return false;
      }
    }

    if (widget.exercise.id == 'ex3') {
      // Bài tập chẵn/lẻ
      try {
        int n = int.parse(testCase.input);
        String result = (n % 2 == 0) ? 'Chẵn' : 'Lẻ';
        return result == testCase.expectedOutput;
      } catch (e) {
        return false;
      }
    }

    if (widget.exercise.id == 'ex4') {
      // Bài tập tìm max
      try {
        List<String> inputLines = testCase.input.split('\\n');
        if (inputLines.length >= 3) {
          int a = int.parse(inputLines[0]);
          int b = int.parse(inputLines[1]);
          int c = int.parse(inputLines[2]);
          int max = [a, b, c].reduce((v, e) => v > e ? v : e);
          return max.toString() == testCase.expectedOutput;
        }
      } catch (e) {
        return false;
      }
    }

    if (widget.exercise.id == 'ex5') {
      // Bài tập giai thừa
      try {
        int n = int.parse(testCase.input);
        int factorial = 1;
        for (int i = 1; i <= n; i++) {
          factorial *= i;
        }
        return factorial.toString() == testCase.expectedOutput;
      } catch (e) {
        return false;
      }
    }

    // Mặc định trả về false nếu không có logic kiểm tra
    return false;
  }

  bool _hasExerciseSpecificLogic(String code) {
    final normalizedCode = code.toLowerCase();

    final hasInput = normalizedCode.contains('readlinesync');
    final hasOutput = normalizedCode.contains('print(') ||
        normalizedCode.contains('stdout.write');

    if (!hasInput || !hasOutput) {
      return false;
    }

    switch (widget.exercise.id) {
      case 'ex1':
        final hasLoop =
            normalizedCode.contains('while') || normalizedCode.contains('for');
        final hasModulo = normalizedCode.contains('% 10') ||
            normalizedCode.contains('%10');
        final hasDivide = normalizedCode.contains('~/= 10') ||
            normalizedCode.contains('~/=10') ||
            normalizedCode.contains('~/ 10') ||
            normalizedCode.contains('~/10');
        final hasSumAccumulate = normalizedCode.contains('sum +=') ||
            normalizedCode.contains('sum= sum +') ||
            normalizedCode.contains('sum = sum +');
        return hasLoop && hasModulo && hasDivide && hasSumAccumulate;

      case 'ex2':
        final hasLoop =
            normalizedCode.contains('for') || normalizedCode.contains('while');
        final hasStarOutput = normalizedCode.contains("'*' *") ||
            normalizedCode.contains('"*" *') ||
            normalizedCode.contains("stdout.write('*')") ||
            normalizedCode.contains('stdout.write("*")');
        return hasLoop && hasStarOutput;

      case 'ex3':
        final hasModulo2 = normalizedCode.contains('% 2') ||
            normalizedCode.contains('%2');
        final hasCondition =
            normalizedCode.contains('if') && normalizedCode.contains('else');
        final hasEvenOddOutput = normalizedCode.contains('chẵn') &&
            normalizedCode.contains('lẻ');
        return hasModulo2 && hasCondition && hasEvenOddOutput;

      case 'ex4':
        final hasThreeInputs = normalizedCode.contains('int a') &&
            normalizedCode.contains('int b') &&
            normalizedCode.contains('int c');
        final hasComparison = normalizedCode.contains('>') ||
            normalizedCode.contains('reduce((v, e) => v > e ? v : e)') ||
            normalizedCode.contains('math.max');
        return hasThreeInputs && hasComparison;

      case 'ex5':
        final hasLoop =
            normalizedCode.contains('for') || normalizedCode.contains('while');
        final hasFactorialAccumulate = normalizedCode.contains('*=') ||
            normalizedCode.contains('factorial = factorial *') ||
            normalizedCode.contains('result = result *');
        return hasLoop && hasFactorialAccumulate;

      default:
        return false;
    }
  }

  String _buildOutputText(List<bool> results, int passed) {
    StringBuffer sb = StringBuffer();
    sb.writeln('📊 Kết quả kiểm tra: $passed/$totalTests test passed\n');

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final test = widget.exercise.testCases[i];
      sb.writeln(result ? '✅ Test ${i + 1}: PASSED' : '❌ Test ${i + 1}: FAILED');
      sb.writeln('   Input: ${test.input}');
      sb.writeln('   Expected: ${test.expectedOutput}');
      sb.writeln('');
    }

    return sb.toString();
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCaseCard(int index, TestCase test) {
    final hasResult = index < testResults.length;
    final passed = hasResult ? testResults[index] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passed == null
              ? Colors.grey.shade300
              : (passed ? Colors.green.shade300 : Colors.red.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Test ${index + 1}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (passed != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        passed ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    passed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      fontSize: 11,
                      color: passed ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Input: ${test.input}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Output: ${test.expectedOutput}',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _showHint() {
    if (widget.exercise.hint != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gợi ý'),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.exercise.hint!,
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 380;
    final isWide = width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(widget.exercise.title),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  widget.exercise.difficulty,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = isWide ? 24.0 : 14.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      icon: Icons.description_outlined,
                      color: Colors.blue,
                      title: 'Mô tả bài tập',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAF3FF), Color(0xFFF6F9FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFD8FF)),
                      ),
                      child: Text(
                        widget.exercise.description,
                        style: const TextStyle(fontSize: 14, height: 1.55),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              label: 'Input',
                              content: widget.exercise.inputFormat,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              label: 'Output',
                              content: widget.exercise.outputFormat,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _buildInfoCard(
                        label: 'Input',
                        content: widget.exercise.inputFormat,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoCard(
                        label: 'Output',
                        content: widget.exercise.outputFormat,
                        color: Colors.deepOrange,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      icon: Icons.checklist_rounded,
                      color: Colors.orange,
                      title: 'Test Cases',
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(widget.exercise.testCases.length, (index) {
                      final test = widget.exercise.testCases[index];
                      return _buildTestCaseCard(index, test);
                    }),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      icon: Icons.code,
                      color: Colors.green,
                      title: 'Nhập code Dart của bạn',
                    ),
                    const SizedBox(height: 10),
                    CodeEditorWidget(
                      controller: codeController,
                      minLines: 9,
                      maxLines: 16,
                    ),
                    const SizedBox(height: 14),
                    if (isCompact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isRunning ? null : runCode,
                            icon: isRunning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: Text(isRunning ? 'Đang chạy...' : 'Chạy code'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _showHint,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text('Xem gợi ý'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isRunning ? null : runCode,
                              icon: isRunning
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(isRunning ? 'Đang chạy...' : 'Chạy code'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _showHint,
                            icon: const Icon(Icons.lightbulb_outline),
                            label: const Text('Gợi ý'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (output.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.terminal,
                        color: Colors.purple,
                        title: 'Kết quả chạy',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            output,
                            style: const TextStyle(
                              color: Color(0xFF86EFAC),
                              fontFamily: 'Courier',
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
