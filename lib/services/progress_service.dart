import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProgressService extends ChangeNotifier {
  List<String> _completedLessonIds = [];
  List<String> _completedExerciseIds = [];
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
  List<String> get completedExerciseIds => _completedExerciseIds;

  String get _storageKey => _currentUserEmail != null 
      ? 'completed_lessons_$_currentUserEmail' 
      : 'completed_lessons_guest';

    String get _exerciseStorageKey => _currentUserEmail != null
      ? 'completed_exercises_$_currentUserEmail'
      : 'completed_exercises_guest';

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
    _completedExerciseIds = prefs.getStringList(_exerciseStorageKey) ?? [];
    notifyListeners();
  }

  double getProgress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }

  bool isCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  Future<void> markExerciseAsCompleted(String exerciseId) async {
    if (!_completedExerciseIds.contains(exerciseId)) {
      _completedExerciseIds.add(exerciseId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_exerciseStorageKey, _completedExerciseIds);
      notifyListeners();
    }
  }

  bool isExerciseCompleted(String exerciseId) {
    return _completedExerciseIds.contains(exerciseId);
  }

  double getExerciseProgress(int totalExercises) {
    if (totalExercises == 0) return 0;
    return _completedExerciseIds.length / totalExercises;
  }

  Future<void> resetExerciseProgress() async {
    _completedExerciseIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_exerciseStorageKey);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _completedLessonIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}
