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
      }
    }

    setState(() {
      testResults = results;
      passedTests = passedTestsCount;
      isRunning = false;
      _buildOutput();
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

  void _buildOutput() {
    StringBuffer sb = StringBuffer();
    sb.writeln('📊 Kết quả kiểm tra: $passedTests/$totalTests test passed\n');

    for (int i = 0; i < testResults.length; i++) {
      final result = testResults[i];
      final test = widget.exercise.testCases[i];
      sb.writeln(result ? '✅ Test ${i + 1}: PASSED' : '❌ Test ${i + 1}: FAILED');
      sb.writeln('   Input: ${test.input}');
      sb.writeln('   Expected: ${test.expectedOutput}');
      sb.writeln('');
    }

    setState(() {
      output = sb.toString();
    });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mô tả bài tập
            const Row(
              children: [
                Icon(Icons.description, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Mô tả bài tập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Text(
                widget.exercise.description,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),

            // Input/Output
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Input',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.inputFormat,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Output',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.outputFormat,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Test cases
            const Row(
              children: [
                Icon(Icons.checklist, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Test Cases',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(widget.exercise.testCases.length, (index) {
              final test = widget.exercise.testCases[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test ${index + 1}:',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text('Input: ${test.input}', style: const TextStyle(fontSize: 11)),
                    Text('Output: ${test.expectedOutput}',
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Code editor
            const Row(
              children: [
                Icon(Icons.code, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Nhập code Dart của bạn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: codeController,
                maxLines: 12,
                minLines: 8,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'void main() {\n  // Viết code của bạn ở đây\n}',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Buttons
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
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Gợi ý'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Output
            if (output.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    output,
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
