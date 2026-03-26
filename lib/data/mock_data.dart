import 'package:code_app/models/models.dart';

// Danh sách các bài học mẫu
List<Lesson> dummyLessons = [
  Lesson(
    id: '1',
    title: 'Bài 1: Biến và Kiểu dữ liệu',
    content: 'Trong Dart, bạn dùng var, String, int để khai báo biến. Biến giúp lưu trữ thông tin.',
    codeSample: 'void main() {\n  var name = "Code App";\n  print(name);\n}',
    expectedOutput: 'Code App',
    quiz: [
      Question(
        questionText: 'Kiểu dữ liệu nào dùng cho văn bản?',
        options: ['int', 'bool', 'String', 'double'],
        correctAnswerIndex: 2,
      ),
    ],
  ),
  Lesson(
    id: '2',
    title: 'Bài 2: Hàm cơ bản',
    content: 'Hàm (Function) là một khối mã thực hiện một nhiệm vụ cụ thể và có thể tái sử dụng.',
    codeSample: 'void sayHi() {\n  print("Chào mừng!");\n}\n\nvoid main() {\n  sayHi();\n}',
    expectedOutput: 'Chào mừng!',
    quiz: [
      Question(
        questionText: 'Từ khóa nào dùng khi hàm không trả về giá trị?',
        options: ['return', 'void', 'dynamic', 'var'],
        correctAnswerIndex: 1,
      ),
    ],
  ),
];