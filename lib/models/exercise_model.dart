class DartExercise {
  final String id;
  final String title;
  final String description;
  final String inputFormat;
  final String outputFormat;
  final List<TestCase> testCases;
  final String difficulty; // 'cơ bản', 'trung bình', 'nâng cao'
  final String? hint;
  final int timeLimit; // giây

  DartExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.inputFormat,
    required this.outputFormat,
    required this.testCases,
    required this.difficulty,
    this.hint,
    this.timeLimit = 30,
  });

  factory DartExercise.fromJson(Map<String, dynamic> json) {
    final testCasesList = json['test_cases'] as List? ?? [];
    List<TestCase> testCases =
        testCasesList.map((tc) => TestCase.fromJson(tc)).toList();

    return DartExercise(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      inputFormat: json['input'] as String,
      outputFormat: json['output'] as String,
      testCases: testCases,
      difficulty: json['difficulty'] as String? ?? 'cơ bản',
      hint: json['hint'] as String?,
      timeLimit: json['time_limit'] as int? ?? 30,
    );
  }
}

class TestCase {
  final String input;
  final String expectedOutput;

  TestCase({
    required this.input,
    required this.expectedOutput,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input'] as String,
      expectedOutput: json['output'] as String,
    );
  }
}
