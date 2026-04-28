import 'package:flutter/foundation.dart';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/services/backend_api.dart';

class ExerciseService {
  static Future<List<DartExercise>> loadExercises() async {
    try {
      final response = await BackendApi.get('/api/exercises');
      final exercisesJson = response['exercises'] as List<dynamic>? ?? [];
      return exercisesJson
          .map((json) => DartExercise.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error loading exercises from backend: $e");
      return [];
    }
  }

  static Future<DartExercise?> getExerciseById(String id) async {
    try {
      final response = await BackendApi.get('/api/exercises/$id');
      final exerciseJson = response['exercise'] as Map<String, dynamic>?;
      if (exerciseJson == null) return null;
      return DartExercise.fromJson(exerciseJson);
    } catch (e) {
      debugPrint("Error loading exercise by id: $e");
      return null;
    }
  }

  /// So sánh kết quả output của người dùng với expected output
  static bool compareOutput(String userOutput, String expectedOutput) {
    String normalize(String value) {
      return value
          .replaceAll('\r', '')
          .split('\n')
          .map((line) => line.trimRight())
          .join('\n')
          .trimRight();
    }

    return normalize(userOutput) == normalize(expectedOutput);
  }

  /// Nhân bản input để test
  static List<String> parseTestInput(String input) {
    return input.split('\\n');
  }
}
