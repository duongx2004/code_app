import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/models/models.dart';
import 'package:code_app/services/data_service.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/screens/lesson_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình học Dart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context, progressService),
          )
        ],
      ),
      // PHẦN THIẾU CỦA BẠN NẰM Ở ĐÂY:
      body: FutureBuilder<List<Lesson>>(
        future: DataService.loadLessons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Không tìm thấy bài học nào.\nKiểm tra lại file JSON và assets!"),
            );
          }

          final lessons = snapshot.data!;
          double overallProgress = progressService.getProgress(lessons.length);

          return Column(
            children: [
              // Gọi hàm vẽ thanh tiến độ
              _buildProgressHeader(overallProgress),

              // Hiển thị danh sách bài học
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    bool isDone = progressService.completedLessonIds.contains(lesson.id);
                    return _buildLessonCard(context, lesson, isDone);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Hàm hiển thị Dialog xác nhận xóa tiến độ
  void _showResetDialog(BuildContext context, ProgressService progressService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa tiến độ?"),
        content: const Text("Tất cả bài học sẽ được đánh dấu là chưa hoàn thành."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              progressService.resetProgress();
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tiến độ tổng quát", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(progress * 100).toInt()}%"),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, bool isDone) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDone ? 1 : 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDone ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
          child: Icon(
            isDone ? Icons.check : Icons.play_lesson_outlined,
            color: isDone ? Colors.green : Colors.blue,
          ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
            color: isDone ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(isDone ? "Đã hoàn thành" : "Chưa học"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: lesson)),
        ),
      ),
    );
  }
}