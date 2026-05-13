import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:code_app/models/models.dart';
import 'package:code_app/services/backend_api.dart';

class DataService {
  static Future<List<Lesson>> loadLessons() async {
    try {
      // Try to fetch from API first
      final response = await BackendApi.get('/api/lessons');
      final lessonsJson = response['lessons'] as List<dynamic>? ?? [];
      if (lessonsJson.isNotEmpty) {
        return lessonsJson
            .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // If API fails, fall back to local data
      print('API failed, loading local lesson data: $e');
    }

    // Load from local JSON file as fallback
    try {
      final jsonString = await rootBundle.loadString('assets/data/lessons.json');
      final lessonsJson = json.decode(jsonString) as List<dynamic>;
      return lessonsJson
          .map((json) => Lesson.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Failed to load local lesson data: $e');
      return [];
    }
  }
}
