import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService extends ChangeNotifier {
  List<String> _completedLessonIds = [];

  ProgressService() {
    _loadFromPrefs(); // Load dữ liệu ngay khi khởi tạo
  }

  List<String> get completedLessonIds => _completedLessonIds;

  // Lưu vào máy
  Future<void> markAsCompleted(String lessonId) async {
    if (!_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.add(lessonId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completed_lessons', _completedLessonIds);

      notifyListeners();
    }
  }

  // Đọc từ máy lên
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _completedLessonIds = prefs.getStringList('completed_lessons') ?? [];
    notifyListeners();
  }

  double getProgress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }
}