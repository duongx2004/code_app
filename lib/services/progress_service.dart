import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressService extends ChangeNotifier {
  List<String> _completedLessonIds = [];

  ProgressService() {
    _loadFromPrefs();
  }

  List<String> get completedLessonIds => _completedLessonIds;

  Future<void> markAsCompleted(String lessonId) async {
    if (!_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.add(lessonId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completed_lessons', _completedLessonIds);
      notifyListeners();
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _completedLessonIds = prefs.getStringList('completed_lessons') ?? [];
    notifyListeners();
  }

  double getProgress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }

  Future<void> resetProgress() async {
    _completedLessonIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('completed_lessons');
    notifyListeners();
  }
}