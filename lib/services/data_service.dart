import 'package:code_app/models/models.dart';
import 'package:code_app/services/backend_api.dart';

class DataService {
  static Future<List<Lesson>> loadLessons() async {
    final response = await BackendApi.get('/api/lessons');
    final lessonsJson = response['lessons'] as List<dynamic>? ?? [];
    return lessonsJson
        .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
