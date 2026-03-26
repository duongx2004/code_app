// lib/models/question_model.dart

class Question {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  });

  // HÀM SỬA LỖI: Chuyển đổi từ Map (JSON) sang Object Question
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'] as String,
      // Ép kiểu list từ JSON sang List<String> của Dart
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
    );
  }
}