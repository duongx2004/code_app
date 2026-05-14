import 'package:flutter/material.dart';
import 'package:code_app/services/fill_blank_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/screens/fill_blank_exercise_screen.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/widgets/common_widgets.dart';
import 'package:provider/provider.dart';

class FillBlankListScreen extends StatefulWidget {
  const FillBlankListScreen({super.key});

  @override
  State<FillBlankListScreen> createState() => _FillBlankListScreenState();
}

class _FillBlankListScreenState extends State<FillBlankListScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = true;
  String? _error;
  String selectedDifficulty = 'Tất cả';
  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exercises = await FillBlankService.loadExercises();
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tiến độ'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ tiến độ bài tập điền chỗ trống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<ProgressService>(context, listen: false).resetFillBlankProgress();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tiến độ')),
        );
        setState(() {}); // Refresh to update completion status
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredExercises {
    if (selectedDifficulty == 'Tất cả') {
      return _exercises;
    }
    return _exercises.where((exercise) =>
      exercise['difficulty']?.toString().toLowerCase() == selectedDifficulty.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);
    final completedCount = _exercises.where((e) => progressService.isFillBlankCompleted(e['id'])).length;
    final totalCount = _exercises.length;
    final progressValue = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Điền vào chỗ trống'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, color: AppTheme.primaryColor),
            onPressed: _clearProgress,
            tooltip: 'Xóa tiến độ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExercises,
          ),
        ],
      ),
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
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Điền vào chỗ trống',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completedCount/$totalCount',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progressValue,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    completedCount == totalCount && totalCount > 0
                        ? '🎉 Chúc mừng! Bạn đã hoàn thành tất cả bài tập điền chỗ trống!'
                        : '💪 Tiếp tục cố gắng để hoàn thành khóa học!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Filter bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Độ khó',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: ['Tất cả', 'Cơ bản', 'Trung bình', 'Nâng cao']
                          .map(
                            (option) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: ChoiceChip(
                                  label: Center(
                                    child: Text(
                                      option,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: selectedDifficulty == option
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selectedDifficulty == option
                                            ? Colors.white
                                            : AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  selected: selectedDifficulty == option,
                                  showCheckmark: false,
                                  selectedColor: AppTheme.primaryColor,
                                  backgroundColor: Colors.transparent,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onSelected: (_) =>
                                      setState(() => selectedDifficulty = option),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Exercises list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 64, color: Colors.red[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Lỗi: $_error',
                                style: TextStyle(color: AppTheme.textSecondaryLight),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.buttonGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ElevatedButton(
                                  onPressed: _loadExercises,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Thử lại',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredExercises.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Không tìm thấy bài tập nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thử thay đổi bộ lọc độ khó',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 16),
                              itemCount: _filteredExercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _filteredExercises[index];
                                final isCompleted = progressService.isFillBlankCompleted(exercise['id']);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ExerciseCard(
                                    title: exercise['title'] ?? '',
                                    description: exercise['description'] ?? '',
                                    difficulty: exercise['difficulty'] ?? '',
                                    completedCount: 0, // Mock data
                                    isCompleted: isCompleted,
                                    isSpecial: index == 0,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FillBlankExerciseScreen(
                                            exerciseId: exercise['id'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
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
}