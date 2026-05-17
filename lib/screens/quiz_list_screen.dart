import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/models/models.dart';
import 'package:code_app/screens/quiz_detail_screen.dart';
import 'package:code_app/services/quiz_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/services/theme_controller.dart';
import 'package:code_app/widgets/common_widgets.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<Quiz> quizzes = [];
  List<Quiz> filteredQuizzes = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String _selectedDifficulty = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _searchController.addListener(_applyQuizFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => isLoading = true);
    try {
      final loaded = await QuizService.fetchQuizzes();
      setState(() {
        quizzes = loaded;
        isLoading = false;
      });
      _applyQuizFilters();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải quiz: $e')),
        );
      }
    }
  }

  void _applyQuizFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredQuizzes = quizzes.where((quiz) {
        final matchesSearch = quiz.title.toLowerCase().contains(query) ||
            quiz.description.toLowerCase().contains(query);
        if (!matchesSearch) return false;
        if (_selectedDifficulty == 'Tất cả') return true;
        final d = quiz.difficulty.trim().toLowerCase();
        if (d.isEmpty) return false;
        return d == _selectedDifficulty.toLowerCase();
      }).toList();
    });
  }

  void _onDifficultyChanged(String value) {
    _selectedDifficulty = value;
    _applyQuizFilters();
  }

  Future<void> _clearProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tiến độ'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ tiến độ bài tập trắc nghiệm?'),
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
        await Provider.of<ProgressService>(context, listen: false).resetQuizProgress();
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
    final completedCount = quizzes.where((q) => progressService.isQuizCompleted(q.id)).length;
    final totalCount = quizzes.length;
    final progressValue = totalCount > 0 ? completedCount / totalCount : 0.0;

    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.quiz, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trắc nghiệm',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            tooltip: isDarkMode ? 'Chuyển sang giao diện sáng' : 'Chuyển sang giao diện tối',
            onPressed: () => themeController.toggleTheme(isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Xóa tiến độ trắc nghiệm',
            onPressed: _clearProgress,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadQuizzes,
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
              AppTheme.getBackgroundColor(context),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 400, maxWidth: 980),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 6,
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
                          Icons.quiz,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Trắc nghiệm',
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
                        ? '🎉 Chúc mừng! Bạn đã hoàn thành tất cả bài trắc nghiệm!'
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

            // Search and filters
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(10),
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
                    hintText: 'Tìm kiếm bài trắc nghiệm...',
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Độ khó',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilterChips(
                    options: const ['Tất cả', 'Cơ bản', 'Trung bình', 'Nâng cao'],
                    selected: _selectedDifficulty,
                    onSelected: _onDifficultyChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Quizzes list
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : filteredQuizzes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy bài trắc nghiệm nào',
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
                            itemCount: filteredQuizzes.length,
                            itemBuilder: (context, index) {
                              final quiz = filteredQuizzes[index];
                              final isCompleted = progressService.isQuizCompleted(quiz.id);
                              return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => QuizDetailScreen(quiz: quiz),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: isCompleted
                                                    ? const LinearGradient(
                                                        colors: [Colors.green, Colors.lightGreen],
                                                      )
                                                    : AppTheme.primaryGradient,
                                              ),
                                              child: Icon(
                                                isCompleted ? Icons.check : Icons.quiz,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          quiz.title,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: isCompleted
                                                                ? AppTheme.textSecondaryLight
                                                                : AppTheme.textPrimaryLight,
                                                            decoration: isCompleted
                                                                ? TextDecoration.lineThrough
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    quiz.description,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondaryLight,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.question_answer,
                                                        color: AppTheme.primaryColor,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${quiz.questions.length} câu hỏi',
                                                        style: TextStyle(
                                                          color: AppTheme.textSecondaryLight,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      if (isCompleted) ...[
                                                        const SizedBox(width: 12),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: const Text(
                                                            'Hoàn thành',
                                                            style: TextStyle(
                                                              color: Colors.green,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: AppTheme.primaryColor,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                            },
                          ),
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