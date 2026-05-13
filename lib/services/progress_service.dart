import 'package:flutter/material.dart';
import 'package:code_app/services/backend_api.dart';
import 'package:code_app/services/sync_progress_service.dart';
import 'package:code_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProgressService extends ChangeNotifier {
  List<String> _completedLessonIds = [];
  List<String> _completedExerciseIds = [];
  List<String> _completedFillBlankIds = [];
  List<String> _completedQuizIds = [];
  String? _currentUserEmail;
  late SyncProgressService _syncService;
  bool _isOnline = true;

  ProgressService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _syncService = SyncProgressService(prefs);
    _currentUserEmail = await AuthService().getLoggedInUser();

    // Load offline progress
    await _loadOfflineProgress();

    // Check connectivity
    _checkConnectivity();

    // Load from server if logged in and online
    if (_currentUserEmail != null && _isOnline) {
      await _loadFromServer();
    }
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  Future<void> _loadOfflineProgress() async {
    final allProgress = await _syncService.getAllProgress();

    _completedLessonIds = allProgress
        .where((p) => p.type == 'lesson')
        .map((p) => p.id)
        .toList();

    _completedExerciseIds = allProgress
        .where((p) => p.type == 'exercise')
        .map((p) => p.id)
        .toList();

    _completedFillBlankIds = allProgress
        .where((p) => p.type == 'fill_blank')
        .map((p) => p.id)
        .toList();

    _completedQuizIds = allProgress
        .where((p) => p.type == 'quiz')
        .map((p) => p.id)
        .toList();

    notifyListeners();
  }

  Future<void> _loadFromServer() async {
    if (_currentUserEmail == null || !_isOnline) {
      return;
    }

    try {
      final response = await BackendApi.get('/api/progress');
      final data = response as Map<String, dynamic>;
      _completedLessonIds = List<String>.from(data['completed_lessons'] ?? []);
      _completedExerciseIds = List<String>.from(data['completed_exercises'] ?? []);

      // Load fill-blank progress
      final fillBlankResponse = await BackendApi.get('/api/fill-blank/progress');
      final fillBlankData = fillBlankResponse as Map<String, dynamic>;
      final fillBlankProgress = fillBlankData['fill_blank_progress'] as List<dynamic>? ?? [];
      _completedFillBlankIds = fillBlankProgress
          .where((p) => p['completed'] == true)
          .map((p) => p['exercise_id'] as String)
          .toList();

      // Load quiz progress
      _completedQuizIds = List<String>.from(data['completed_quizzes'] ?? []);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progress from server: $e');
      // Nếu lỗi server, giữ nguyên offline progress
    }
  }

  // Sync offline progress to server after login
  Future<void> syncOfflineProgress() async {
    if (_currentUserEmail == null || !_isOnline) {
      return;
    }

    try {
      final unsyncedProgress = await _syncService.getUnsyncedProgress();
      if (unsyncedProgress.isEmpty) {
        return;
      }

      // Sync to server
      final syncedIds = <String>[];
      for (final progress in unsyncedProgress) {
        try {
          await BackendApi.post('/api/progress/sync', {
            'user_email': _currentUserEmail,
            'type': progress.type,
            'id': progress.id,
            'timestamp': progress.timestamp.toIso8601String(),
          });
          syncedIds.add(progress.id);
        } catch (e) {
          debugPrint('Error syncing progress ${progress.id}: $e');
        }
      }

      // Mark as synced
      if (syncedIds.isNotEmpty) {
        await _syncService.markAsSynced(syncedIds);
      }

      // Reload from server to get merged data
      await _loadFromServer();
    } catch (e) {
      debugPrint('Error syncing offline progress: $e');
    }
  }

  Future<void> _saveProgressOffline(String id, String type) async {
    await _syncService.saveProgressOffline(id, type);
  }

  Future<void> _syncToServerIfPossible(String id, String type) async {
    if (_currentUserEmail != null && _isOnline) {
      try {
        await BackendApi.post('/api/progress/sync', {
          'user_email': _currentUserEmail,
          'type': type,
          'id': id,
          'timestamp': DateTime.now().toIso8601String(),
        });
        // Mark as synced
        await _syncService.markAsSynced([id]);
      } catch (e) {
        debugPrint('Error syncing to server: $e');
        // Keep as unsynced for later retry
      }
    }
  }

  List<String> get completedLessonIds => _completedLessonIds;
  List<String> get completedExerciseIds => _completedExerciseIds;
  List<String> get completedFillBlankIds => _completedFillBlankIds;
  List<String> get completedQuizIds => _completedQuizIds;

  Future<void> markAsCompleted(String lessonId) async {
    if (_completedLessonIds.contains(lessonId)) {
      return;
    }

    _completedLessonIds.add(lessonId);
    notifyListeners();

    // Save offline first
    await _saveProgressOffline(lessonId, 'lesson');

    // Try to sync to server
    await _syncToServerIfPossible(lessonId, 'lesson');
  }

  double getProgress(int totalLessons) {
    if (totalLessons == 0) return 0;
    return _completedLessonIds.length / totalLessons;
  }

  bool isCompleted(String lessonId) {
    return _completedLessonIds.contains(lessonId);
  }

  Future<void> markExerciseAsCompleted(String exerciseId) async {
    if (_completedExerciseIds.contains(exerciseId)) {
      return;
    }

    _completedExerciseIds.add(exerciseId);
    notifyListeners();

    // Save offline first
    await _saveProgressOffline(exerciseId, 'exercise');

    // Try to sync to server
    await _syncToServerIfPossible(exerciseId, 'exercise');
  }

  bool isExerciseCompleted(String exerciseId) {
    return _completedExerciseIds.contains(exerciseId);
  }

  double getExerciseProgress(int totalExercises) {
    if (totalExercises == 0) return 0;
    return _completedExerciseIds.length / totalExercises;
  }

  Future<void> markFillBlankAsCompleted(String exerciseId) async {
    if (_completedFillBlankIds.contains(exerciseId)) {
      return;
    }

    _completedFillBlankIds.add(exerciseId);
    notifyListeners();

    // Save offline first
    await _saveProgressOffline(exerciseId, 'fill_blank');

    // Try to sync to server
    await _syncToServerIfPossible(exerciseId, 'fill_blank');
  }

  bool isFillBlankCompleted(String exerciseId) {
    return _completedFillBlankIds.contains(exerciseId);
  }

  Future<void> markQuizAsCompleted(String quizId) async {
    if (_completedQuizIds.contains(quizId)) {
      return;
    }

    _completedQuizIds.add(quizId);
    notifyListeners();

    // Save offline first
    await _saveProgressOffline(quizId, 'quiz');

    // Try to sync to server
    await _syncToServerIfPossible(quizId, 'quiz');
  }

  bool isQuizCompleted(String quizId) {
    return _completedQuizIds.contains(quizId);
  }

  int getCompletedQuizCount() {
    return _completedQuizIds.length;
  }

  double getFillBlankProgress(int totalFillBlankExercises) {
    if (totalFillBlankExercises == 0) return 0;
    return _completedFillBlankIds.length / totalFillBlankExercises;
  }

  // Called when user logs in
  Future<void> onLogin(String userEmail) async {
    _currentUserEmail = userEmail;
    await _checkConnectivity();

    // Sync offline progress to server
    await syncOfflineProgress();

    // Load latest from server
    await _loadFromServer();
  }

  // Called when user logs out - keep offline progress, just clear current user
  Future<void> onLogout() async {
    _currentUserEmail = null;
    // Keep offline progress intact
    // Optionally cleanup old synced progress
    await _syncService.cleanupSyncedProgress();
  }

  // Public method to refresh progress after login
  Future<void> refreshProgress() async {
    _currentUserEmail = await AuthService().getLoggedInUser();
    await _checkConnectivity();

    // Load offline progress
    await _loadOfflineProgress();

    // Load from server if logged in and online
    if (_currentUserEmail != null && _isOnline) {
      await _loadFromServer();
    }
  }

  Future<void> resetExerciseProgress() async {
    if (_currentUserEmail != null && _isOnline) {
      try {
        for (var exerciseId in _completedExerciseIds) {
          await BackendApi.deleteWithBody('/api/progress', {
            'user_email': _currentUserEmail,
            'type': 'exercise',
            'id': exerciseId,
          });
        }
      } catch (e) {
        debugPrint('Error resetting exercise progress on server: $e');
      }
    }

    // Clear local progress
    _completedExerciseIds.clear();
    await _syncService.clearAllProgress();
    notifyListeners();
  }

  Future<void> resetQuizProgress() async {
    if (_currentUserEmail != null && _isOnline) {
      try {
        for (var quizId in _completedQuizIds) {
          await BackendApi.deleteWithBody('/api/progress', {
            'user_email': _currentUserEmail,
            'type': 'quiz',
            'id': quizId,
          });
        }
      } catch (e) {
        debugPrint('Error resetting quiz progress on server: $e');
      }
    }

    // Clear local progress
    _completedQuizIds.clear();
    await _syncService.clearAllProgress();
    notifyListeners();
  }

  Future<void> resetFillBlankProgress() async {
    if (_currentUserEmail != null && _isOnline) {
      try {
        for (var fillBlankId in _completedFillBlankIds) {
          await BackendApi.deleteWithBody('/api/progress', {
            'user_email': _currentUserEmail,
            'type': 'fill_blank',
            'id': fillBlankId,
          });
        }
      } catch (e) {
        debugPrint('Error resetting fill blank progress on server: $e');
      }
    }

    // Clear local progress
    _completedFillBlankIds.clear();
    await _syncService.clearAllProgress();
    notifyListeners();
  }

  Future<void> resetProgress() async {
    if (_currentUserEmail != null && _isOnline) {
      try {
        for (var lessonId in _completedLessonIds) {
          await BackendApi.deleteWithBody('/api/progress', {
            'user_email': _currentUserEmail,
            'type': 'lesson',
            'id': lessonId,
          });
        }
      } catch (e) {
        debugPrint('Error resetting progress on server: $e');
      }
    }

    // Clear local progress
    _completedLessonIds.clear();
    _completedExerciseIds.clear();
    _completedFillBlankIds.clear();
    _completedQuizIds.clear();
    await _syncService.clearAllProgress();
    notifyListeners();
  }
}
