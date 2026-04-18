import 'package:code_app/models/models.dart';

// Danh sách các bài học mẫu dùng cho Unit Test
List<Lesson> dummyLessons = [
  Lesson(
    id: '1',
    title: 'Bài 1: Biến và Kiểu dữ liệu',
    content: 'Trong Dart, mọi thứ đều là Object. Bạn sử dụng \'var\' để Dart tự suy luận kiểu, hoặc chỉ định rõ như \'String\', \'int\', \'double\', \'bool\'.',
    codeSample: 'void main() {\n  String name = "Flutter";\n  int year = 2024;\n  print("\$name ra đời năm \$year");\n}',
    expectedOutput: 'Flutter ra đời năm 2024',
    quiz: [
      Question(
        questionText: 'Kiểu dữ liệu nào dùng để lưu giá trị Đúng/Sai?',
        options: ['int', 'String', 'bool', 'double'],
        correctAnswerIndex: 2,
      ),
      Question(
        questionText: 'Từ khóa nào giúp Dart tự suy luận kiểu?',
        options: ['var', 'auto', 'let', 'dynamic'],
        correctAnswerIndex: 0,
      ),
      Question(
        questionText: 'Kiểu dữ liệu nào dùng để lưu số thực?',
        options: ['int', 'double', 'String', 'bool'],
        correctAnswerIndex: 1,
      ),
    ],
  ),
  Lesson(
    id: '2',
    title: 'Bài 2: Câu lệnh điều kiện (If-Else)',
    content: 'If-Else giúp chương trình ra quyết định dựa trên điều kiện.',
    codeSample: 'void main() {\n  int age = 20;\n  if (age >= 18) {\n    print("Bạn đã đủ tuổi bầu cử");\n  } else {\n    print("Bạn còn quá nhỏ");\n  }\n}',
    expectedOutput: 'Bạn đã đủ tuổi bầu cử',
    quiz: [
      Question(
        questionText: 'Kết quả của (10 > 5) là gì?',
        options: ['true', 'false', 'null', 'error'],
        correctAnswerIndex: 0,
      ),
    ],
  ),
  Lesson(
    id: '3',
    title: 'Bài 3: Vòng lặp For cơ bản',
    content: 'Vòng lặp For giúp bạn thực hiện một hành động nhiều lần.',
    codeSample: 'void main() {\n  for (int i = 1; i <= 3; i++) {\n    print("Lần lặp thứ \$i");\n  }\n}',
    expectedOutput: 'Lần lặp thứ 1\nLần lặp thứ 2\nLần lặp thứ 3',
    quiz: [
      Question(
        questionText: 'Trong vòng lặp for(int i=0; i<5; i++), i sẽ dừng lại ở giá trị nào?',
        options: ['3', '4', '5', '6'],
        correctAnswerIndex: 1,
      ),
    ],
  ),
  Lesson(
    id: '4',
    title: 'Bài 4: Danh sách (List)',
    content: 'List là một tập hợp các phần tử có thứ tự, bắt đầu từ số 0.',
    codeSample: 'void main() {\n  var fruits = ["Táo", "Cam", "Xoài"];\n  print(fruits[0]);\n}',
    expectedOutput: 'Táo',
    quiz: [
      Question(
        questionText: 'Để lấy phần tử thứ 2 trong danh sách \'a\', ta viết thế nào?',
        options: ['a[1]', 'a[2]', 'a(1)', 'a{2}'],
        correctAnswerIndex: 0,
      ),
    ],
  ),
  Lesson(
    id: '5',
    title: 'Bài 5: Hàm (Functions)',
    content: 'Hàm giúp gom nhóm các đoạn code có cùng chức năng.',
    codeSample: 'int tinhTong(int a, int b) {\n  return a + b;\n}\n\nvoid main() {\n  print(tinhTong(10, 5));\n}',
    expectedOutput: '15',
    quiz: [
      Question(
        questionText: 'Từ khóa nào dùng để trả về giá trị từ một hàm?',
        options: ['get', 'void', 'return', 'back'],
        correctAnswerIndex: 2,
      ),
    ],
  ),
  Lesson(
    id: '6',
    title: 'Bài 6: Map (Từ điển)',
    content: 'Map là một tập hợp các cặp khóa-giá trị (key-value).',
    codeSample: 'void main() {\n  var scores = {\'Toán\': 9, \'Văn\': 8};\n  print(scores[\'Toán\']);\n}',
    expectedOutput: '9',
    quiz: [
      Question(
        questionText: 'Trong Map {\'A\': 1}, \'A\' được gọi là gì?',
        options: ['Value', 'Key', 'Index', 'List'],
        correctAnswerIndex: 1,
      ),
    ],
  ),
  Lesson(
    id: '7',
    title: 'Bài 7: Hướng đối tượng (Class)',
    content: 'Class là khuôn mẫu để tạo ra các đối tượng (Object).',
    codeSample: 'class Person {\n  String name = \'User\';\n  void sayHi() => print(\'Chào \$name\');\n}\n\nvoid main() {\n  var p = Person();\n  p.sayHi();\n}',
    expectedOutput: 'Chào User',
    quiz: [
      Question(
        questionText: 'Từ khóa nào dùng để tạo một lớp mới?',
        options: ['object', 'new', 'class', 'void'],
        correctAnswerIndex: 2,
      ),
    ],
  ),
  Lesson(
    id: '8',
    title: 'Bài 8: Xử lý lỗi (Try-Catch)',
    content: 'Try-Catch giúp chương trình không bị crash khi gặp lỗi bất ngờ.',
    codeSample: 'void main() {\n  try {\n    int result = 10 ~/ 0;\n    print(result);\n  } catch (e) {\n    print(\'Có lỗi xảy ra!\');\n  }\n}',
    expectedOutput: 'Có lỗi xảy ra!',
    quiz: [
      Question(
        questionText: 'Khối lệnh nào luôn được thực thi dù có lỗi hay không?',
        options: ['try', 'catch', 'finally', 'throw'],
        correctAnswerIndex: 2,
      ),
    ],
  ),
];
