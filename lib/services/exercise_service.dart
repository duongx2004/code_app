import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:code_app/models/exercise_model.dart';

class ExerciseService {
  static Future<List<DartExercise>> loadExercises() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/exercises.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => DartExercise.fromJson(json)).toList();
    } catch (e) {
      print("Error loading exercises: $e");
      return [];
    }
  }

  static Future<DartExercise?> getExerciseById(String id) async {
    final exercises = await loadExercises();
    try {
      return exercises.firstWhere((ex) => ex.id == id);
    } catch (e) {
      return null;
    }
  }

  /// So sánh kết quả output của người dùng với expected output
  static bool compareOutput(String userOutput, String expectedOutput) {
    // Remove trailing whitespace từng dòng
    List<String> userLines = userOutput
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();

    List<String> expectedLines = expectedOutput
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList();

    return userLines.join('\n') == expectedLines.join('\n');
  }

  /// Nhân bản input để test
  static List<String> parseTestInput(String input) {
    return input.split('\\n');
  }
}
