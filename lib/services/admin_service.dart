import 'dart:convert';
import 'package:code_app/models/exercise_model.dart';
import 'package:code_app/models/lesson_model.dart';
import 'package:code_app/services/backend_api.dart';

class AdminService {
  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await BackendApi.get('/api/users');
    final users = response['users'] as List<dynamic>? ?? [];
    return users.cast<Map<String, dynamic>>();
  }

  static Future<bool> createUser(String email, String password, String displayName, {bool isAdmin = false}) async {
    final response = await BackendApi.post('/api/users', {
      'email': email,
      'password': password,
      'display_name': displayName,
      'is_admin': isAdmin,
    });
    return response['success'] == true;
  }

  static Future<bool> deleteUser(String email) async {
    final response = await BackendApi.delete('/api/users/${Uri.encodeComponent(email)}');
    return response['success'] == true;
  }

  static Future<bool> updateUser(String email, String displayName, bool isAdmin, {String? password}) async {
    final data = {
      'display_name': displayName,
      'is_admin': isAdmin,
    };
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    final response = await BackendApi.put('/api/users/${Uri.encodeComponent(email)}', data);
    return response['success'] == true;
  }

  static Future<List<Lesson>> fetchLessons() async {
    final response = await BackendApi.get('/api/lessons');
    final lessonsJson = response['lessons'] as List<dynamic>? ?? [];
    return lessonsJson
        .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> deleteLesson(String id) async {
    final response = await BackendApi.delete('/api/lessons/$id');
    return response['success'] == true;
  }

  static Future<String?> createLesson(Lesson lesson) async {
    final response = await BackendApi.post('/api/lessons', lesson.toMap());
    if (response['success'] == true) {
      return lesson.id;
    }
    return null;
  }

  static Future<bool> updateLesson(String id, Lesson lesson) async {
    final response = await BackendApi.put('/api/lessons/$id', lesson.toMap());
    return response['success'] == true;
  }

  static Future<List<DartExercise>> fetchExercises() async {
    final response = await BackendApi.get('/api/exercises');
    final exercises = response['exercises'] as List<dynamic>? ?? [];
    return exercises
        .map((json) => DartExercise.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> deleteExercise(String id) async {
    final response = await BackendApi.delete('/api/exercises/$id');
    return response['success'] == true;
  }

  static Future<bool> createExercise(String title, String description, String difficulty, String inputFormat, String outputFormat, String testCasesJson, {String? hint, int timeLimit = 30}) async {
    List<TestCase> testCases = [];
    try {
      final testCasesList = json.decode(testCasesJson) as List;
      testCases = testCasesList.map((tc) => TestCase.fromJson(tc as Map<String, dynamic>)).toList();
    } catch (e) {
      // If parsing fails, use empty list
    }

    final response = await BackendApi.post('/api/exercises', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'input': inputFormat,
      'output': outputFormat,
      'difficulty': difficulty,
      'hint': hint,
      'time_limit': timeLimit,
      'test_cases': testCases.map((tc) => tc.toMap()).toList(),
    });
    return response['success'] == true;
  }

  static Future<bool> updateExercise(String id, DartExercise exercise) async {
    final response = await BackendApi.put('/api/exercises/$id', {
      ...exercise.toMap(),
      'test_cases': exercise.testCases.map((tc) => tc.toMap()).toList(),
    });
    return response['success'] == true;
  }

  static Future<List<Map<String, dynamic>>> fetchFillBlankExercises() async {
    final response = await BackendApi.get('/api/fill-blank/exercises');
    final exercises = response['exercises'] as List<dynamic>? ?? [];
    return exercises.cast<Map<String, dynamic>>();
  }

  static Future<bool> deleteFillBlankExercise(String id) async {
    final response = await BackendApi.delete('/api/admin/fill-blank/$id');
    return response['success'] == true;
  }

  static Future<bool> createFillBlankExercise({
    required String id,
    required String title,
    required String content,
    required String difficulty,
    String? hint,
    required List<Map<String, dynamic>> blanks,
  }) async {
    final response = await BackendApi.post('/api/admin/fill-blank', {
      'id': id,
      'title': title,
      'content': content,
      'difficulty': difficulty,
      'hint': hint,
      'blanks': blanks,
    });
    return response['success'] == true;
  }

  static Future<bool> updateFillBlankExercise({
    required String id,
    required String title,
    required String content,
    required String difficulty,
    String? hint,
    required List<Map<String, dynamic>> blanks,
  }) async {
    final response = await BackendApi.put('/api/admin/fill-blank/$id', {
      'title': title,
      'content': content,
      'difficulty': difficulty,
      'hint': hint,
      'blanks': blanks,
    });
    return response['success'] == true;
  }

  static Future<bool> clearProgress(String type) async {
    final response = await BackendApi.deleteWithBody('/api/admin/clear-progress', {
      'type': type,
    });
    return response['success'] == true;
  }

  static Future<List<Map<String, dynamic>>> fetchQuizzes() async {
    final response = await BackendApi.get('/api/quizzes');
    final quizzes = response['quizzes'] as List<dynamic>? ?? [];
    return quizzes.cast<Map<String, dynamic>>();
  }

  static Future<bool> createQuiz({
    String? id,
    required String title,
    required String description,
    required String difficulty,
    required List<Map<String, dynamic>> questions,
  }) async {
    final response = await BackendApi.post('/api/quizzes', {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'questions': questions,
    });
    return response['success'] == true;
  }

  static Future<bool> updateQuiz({
    required String id,
    required String title,
    required String description,
    required String difficulty,
    required List<Map<String, dynamic>> questions,
  }) async {
    final response = await BackendApi.put('/api/quizzes/$id', {
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'questions': questions,
    });
    return response['success'] == true;
  }

  static Future<bool> deleteQuiz(String id) async {
    final response = await BackendApi.delete('/api/quizzes/$id');
    return response['success'] == true;
  }
}
