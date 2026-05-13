import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/screens/exercise_detail_screen.dart';
import 'package:code_app/services/exercise_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/widgets/common_widgets.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<DartExercise> exercises = [];
  List<DartExercise> filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  String selectedDifficulty = 'Tất cả';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    try {
      final loaded = await ExerciseService.loadExercises();
      setState(() {
        exercises = loaded;
        filteredExercises = loaded;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải bài tập: $e')),
      );
    }
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredExercises = exercises.where((exercise) {
        final matchesSearch = exercise.title.toLowerCase().contains(query) ||
                             exercise.description.toLowerCase().contains(query);
        final matchesDifficulty = selectedDifficulty == 'Tất cả' ||
                                 exercise.difficulty == selectedDifficulty;
        return matchesSearch && matchesDifficulty;
      }).toList();
    });
  }

  void _onDifficultyChanged(String difficulty) {
    setState(() => selectedDifficulty = difficulty);
    _filterExercises();
  }

  Future<void> _clearProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tiến độ'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ tiến độ bài tập code?'),
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
        await Provider.of<ProgressService>(context, listen: false).resetExerciseProgress();
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

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);
    final completedCount = exercises.where((e) => progressService.isExerciseCompleted(e.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.code, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Bài tập'),
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
                          Icons.code,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Bài tập lập trình',
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
                    total: exercises.length,
                    message: completedCount == exercises.length
                        ? '🎉 Chúc mừng! Bạn đã hoàn thành tất cả bài tập!'
                        : '💪 Tiếp tục cố gắng để hoàn thành khóa học!',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Search and filters
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
                  CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Tìm kiếm bài tập...',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Độ khó',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChips(
                    options: ['Tất cả', 'Cơ bản', 'Trung bình', 'Nâng cao'],
                    selected: selectedDifficulty,
                    onSelected: _onDifficultyChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Exercises list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : filteredExercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
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
                                  'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
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
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];
                              final isCompleted = progressService.isExerciseCompleted(exercise.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExerciseCard(
                                  title: exercise.title,
                                  description: exercise.description,
                                  difficulty: exercise.difficulty,
                                  completedCount: 0, // Mock data - in real app this would be from service
                                  isCompleted: isCompleted,
                                  isSpecial: index == 0, // First exercise is special
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(exercise: exercise),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}