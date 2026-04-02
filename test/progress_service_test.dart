import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_app/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressService Unit Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Tiến độ ban đầu phải là 0', () async {
      final service = ProgressService();
      // SharedPreferences trong mock là sync, nhưng Service cần một tick để load
      await Future.delayed(Duration.zero);
      
      expect(service.completedLessonIds, isEmpty);
      expect(service.getProgress(5), 0.0);
    });

    test('Đánh dấu hoàn thành bài học', () async {
      final service = ProgressService();
      await Future.delayed(Duration.zero);

      await service.markAsCompleted('1');
      expect(service.completedLessonIds.contains('1'), true);
      expect(service.getProgress(4), 0.25);
    });

    test('Reset tiến độ', () async {
      final service = ProgressService();
      await Future.delayed(Duration.zero);
      
      await service.markAsCompleted('1');
      await service.resetProgress();
      
      expect(service.completedLessonIds, isEmpty);
      expect(service.getProgress(5), 0.0);
    });
  });
}
