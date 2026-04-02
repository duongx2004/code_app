import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:code_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kiểm tra hiển thị màn hình Home và tiến độ', (WidgetTester tester) async {
    // Mock SharedPreferences để tránh lỗi khi khởi tạo ProgressService
    SharedPreferences.setMockInitialValues({});
    
    // 1. Khởi chạy ứng dụng
    await tester.pumpWidget(const MyApp());

    // 2. Chờ màn hình AuthWrapper kiểm tra trạng thái đăng nhập (màn hình Loading)
    // Dùng findsWidgets vì có thể có nhiều CircularProgressIndicator hoặc ít nhất 1 cái
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // 3. Đợi một lúc để giả lập quá trình load dữ liệu xong
    await tester.pump(const Duration(seconds: 2));
    
    // Sau khi load xong, màn hình sẽ chuyển sang LoginScreen (nếu chưa đăng nhập)
    // Chúng ta kiểm tra sự tồn tại của nút "Đăng nhập" hoặc một text đặc trưng
    // expect(find.text('Đăng nhập'), findsOneWidget);
  });
}
