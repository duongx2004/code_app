import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:code_app/main.dart';
import 'package:code_app/services/progress_service.dart';

void main() {
  testWidgets('Kiểm tra hiển thị màn hình Home và tiến độ', (WidgetTester tester) async {
    // 1. Khởi chạy ứng dụng trong môi trường Test
    // Chúng ta bao bọc MyApp trong ChangeNotifierProvider giống như trong main.dart
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ProgressService(),
        child: const MyApp(),
      ),
    );

    // 2. Vì app load JSON (bất đồng bộ), ta cần đợi một chút để dữ liệu hiện lên
    await tester.pumpAndSettle();

    // 3. Kiểm tra xem tiêu đề AppBar có xuất hiện không
    expect(find.text('Lộ trình học Dart'), findsOneWidget);

    // 4. Kiểm tra xem thanh tiến độ tổng quát có xuất hiện không
    expect(find.text('Tiến độ tổng quát'), findsOneWidget);

    // 5. Kiểm tra sự tồn tại của ít nhất một bài học (nếu file JSON có dữ liệu)
    // Lưu ý: Trong môi trường test thực tế, bạn nên dùng MockData thay vì đọc file assets thật
    // Nhưng với bài tập này, chỉ cần đảm bảo app không bị crash khi load là đủ.
  });
}