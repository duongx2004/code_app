import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/models/models.dart';
import 'package:code_app/services/data_service.dart'; // Mới
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/screens/lesson_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final progressService = Provider.of<ProgressService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Lộ trình học Dart')),
      body: FutureBuilder<List<Lesson>>(
        future: DataService.loadLessons(), // Gọi hàm load file JSON
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Lỗi khi tải dữ liệu!"));
          }

          final lessons = snapshot.data!;
          double overallProgress = progressService.getProgress(lessons.length);

          return Column(
            children: [
              // Thanh tiến độ (giữ nguyên logic cũ nhưng dùng lessons.length mới)
              _buildProgressHeader(overallProgress),

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

  // Tách Widget nhỏ cho sạch code
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
          LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(5)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, bool isDone) {
    return Card(
      child: ListTile(
        leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : Colors.grey),
        title: Text(lesson.title),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LessonDetailScreen(lesson: lesson))),
      ),
    );
  }
}