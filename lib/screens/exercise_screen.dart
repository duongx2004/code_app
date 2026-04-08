import 'package:flutter/material.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/screens/exercise_detail_screen.dart';
import 'package:code_app/services/exercise_service.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'cơ bản':
        return Colors.green;
      case 'trung bình':
        return Colors.orange;
      case 'nâng cao':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài tập Dart'),
        elevation: 0,
      ),
      body: FutureBuilder<List<DartExercise>>(
        future: ExerciseService.loadExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Không tìm thấy bài tập nào"),
            );
          }

          final exercises = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(context, exercise);
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, DartExercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          exercise.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              exercise.description.split('\n').first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(exercise.difficulty),
              backgroundColor: _getDifficultyColor(exercise.difficulty),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ExerciseDetailScreen(exercise: exercise),
            ),
          );
        },
      ),
    );
  }
}
