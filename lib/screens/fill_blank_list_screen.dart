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
    return _exercises.where((exercise) => exercise['difficulty'] == selectedDifficulty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);
    final completedCount = _exercises.where((e) => progressService.isFillBlankCompleted(e['id'])).length;

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
        child: Column(
          children: [
            // Header with progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Điền vào chỗ trống',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProgressCard(
                    completed: completedCount,
                    total: _exercises.length,
                    message: completedCount == _exercises.length
                        ? '🎉 Chúc mừng! Bạn đã hoàn thành tất cả bài tập điền chỗ trống!'
                        : '💪 Tiếp tục cố gắng để hoàn thành khóa học!',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Filter bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
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
                  FilterChips(
                    options: ['Tất cả', 'Cơ bản', 'Trung bình', 'Nâng cao'],
                    selected: selectedDifficulty,
                    onSelected: (difficulty) => setState(() => selectedDifficulty = difficulty),
                  ),
                ],
              ),
            ),

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
    );
  }
}