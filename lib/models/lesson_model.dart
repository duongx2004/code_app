import 'question_model.dart';

class Lesson {
  final String id;
  final String title;
  final String content;
  final String codeSample;
  final String expectedOutput;
  final List<Question> quiz;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.codeSample,
    required this.expectedOutput,
    required this.quiz,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final quizList = json['quiz'] as List? ?? [];

    List<Question> quizObjects =
    quizList.map((q) => Question.fromJson(q)).toList();

    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      codeSample: json['codeSample'] as String,
      expectedOutput: json['expectedOutput'] as String,
      quiz: quizObjects,
    );
  }
}