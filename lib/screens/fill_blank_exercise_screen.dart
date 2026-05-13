import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/models/fill_blank_model.dart';
import 'package:code_app/services/fill_blank_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/widgets/custom_card.dart';

class FillBlankExerciseScreen extends StatefulWidget {
  final String exerciseId;

  const FillBlankExerciseScreen({
    super.key,
    required this.exerciseId,
  });

  @override
  State<FillBlankExerciseScreen> createState() => _FillBlankExerciseScreenState();
}

class _FillBlankExerciseScreenState extends State<FillBlankExerciseScreen> {
  FillBlankExercise? _exercise;
  bool _isLoading = true;
  String? _error;
  List<TextEditingController> _controllers = [];
  FillBlankResult? _result;
  bool _isChecking = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exercise = await FillBlankService.getExerciseById(widget.exerciseId);
      if (exercise != null) {
        setState(() {
          _exercise = exercise;
          _controllers = List.generate(
            exercise.blanks.length,
            (index) => TextEditingController(),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Không tìm thấy bài tập';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAnswers() async {
    if (_exercise == null) return;

    setState(() => _isChecking = true);

    try {
      final answers = _controllers.map((c) => c.text.trim()).toList();
      final result = await FillBlankService.checkAnswers(_exercise!.id, answers);

      if (result != null) {
        setState(() {
          _result = result;
          _isChecking = false;
        });

        if (result.completed && !_isCompleted) {
          await _markAsCompleted();
        }

        _showResultDialog(result);
      } else {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi kiểm tra câu trả lời')),
        );
      }
    } catch (e) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _markAsCompleted() async {
    try {
      await Provider.of<ProgressService>(context, listen: false)
          .markFillBlankAsCompleted(_exercise!.id);
      setState(() => _isCompleted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu tiến độ: $e')),
      );
    }
  }

  void _showResultDialog(FillBlankResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.completed ? 'Chúc mừng! 🎉' : 'Cố gắng hơn nhé! 💪',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Điểm: ${result.score}/${result.totalBlanks}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              result.completed
                  ? 'Bạn đã hoàn thành bài tập thành công!'
                  : 'Hãy kiểm tra lại các câu trả lời.',
            ),
            if (!result.completed) ...[
              const SizedBox(height: 16),
              const Text(
                'Các câu trả lời sai:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...result.results.where((r) => !r.isCorrect).map((r) => Text(
                'Câu ${r.blankIndex + 1}: Đáp án đúng là "${r.correctAnswers.join(", ")}"',
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bài tập điền chỗ trống'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bài tập điền chỗ trống'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExercise,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final exercise = _exercise!;
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isCompleted)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise description
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Độ khó: ${exercise.difficulty}',
                      style: TextStyle(
                        color: _getDifficultyColor(exercise.difficulty),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(exercise.content),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fill in the blanks
            const Text(
              'Điền vào chỗ trống:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(exercise.blanks.length, (index) {
              final blank = exercise.blanks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (blank.hint != null && blank.hint!.isNotEmpty)
                      Text(
                        'Gợi ý: ${blank.hint}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        labelText: 'Câu trả lời ${index + 1}',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkAnswers,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isChecking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kiểm tra đáp án',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),

            // Result display
            if (_result != null) ...[
              const SizedBox(height: 24),
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kết quả: ${_result!.score}/${_result!.totalBlanks}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _result!.completed ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.completed
                            ? 'Tất cả câu trả lời đều đúng!'
                            : 'Một số câu trả lời cần sửa.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
}