import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/services/dart_code_runner.dart';
import 'package:code_app/services/exercise_service.dart';
import 'package:code_app/services/progress_service.dart';
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

  Future<void> runCode() async {
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

    await _executeCode(code);
  }

  Future<void> _executeCode(String code) async {
    final results = <bool>[];
    final actualOutputs = <String>[];
    var passedTestsCount = 0;
    String? runtimeError;
    var hasConnectionFailure = false;

    if (!_hasExerciseSpecificLogic(code)) {
      final failedResults = List<bool>.filled(totalTests, false);
      final builtOutput = _buildOutputText(
        failedResults,
        0,
        runtimeError: "Code chưa đủ cấu trúc. Kiểm tra: đọc input bằng stdin.readLineSync()/readLineSync() và in output bằng print()/stdout.write().",
      );

      if (!mounted) return;
      setState(() {
        testResults = failedResults;
        passedTests = 0;
        isRunning = false;
        output = builtOutput;
      });

      _showSnackBar('Chưa đúng cấu trúc bài làm, hãy thử lại!', Colors.red);
      return;
    }

    for (var testCase in widget.exercise.testCases) {
      final executionResult = await DartCodeRunner.runCode(
        code,
        input: testCase.input,
        timeout: Duration(seconds: widget.exercise.timeLimit),
      );

      if (executionResult.connectionFailed) {
        hasConnectionFailure = true;
      }

      runtimeError ??= executionResult.error ??
          (executionResult.stderr.trim().isNotEmpty
              ? executionResult.stderr.trim()
              : (executionResult.timedOut ? 'Code chạy quá thời gian cho phép.' : null));

      final userOutput = executionResult.stdout.trim();
      final passed = !executionResult.hasError &&
          ExerciseService.compareOutput(userOutput, testCase.expectedOutput);

      results.add(passed);
      actualOutputs.add(userOutput);
      if (passed) passedTestsCount++;
    }

    final builtOutput = _buildOutputText(
      results,
      passedTestsCount,
      runtimeError: runtimeError,
      actualOutputs: actualOutputs,
    );

    if (!mounted) return;
    setState(() {
      testResults = results;
      passedTests = passedTestsCount;
      isRunning = false;
      output = builtOutput;
    });

    final normalizedRuntimeError = runtimeError?.toLowerCase() ?? '';
    final hasNetworkIssue = hasConnectionFailure ||
      normalizedRuntimeError.contains('kết nối') ||
      normalizedRuntimeError.contains('mạng') ||
      normalizedRuntimeError.contains('thời gian chờ mạng');

    if (hasNetworkIssue) {
      _showSnackBar(
        'Không thể kết nối server chạy code. Kiểm tra mạng hoặc server đang chạy.',
        Colors.orange,
      );
      return;
    }

    if (passedTests == totalTests) {
      await context
          .read<ProgressService>()
          .markExerciseAsCompleted(widget.exercise.id);
      _showCompletionAndBack();
    } else if (passedTests > 0) {
      _showSnackBar('Tốt lắm! Bạn đã pass $passedTests/$totalTests test',
          Colors.blue);
    } else {
      _showSnackBar('Chưa đúng, hãy thử lại!', Colors.red);
    }
  }

  bool _hasExerciseSpecificLogic(String code) {
    final normalizedCode = code.toLowerCase();
    final compactCode = normalizedCode.replaceAll(RegExp(r'\s+'), '');

    // Đủ tiêu chí cơ bản: đọc input và in output
    final hasInput = compactCode.contains('stdin.readlinesync(') ||
        compactCode.contains('readlinesync(');
    final hasOutput = compactCode.contains('print(') ||
        compactCode.contains('stdout.write(');

    return hasInput && hasOutput;
  }

  String _buildOutputText(
    List<bool> results,
    int passed, {
    String? runtimeError,
    List<String>? actualOutputs,
  }) {
    StringBuffer sb = StringBuffer();
    sb.writeln('📊 Kết quả kiểm tra: $passed/$totalTests test passed\n');

    if (runtimeError != null && runtimeError.isNotEmpty) {
      sb.writeln('⚠️ Thông báo chạy code: $runtimeError\n');
    }

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final test = widget.exercise.testCases[i];
      sb.writeln(result ? '✅ Test ${i + 1}: PASSED' : '❌ Test ${i + 1}: FAILED');
      sb.writeln('   Input: ${test.input}');
      sb.writeln('   Expected: ${test.expectedOutput}');
      if (!result && actualOutputs != null && actualOutputs.length > i) {
        sb.writeln('   Actual: ${actualOutputs[i]}');
      }
      sb.writeln('');
    }

    return sb.toString();
  }

  Color _difficultyColor() {
    final normalized = widget.exercise.difficulty.toLowerCase();
    if (normalized.contains('trung')) {
      return const Color(0xFFEA8A1A);
    }
    if (normalized.contains('nâng')) {
      return const Color(0xFFDC2626);
    }
    return const Color(0xFF16A34A);
  }

  Widget _buildGlassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: child,
    );
  }

  Widget _buildProblemSection(bool isWide) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Mô tả bài tập',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.exercise.description,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF1F2A3D),
            ),
          ),
          const SizedBox(height: 14),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildIOMiniCard('Input', widget.exercise.inputFormat)),
                const SizedBox(width: 10),
                Expanded(child: _buildIOMiniCard('Output', widget.exercise.outputFormat)),
              ],
            )
          else ...[
            _buildIOMiniCard('Input', widget.exercise.inputFormat),
            const SizedBox(height: 8),
            _buildIOMiniCard('Output', widget.exercise.outputFormat),
          ],
        ],
      ),
    );
  }

  Widget _buildIOMiniCard(String label, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF31518D),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF24334D)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorSection() {
    return _buildGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.code_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Code của bạn',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF253A55)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B1120).withValues(alpha: 0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final color in const [
                      Color(0xFFEF4444),
                      Color(0xFFF59E0B),
                      Color(0xFF10B981),
                    ])
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    const Spacer(),
                    const Text(
                      'main.dart',
                      style: TextStyle(
                        color: Color(0xFF9EB7D6),
                        fontSize: 11,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CodeEditorWidget(
                  controller: codeController,
                  minLines: 10,
                  maxLines: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final passRateText = '$passedTests/$totalTests Passed';
    final allPassed = passedTests == totalTests && totalTests > 0;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allPassed ? Icons.verified_rounded : Icons.query_stats_rounded,
                color: allPassed ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                size: 19,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kết quả chạy',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: allPassed
                      ? const Color(0xFFE8F8EE)
                      : const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  passRateText,
                  style: TextStyle(
                    color: allPassed ? const Color(0xFF15803D) : const Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF122033),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                output,
                style: const TextStyle(
                  color: Color(0xFFCFF4D2),
                  fontFamily: 'Courier',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Test case',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.exercise.testCases.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTestCaseRow(index, widget.exercise.testCases[index]),
            );
          }),
          if (allPassed)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFE8CC)),
              ),
              child: const Row(
                children: [
                  Text('🎉', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đã hoàn thành bài này!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestCaseRow(int index, TestCase test) {
    final hasResult = index < testResults.length;
    final isPassed = hasResult ? testResults[index] : null;

    final borderColor = isPassed == null
        ? const Color(0xFFDCE3F1)
        : (isPassed ? const Color(0xFF9AD7AF) : const Color(0xFFF2A5A5));

    final statusIcon = isPassed == null
        ? Icons.radio_button_unchecked_rounded
        : (isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded);

    final statusColor = isPassed == null
        ? const Color(0xFF64748B)
        : (isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Input: ${test.input}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Expected: ${test.expectedOutput}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F3))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4338CA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isRunning ? null : runCode,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRunning)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else
                            const Icon(Icons.play_arrow_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isRunning ? 'Đang chạy...' : 'Chạy code',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              height: 50,
              child: OutlinedButton(
                onPressed: _showHint,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD3DDEF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, size: 22),
              ),
            ),
          ],
        ),
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

  void _showCompletionAndBack() {
    _showSnackBar('🎉 Hoàn thành bài tập! Đang quay về danh sách...', Colors.green);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;
    final difficultyColor = _difficultyColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF6F8FC),
        leadingWidth: 46,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          widget.exercise.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: difficultyColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  widget.exercise.difficulty,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: difficultyColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyActionBar(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(isWide ? 24 : 14, 14, isWide ? 24 : 14, 96),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProblemSection(isWide),
                    const SizedBox(height: 18),
                    _buildEditorSection(),
                    const SizedBox(height: 18),
                    if (output.isNotEmpty)
                      _buildResultSection()
                    else
                      _buildGlassCard(
                        child: const Row(
                          children: [
                            Icon(Icons.play_circle_outline_rounded, color: Color(0xFF2563EB)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Nhấn "Chạy code" để kiểm tra kết quả và trạng thái test case.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
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
}
