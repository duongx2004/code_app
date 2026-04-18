import 'package:flutter_test/flutter_test.dart';
import 'package:code_app/services/exercise_service.dart';

void main() {
  group('Kiểm thử logic chấm điểm bài tập (ExerciseService)', () {
    
    test('Test 1: So sánh kết quả khớp hoàn toàn (Case cơ bản)', () {
      // Nội dung: Kiểm tra khi kết quả người dùng chạy ra đúng y hệt mong đợi.
      const userOutput = "Hello World\n";
      const expectedOutput = "Hello World";
      
      expect(ExerciseService.compareOutput(userOutput, expectedOutput), true);
    });

    test('Test 2: So sánh bỏ qua khoảng trắng và dòng trống (Tránh lỗi vặt)', () {
      // Nội dung: Kiểm tra nếu người dùng lỡ tay nhấn thừa dấu cách hoặc xuống dòng
      // thì hệ thống vẫn phải tính là đúng (vì giá trị kết quả chính xác).
      const userOutput = "Kết quả: 10   \n\n";
      const expectedOutput = "Kết quả: 10";
      
      expect(ExerciseService.compareOutput(userOutput, expectedOutput), true);
    });

    test('Test 3: So sánh kết quả có nhiều dòng (Ví dụ bài tập vòng lặp)', () {
      // Nội dung: Kiểm tra logic cho các bài in ra nhiều dòng (Ví dụ Bài 3: Vòng lặp For).
      const userOutput = "Dòng 1\nDòng 2  \nDòng 3";
      const expectedOutput = "Dòng 1\nDòng 2\nDòng 3";
      
      expect(ExerciseService.compareOutput(userOutput, expectedOutput), true);
    });

    test('Test 4: Kiểm tra trường hợp kết quả SAI', () {
      // Nội dung: Đảm bảo nếu người dùng tính toán sai kết quả thì hệ thống phải báo Sai.
      const userOutput = "15"; // Kết quả người dùng
      const expectedOutput = "10"; // Đáp án đúng
      
      expect(ExerciseService.compareOutput(userOutput, expectedOutput), false);
    });

    test('Test 5: Xử lý dữ liệu đầu vào (Input Parsing)', () {
      // Nội dung: Kiểm tra xem hệ thống có tách đúng các giá trị đầu vào (\n) để đưa vào code không.
      const input = "10\\n20\\n30";
      final result = ExerciseService.parseTestInput(input);
      
      expect(result.length, 3);
      expect(result[0], "10");
      expect(result[1], "20");
      expect(result[2], "30");
    });
  });
}
