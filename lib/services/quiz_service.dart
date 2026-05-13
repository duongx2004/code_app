import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:code_app/models/models.dart';
import 'package:code_app/services/backend_api.dart';

class QuizService {
  static Future<List<Quiz>> fetchQuizzes() async {
    try {
      // Try to fetch from API first
      final response = await BackendApi.get('/api/quizzes');
      final quizzesJson = response['quizzes'] as List<dynamic>? ?? [];
      if (quizzesJson.isNotEmpty) {
        return quizzesJson
            .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If API fails, fall back to local data
      print('API failed, loading local quiz data: $e');
    }

    // Load from local JSON file as fallback
    try {
      final jsonString = await rootBundle.loadString('assets/data/quizzes.json');
      final quizzesJson = json.decode(jsonString) as List<dynamic>;
      return quizzesJson
          .map((json) => Quiz.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to load local quiz data: $e');
      return [];
    }
  }

  static Future<bool> createQuiz(String title, String description, List<Question> questions) async {
    final quiz = Quiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      difficulty: '',
      questions: questions,
    );
    final response = await BackendApi.post('/api/quizzes', quiz.toMap());
    return response['success'] == true;
  }

  static Future<bool> updateQuiz(String id, String title, String description, List<Question> questions) async {
    final quiz = Quiz(
      id: id,
      title: title,
      description: description,
      difficulty: '',
      questions: questions,
    );
    final response = await BackendApi.put('/api/quizzes/$id', quiz.toMap());
    return response['success'] == true;
  }

  static Future<bool> deleteQuiz(String id) async {
    final response = await BackendApi.delete('/api/quizzes/$id');
    return response['success'] == true;
  }
}