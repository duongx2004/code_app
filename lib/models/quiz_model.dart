import 'question_model.dart';

class Quiz {
  final String id;
  final String title;
  final String description;
  /// Độ khó từ API (có thể rỗng với dữ liệu cũ / file JSON).
  final String difficulty;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    this.difficulty = '',
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>)
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}