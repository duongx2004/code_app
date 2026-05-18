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
            onPressed: () {
              Navigator.of(context).pop();
              if (result.completed) {
                // Go back to the list screen when exercise completed
                Navigator.of(context).pop();
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, {List<Widget> actions = const []}) {
    return AppBar(
      leading: const BackButton(color: Colors.white),
      title: Text(title),
      backgroundColor: Colors.white,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar('Bài tập điền chỗ trống'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: _buildAppBar('Bài tập điền chỗ trống'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $_error'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: _loadExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final exercise = _exercise!;
    return Scaffold(
      appBar: _buildAppBar(
        exercise.title,
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
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Container(
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
                            _getDifficultyIcon(exercise.difficulty),
                            color: _getDifficultyColor(exercise.difficulty),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Độ khó: ${exercise.difficulty}',
                            style: TextStyle(
                              color: _getDifficultyColor(exercise.difficulty),
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
                              'Chỗ trống: ${exercise.blanks.length}',
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
                        exercise.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            exercise.content,
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
              const SizedBox(height: 24),
              const Text(
                'Điền vào chỗ trống',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(exercise.blanks.length, (index) {
                final blank = exercise.blanks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Chỗ trống',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        if (blank.hint != null && blank.hint!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Gợi ý: ${blank.hint}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _controllers[index],
                          decoration: InputDecoration(
                            labelText: 'Câu trả lời ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkAnswers,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isChecking
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Kiểm tra đáp án',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
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