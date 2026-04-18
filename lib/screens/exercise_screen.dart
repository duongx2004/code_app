import 'package:flutter/material.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/screens/exercise_detail_screen.dart';
import 'package:code_app/services/exercise_service.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  // Hàm hỗ trợ lấy màu sắc theo độ khó
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'cơ bản':
        return const Color(0xFF10B981); // Emerald Green
      case 'trung bình':
        return const Color(0xFFF59E0B); // Amber Orange
      case 'nâng cao':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thử thách Code Dart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<DartExercise>>(
        future: ExerciseService.loadExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code_off_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("Chưa có bài tập nào khả dụng", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(context, exercise, index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, DartExercise exercise, int order) {
    final diffColor = _getDifficultyColor(exercise.difficulty);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ExerciseDetailScreen(exercise: exercise),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon trang trí đại diện cho bài tập
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.terminal_rounded, color: diffColor, size: 26),
                ),
                const SizedBox(width: 16),
                // Nội dung bài tập
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.description.split('\n').first,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey[400], height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      // Badge hiển thị độ khó
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: diffColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: diffColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          exercise.difficulty.toUpperCase(),
                          style: TextStyle(
                            color: diffColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Center(
                  child: Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
