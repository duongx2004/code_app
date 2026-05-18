import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/models/models.dart';
import 'package:code_app/services/data_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/screens/lesson_detail_screen.dart';
import 'package:code_app/widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.school, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trang chủ',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.lightBackground,
        child: FutureBuilder<List<Lesson>>(
          future: DataService.loadLessons(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.textSecondaryLight),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.buttonGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: () => setState(() {}),
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
              );
            }

            final lessons = snapshot.data ?? [];
            final completedCount = progressService.completedLessonIds.length;
            final quizCompletedCount = progressService.getCompletedQuizCount();

            return Column(
              children: [
                // Progress header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 420;

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lộ trình học',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                                          onPressed: () => setState(() {}),
                                          tooltip: 'Tải lại',
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_sweep, color: AppTheme.primaryColor, size: 20),
                                          onPressed: () => _clearLearningProgress(progressService),
                                          tooltip: 'Xóa tiến độ lộ trình học',
                                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                          padding: const EdgeInsets.all(6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Lộ trình học',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 110),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.refresh, color: AppTheme.primaryColor, size: 20),
                                        onPressed: () => setState(() {}),
                                        tooltip: 'Tải lại',
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        padding: const EdgeInsets.all(6),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_sweep, color: AppTheme.primaryColor, size: 20),
                                        onPressed: () => _clearLearningProgress(progressService),
                                        tooltip: 'Xóa tiến độ lộ trình học',
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        padding: const EdgeInsets.all(6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ProgressCard(
                        completed: completedCount,
                        total: lessons.length,
                        message: completedCount == lessons.length
                            ? 'Chúc mừng! Bạn đã hoàn thành lộ trình học!'
                            : 'Tiếp tục cố gắng để hoàn thành khóa học!',
                      ),
                      if (quizCompletedCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.quiz,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Đã hoàn thành $quizCompletedCount bài trắc nghiệm',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Lessons list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return FutureBuilder<bool>(
                        future: Future.value(progressService.isCompleted(lesson.id)),
                        builder: (context, completionSnapshot) {
                          final isCompleted = completionSnapshot.data ?? false;

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
                                      builder: (context) => LessonDetailScreen(lesson: lesson),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isCompact = constraints.maxWidth < 420;

                                      final leading = Container(
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
                                          isCompleted ? Icons.check : Icons.book,
                                          color: Colors.white,
                                        ),
                                      );

                                      final titleRow = Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lesson.title,
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
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      );

                                      final quizTag = lesson.quiz.isNotEmpty
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${lesson.quiz.length} câu trắc nghiệm',
                                                style: TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink();

                                      if (isCompact) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                leading,
                                                const SizedBox(width: 12),
                                                Expanded(child: titleRow),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              lesson.content.length > 100
                                                  ? '${lesson.content.substring(0, 100)}...'
                                                  : lesson.content,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondaryLight,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            if (lesson.quiz.isNotEmpty) quizTag,
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                color: AppTheme.primaryColor,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return Row(
                                        children: [
                                          leading,
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                titleRow,
                                                const SizedBox(height: 4),
                                                Text(
                                                  lesson.content.length > 100
                                                      ? '${lesson.content.substring(0, 100)}...'
                                                      : lesson.content,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppTheme.textSecondaryLight,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (lesson.quiz.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  quizTag,
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppTheme.primaryColor,
                                            size: 16,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _clearLearningProgress(ProgressService progressService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurfaceColor(context),
        title: Text(
          'Xóa tiến độ lộ trình học',
          style: TextStyle(color: AppTheme.getTextPrimaryColor(context)),
        ),
        content: Text(
          'Bạn có chắc muốn xóa tiến độ lộ trình học không? Hành động này không thể hoàn tác.',
          style: TextStyle(color: AppTheme.getTextSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await progressService.resetProgress();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tiến độ lộ trình học')),
      );
      setState(() {}); // Refresh UI
    }
  }
}