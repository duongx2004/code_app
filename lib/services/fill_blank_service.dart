import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:code_app/models/fill_blank_model.dart';
import 'package:code_app/services/backend_api.dart';
import 'package:code_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class FillBlankService {
  static Future<List<Map<String, dynamic>>> loadExercises() async {
    try {
      // Try to fetch from API first
      final response = await BackendApi.get('/api/fill-blank/exercises');
      final exercisesJson = response['exercises'] as List<dynamic>? ?? [];
      if (exercisesJson.isNotEmpty) {
        return exercisesJson.map((json) => json as Map<String, dynamic>).toList();
      }
    } catch (e) {
      // If API fails, fall back to local data
      debugPrint("API failed, loading local fill blank data: $e");
    }

    // Load from local JSON file as fallback
    try {
      final jsonString = await rootBundle.loadString('assets/data/fill_blank_exercises.json');
      final exercisesJson = json.decode(jsonString) as List<dynamic>;
      return exercisesJson.map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint("Failed to load local fill blank data: $e");
      return [];
    }
  }

  static Future<FillBlankExercise?> getExerciseById(String id) async {
    try {
      final response = await BackendApi.get('/api/fill-blank/exercises/$id');
      final exerciseJson = response['exercise'] as Map<String, dynamic>?;
      if (exerciseJson == null) return null;
      return FillBlankExercise.fromJson(exerciseJson);
    } catch (e) {
      debugPrint("Error loading fill blank exercise by id: $e");
      return null;
    }
  }

  static Future<FillBlankResult?> checkAnswers(String exerciseId, List<String> answers) async {
    try {
      final userEmail = await AuthService().getCurrentUserEmail();
      if (userEmail == null) return null;

      final response = await BackendApi.post('/api/fill-blank/check', {
        'exerciseId': exerciseId,
        'userEmail': userEmail,
        'answers': answers,
      });

      return FillBlankResult.fromJson(response);
    } catch (e) {
      debugPrint("Error checking fill blank answers: $e");
      return null;
    }
  }

  // Admin functions
  static Future<bool> createExercise({
    required String id,
    required String title,
    required String content,
    required String difficulty,
    String? hint,
    required List<Map<String, dynamic>> blanks,
  }) async {
    try {
      await BackendApi.post('/api/admin/fill-blank', {
        'id': id,
        'title': title,
        'content': content,
        'difficulty': difficulty,
        'hint': hint,
        'blanks': blanks,
      });
      return true;
    } catch (e) {
      debugPrint("Error creating fill blank exercise: $e");
      return false;
    }
  }

  static Future<bool> updateExercise({
    required String id,
    required String title,
    required String content,
    required String difficulty,
    String? hint,
    required List<Map<String, dynamic>> blanks,
  }) async {
    try {
      await BackendApi.put('/api/admin/fill-blank/$id', {
        'title': title,
        'content': content,
        'difficulty': difficulty,
        'hint': hint,
        'blanks': blanks,
      });
      return true;
    } catch (e) {
      debugPrint("Error updating fill blank exercise: $e");
      return false;
    }
  }

  static Future<bool> deleteExercise(String id) async {
    try {
      await BackendApi.delete('/api/admin/fill-blank/$id');
      return true;
    } catch (e) {
      debugPrint("Error deleting fill blank exercise: $e");
      return false;
    }
  }
}