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
    required this.quiz
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Chuyển danh sách quiz từ JSON thành danh sách Object Question
    var quizList = json['quiz'] as List;
    List<Question> quizObjects = quizList.map((q) => Question.fromJson(q)).toList();

    return Lesson(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      codeSample: json['codeSample'],
      expectedOutput: json['expectedOutput'],
      quiz: quizObjects, // Gán danh sách đã chuyển đổi vào đây
    );
  }
}