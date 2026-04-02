import 'package:code_app/models/lesson_model.dart';
import 'package:code_app/models/question_model.dart';

final List<Lesson> lessons = [
  Lesson(
    id: "4",
    title: "Biến trong Dart",
    content: "Biến dùng để lưu trữ dữ liệu...",
    codeSample: "var name = 'Dart'; print(name);",
    expectedOutput: "Dart",
    quiz: [
      Question(
        questionText: "Từ khóa khai báo biến linh hoạt?",
        options: ["int", "var", "String", "final"],
        correctAnswerIndex: 1,
      ),
    ],
  ),
];
