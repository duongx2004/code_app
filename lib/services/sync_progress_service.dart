import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressItem {
  final String id;
  final String type; // 'lesson', 'exercise', 'fill_blank'
  final DateTime timestamp;
  final bool synced;

  ProgressItem({
    required this.id,
    required this.type,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'synced': synced,
  };

  factory ProgressItem.fromJson(Map<String, dynamic> json) => ProgressItem(
    id: json['id'],
    type: json['type'],
    timestamp: DateTime.parse(json['timestamp']),
    synced: json['synced'] ?? false,
  );
}

class SyncProgressService {
  static const String _keyOfflineProgress = 'offline_progress';
  static const String _keyLastSyncTime = 'last_sync_time';

  final SharedPreferences _prefs;

  SyncProgressService(this._prefs);

  // Lưu progress vào local storage
  Future<void> saveProgressOffline(String id, String type) async {
    final progressList = await _getOfflineProgress();
    final existingIndex = progressList.indexWhere((p) => p.id == id && p.type == type);

    if (existingIndex >= 0) {
      // Update existing
      progressList[existingIndex] = ProgressItem(
        id: id,
        type: type,
        timestamp: DateTime.now(),
        synced: false,
      );
    } else {
      // Add new
      progressList.add(ProgressItem(
        id: id,
        type: type,
        timestamp: DateTime.now(),
        synced: false,
      ));
    }

    await _saveOfflineProgress(progressList);
  }

  // Lấy danh sách progress chưa sync
  Future<List<ProgressItem>> getUnsyncedProgress() async {
    final progressList = await _getOfflineProgress();
    return progressList.where((p) => !p.synced).toList();
  }

  // Đánh dấu progress đã sync
  Future<void> markAsSynced(List<String> syncedIds) async {
    final progressList = await _getOfflineProgress();
    for (final id in syncedIds) {
      final index = progressList.indexWhere((p) => p.id == id);
      if (index >= 0) {
        progressList[index] = ProgressItem(
          id: progressList[index].id,
          type: progressList[index].type,
          timestamp: progressList[index].timestamp,
          synced: true,
        );
      }
    }
    await _saveOfflineProgress(progressList);
    await _setLastSyncTime(DateTime.now());
  }

  // Lấy tất cả progress (bao gồm cả đã sync và chưa sync)
  Future<List<ProgressItem>> getAllProgress() async {
    return await _getOfflineProgress();
  }

  // Xóa progress đã sync cũ (cleanup)
  Future<void> cleanupSyncedProgress({Duration? olderThan}) async {
    olderThan ??= const Duration(days: 30);
    final cutoffTime = DateTime.now().subtract(olderThan);

    final progressList = await _getOfflineProgress();
    final filteredList = progressList.where((p) =>
      !p.synced || p.timestamp.isAfter(cutoffTime)
    ).toList();

    await _saveOfflineProgress(filteredList);
  }

  // Clear all offline progress (khi logout)
  Future<void> clearAllProgress() async {
    await _prefs.remove(_keyOfflineProgress);
    await _prefs.remove(_keyLastSyncTime);
  }

  // Lấy thời gian sync cuối cùng
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _prefs.getString(_keyLastSyncTime);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  Future<List<ProgressItem>> _getOfflineProgress() async {
    final jsonString = _prefs.getString(_keyOfflineProgress);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ProgressItem.fromJson(json)).toList();
    } catch (e) {
      // Nếu có lỗi parse, reset
      await _prefs.remove(_keyOfflineProgress);
      return [];
    }
  }

  Future<void> _saveOfflineProgress(List<ProgressItem> progressList) async {
    final jsonList = progressList.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyOfflineProgress, jsonEncode(jsonList));
  }

  Future<void> _setLastSyncTime(DateTime time) async {
    await _prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }
}