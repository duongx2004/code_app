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

  static Future<bool> createLesson(Lesson lesson) async {
    final response = await BackendApi.post('/api/lessons', lesson.toMap());
    return response['success'] == true;
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

  static Future<bool> createExercise(DartExercise exercise) async {
    final response = await BackendApi.post('/api/exercises', {
      ...exercise.toMap(),
      'test_cases': exercise.testCases.map((tc) => tc.toMap()).toList(),
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
}
