import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProgressService extends ChangeNotifier {
  List<String> _completedLessonIds = [];
  String? _currentUserEmail;

  ProgressService() {
    init();
  }

  Future<void> init() async {
    _currentUserEmail = await AuthService().getLoggedInUser();
    if (_currentUserEmail != null) {
      await _loadFromPrefs();
    }
  }

  List<String> get completedLessonIds => _completedLessonIds;

  String get _storageKey => _currentUserEmail != null 
      ? 'completed_lessons_$_currentUserEmail' 
      : 'completed_lessons_guest';

  Future<void> markAsCompleted(String lessonId) async {
    if (!_completedLessonIds.contains(lessonId)) {
      _completedLessonIds.add(lessonId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _completedLessonIds);
      notifyListeners();
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _completedLessonIds = prefs.getStringList(_storageKey) ?? [];
    notifyListeners();
  }

  double getProgress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }

  bool isCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  Future<void> resetProgress() async {
    _completedLessonIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
