-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 13, 2026 at 01:54 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `code_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `exercises`
--

CREATE TABLE `exercises` (
  `id` varchar(255) NOT NULL,
  `title` text NOT NULL,
  `description` text NOT NULL,
  `input_format` text NOT NULL,
  `output_format` text NOT NULL,
  `difficulty` varchar(100) NOT NULL,
  `hint` text DEFAULT NULL,
  `time_limit` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `exercises`
--

INSERT INTO `exercises` (`id`, `title`, `description`, `input_format`, `output_format`, `difficulty`, `hint`, `time_limit`) VALUES
('1778572160027', 'Tính tổng hai số', 'Viết chương trình nhận vào hai số nguyên và in ra tổng của chúng', 'Hai số nguyên cách nhau bởi dấu cách', 'Tổng của hai số', 'cơ bản', 'Sử dụng stdin.readLineSync() để đọc input', 30),
('ex1', 'Tính tổng các chữ số', 'Viết chương trình tính tổng các chữ số trong một số nguyên dương.\n\nVí dụ: Với số 123, các chữ số là 1, 2, 3, nên tổng là 1 + 2 + 3 = 6\n\nGợi ý:\n- Dùng vòng lặp để lấy từng chữ số\n- Dùng phép toán modulo (%) để lấy chữ số cuối cùng\n- Dùng phép chia nguyên (~/) để loại bỏ chữ số cuối', 'Một dòng chứa một số nguyên dương n (1 ≤ n ≤ 100000)', 'In ra tổng các chữ số của số n', 'cơ bản', 'void main() {\n  int n = int.parse(readLineSync()!);\n  int sum = 0;\n  while (n > 0) {\n    sum += n % 10;\n    n ~/= 10;\n  }\n  print(sum);\n}', 30),
('ex2', 'In hình tam giác sao', 'Viết chương trình in ra hình tam giác sao (*) với n dòng.\n\nVí dụ: Với n=3, kết quả là:\n*\n**\n***\n\nLưu ý: Mỗi dòng có số sao bằng số thứ tự dòng đó', 'Một số nguyên n (1 ≤ n ≤ 10)', 'In ra hình tam giác sao, mỗi dòng trên một dòng', 'cơ bản', 'import \'dart:io\';\n\nvoid main() {\n  int n = int.parse(stdin.readLineSync()!);\n  for (int i = 1; i <= n; i++) {\n    for (int j = 0; j < i; j++) {\n      stdout.write(\'*\');\n    }\n    print(\'\');\n  }\n}\n\n// Hoặc cách khác không cần import:\nvoid main() {\n  int n = int.parse(readLineSync()!);\n  for (int i = 1; i <= n; i++) {\n    print(\'*\' * i);\n  }\n}', 30),
('ex3', 'Kiểm tra số chẵn lẻ', 'Viết chương trình kiểm tra một số nguyên có phải số chẵn hay không.\n\nNếu là số chẵn, in ra \'Chẵn\', nếu là số lẻ in ra \'Lẻ\'', 'Một số nguyên n', 'In ra \'Chẵn\' hoặc \'Lẻ\'', 'cơ bản', 'void main() {\n  int n = int.parse(readLineSync()!);\n  if (n % 2 == 0) {\n    print(\'Chẵn\');\n  } else {\n    print(\'Lẻ\');\n  }\n}', 30),
('ex4', 'Tìm số lớn nhất trong 3 số', 'Viết chương trình nhận vào 3 số nguyên và in ra số lớn nhất trong 3 số đó.', 'Ba dòng, mỗi dòng chứa một số nguyên', 'In ra số lớn nhất', 'cơ bản', 'void main() {\n  int a = int.parse(readLineSync()!);\n  int b = int.parse(readLineSync()!);\n  int c = int.parse(readLineSync()!);\n  int max = a;\n  if (b > max) max = b;\n  if (c > max) max = c;\n  print(max);\n}', 30),
('ex5', 'Tính giai thừa', 'Viết chương trình tính giai thừa của một số nguyên dương n.\n\nGiai thừa n! = 1 × 2 × 3 × ... × n\nVí dụ: 5! = 1 × 2 × 3 × 4 × 5 = 120', 'Một số nguyên dương n (n ≤ 20)', 'In ra giai thừa của n', 'trung bình', 'void main() {\n  int n = int.parse(readLineSync()!);\n  int factorial = 1;\n  for (int i = 1; i <= n; i++) {\n    factorial *= i;\n  }\n  print(factorial);\n}', 30);

-- --------------------------------------------------------

--
-- Table structure for table `fill_blank_answers`
--

CREATE TABLE `fill_blank_answers` (
  `id` int(11) NOT NULL,
  `exercise_id` varchar(50) NOT NULL,
  `blank_index` int(11) NOT NULL,
  `correct_answers` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`correct_answers`)),
  `hint` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `fill_blank_answers`
--

INSERT INTO `fill_blank_answers` (`id`, `exercise_id`, `blank_index`, `correct_answers`, `hint`) VALUES
(9, 'fb005', 0, '[\"List\",\"var\"]', 'Khai báo List'),
(10, 'fb005', 1, '[\"List\",\"var\"]', 'Cùng từ khóa List'),
(11, 'fb006', 0, '[\"Map\",\"var\"]', 'Khai báo Map'),
(12, 'fb006', 1, '[\"Map\",\"var\"]', 'Cùng từ khóa Map'),
(17, 'fb010', 0, '[\"await\",\"AWAIT\"]', 'Từ khóa await'),
(21, 'fb013', 0, '[\"catch\",\"CATCH\"]', 'Từ khóa catch'),
(22, 'fb014', 0, '[\"get\",\"GET\"]', 'Từ khóa get'),
(23, 'fb014', 1, '[\"fullName\",\"name\"]', 'Tên getter'),
(24, 'fb015', 0, '[\"extends\",\"EXTENDS\"]', 'Từ khóa extends'),
(25, 'fb016', 0, '[\"abstract\",\"ABSTRACT\"]', 'Từ khóa abstract'),
(26, 'fb017', 0, '[\"with\",\"WITH\"]', 'Từ khóa with'),
(27, 'fb018', 0, '[\"int\",\"String\",\"double\"]', 'Kiểu dữ liệu'),
(28, 'fb019', 0, '[\"enum\",\"ENUM\"]', 'Từ khóa enum'),
(30, 'sample_1', 0, '[\"var\"]', 'Từ khóa khai báo biến'),
(31, 'sample_1', 1, '[\"String\"]', 'Kiểu dữ liệu chuỗi'),
(32, 'sample_1', 2, '[\"String\"]', 'Kiểu dữ liệu của biến'),
(33, '1777913931826', 0, '[\"class\"]', 'không có');

-- --------------------------------------------------------

--
-- Table structure for table `fill_blank_exercises`
--

CREATE TABLE `fill_blank_exercises` (
  `id` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `difficulty` enum('cơ bản','trung bình','nâng cao') DEFAULT 'cơ bản',
  `hint` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `fill_blank_exercises`
--

INSERT INTO `fill_blank_exercises` (`id`, `title`, `content`, `difficulty`, `hint`, `created_at`, `updated_at`) VALUES
('1777913931826', 'teas', 'Trong lập trình hướng đối tượng, _____ là bản thiết kế để tạo object.', 'cơ bản', 'asdfggh', '2026-05-04 16:58:51', '2026-05-04 16:58:51'),
('fb005', 'List trong Dart', 'Để tạo một List có thể thay đổi, chúng ta sử dụng _____. Ví dụ: _____ numbers = [1, 2, 3];', 'cơ bản', 'Khai báo List', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb006', 'Map trong Dart', 'Để tạo một Map, chúng ta sử dụng _____. Ví dụ: _____ person = {\"name\": \"John\", \"age\": 30};', 'cơ bản', 'Khai báo Map', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb010', 'Future', 'Để chờ kết quả của một Future, chúng ta sử dụng _____. Ví dụ: var result = _____ future;', 'trung bình', 'Đợi Future', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb013', 'Exception Handling', 'Để bắt exception, chúng ta sử dụng _____. Ví dụ: try { code } _____ (e) { handle }', 'trung bình', 'Xử lý ngoại lệ', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb014', 'Getters và Setters', 'Để định nghĩa một getter, chúng ta sử dụng từ khóa _____. Ví dụ: String get _____ => _name;', 'trung bình', 'Getter method', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb015', 'Inheritance', 'Để kế thừa từ một class, chúng ta sử dụng từ khóa _____. Ví dụ: class Dog _____ Animal { }', 'nâng cao', 'Kế thừa class', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb016', 'Abstract Class', 'Để định nghĩa một abstract class, chúng ta sử dụng từ khóa _____. Ví dụ: _____ class Shape { }', 'nâng cao', 'Class trừu tượng', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb017', 'Mixin', 'Để sử dụng mixin, chúng ta sử dụng từ khóa _____. Ví dụ: class A _____ B { }', 'nâng cao', 'Mixin trong Dart', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb018', 'Generic Types', 'Để tạo một List với kiểu cụ thể, chúng ta sử dụng _____. Ví dụ: List<_____> numbers = [];', 'trung bình', 'Kiểu generic', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('fb019', 'Enum', 'Để định nghĩa enum, chúng ta sử dụng từ khóa _____. Ví dụ: _____ Status { active, inactive }', 'trung bình', 'Định nghĩa enum', '2026-05-03 13:48:12', '2026-05-03 13:48:12'),
('sample_1', 'Giới thiệu về biến trong Dart', 'Trong Dart, để khai báo một biến, chúng ta sử dụng từ khóa _____ hoặc _____. Ví dụ: _____ myVariable = \"Hello\";', 'cơ bản', 'Biến dùng để lưu trữ dữ liệu', '2026-05-04 13:13:30', '2026-05-04 13:13:30');

-- --------------------------------------------------------

--
-- Table structure for table `lessons`
--

CREATE TABLE `lessons` (
  `id` varchar(255) NOT NULL,
  `title` text NOT NULL,
  `description` text NOT NULL,
  `code_sample` text NOT NULL,
  `expected_output` text NOT NULL,
  `quiz` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `lessons`
--

INSERT INTO `lessons` (`id`, `title`, `description`, `code_sample`, `expected_output`, `quiz`) VALUES
('1', 'bài 1 test', 'test', 'test', 'qweer', '[{\"questionText\":\"test\",\"options\":[\"1\",\"2\",\"3\",\"4\"],\"correctAnswerIndex\":0}]'),
('2', 'Bài 2: Câu lệnh điều kiện (If-Else)', 'If-Else giúp chương trình ra quyết định dựa trên điều kiện. Nếu điều kiện đúng (true), khối lệnh bên trong \'if\' sẽ chạy.', 'void main() {\n  int age = 20;\n  if (age >= 18) {\n    print(\"Bạn đã đủ tuổi bầu cử\");\n  } else {\n    print(\"Bạn còn quá nhỏ\");\n  }\n}', 'Bạn đã đủ tuổi bầu cử', '[{\"questionText\":\"Kết quả của (10 > 5) là gì?\",\"options\":[\"true\",\"false\",\"null\",\"error\"],\"correctAnswerIndex\":0}]'),
('3', 'Bài 3: Vòng lặp For cơ bản', 'Vòng lặp For giúp bạn thực hiện một hành động nhiều lần một cách tự động.', 'void main() {\n  for (int i = 1; i <= 3; i++) {\n    print(\"Lần lặp thứ $i\");\n  }\n}', 'Lần lặp thứ 1\nLần lặp thứ 2\nLần lặp thứ 3', '[{\"questionText\":\"Trong vòng lặp for(int i=0; i<5; i++), i sẽ dừng lại ở giá trị nào?\",\"options\":[\"3\",\"4\",\"5\",\"6\"],\"correctAnswerIndex\":1}]'),
('4', 'Bài 4: Danh sách (List)', 'List là một tập hợp các phần tử có thứ tự. Chỉ số (index) của List luôn bắt đầu từ số 0.', 'void main() {\n  var fruits = [\"Táo\", \"Cam\", \"Xoài\"];\n  print(fruits[0]);\n  print(\"Số lượng: ${fruits.length}\");\n}', 'Táo\nSố lượng: 3', '[{\"questionText\":\"Để lấy phần tử thứ 2 trong danh sách \'a\', ta viết thế nào?\",\"options\":[\"a[1]\",\"a[2]\",\"a(1)\",\"a{2}\"],\"correctAnswerIndex\":0}]'),
('5', 'Bài 5: Hàm (Functions)', 'Hàm giúp gom nhóm các đoạn code có cùng chức năng để tái sử dụng nhiều lần.', 'int tinhTong(int a, int b) {\n  return a + b;\n}\n\nvoid main() {\n  print(tinhTong(10, 5));\n}', '15', '[{\"questionText\":\"Từ khóa nào dùng để trả về giá trị từ một hàm?\",\"options\":[\"get\",\"void\",\"return\",\"back\"],\"correctAnswerIndex\":2}]'),
('7', 'Bài 7: Hướng đối tượng (Class)', 'Class là khuôn mẫu để tạo ra các đối tượng (Object). Nó bao gồm các thuộc tính và phương thức.', 'class Person {\n  String name = \'User\';\n  void sayHi() => print(\'Chào $name\');\n}\n\nvoid main() {\n  var p = Person();\n  p.sayHi();\n}', 'Chào User', '[{\"questionText\":\"Từ khóa nào dùng để tạo một lớp mới?\",\"options\":[\"object\",\"new\",\"class\",\"void\"],\"correctAnswerIndex\":2}]'),
('8', 'Bài 8: Xử lý lỗi (Try-Catch)', 'Try-Catch giúp chương trình không bị \'văng\' khi gặp lỗi bất ngờ. Bạn \'thử\' (try) một đoạn code và \'bắt\' (catch) lỗi nếu có.', 'void main() {\n  try {\n    int result = 10 ~/ 0;\n    print(result);\n  } catch (e) {\n    print(\'Có lỗi xảy ra!\');\n  }\n}', 'Có lỗi xảy ra!', '[{\"questionText\":\"Khối lệnh nào luôn được thực thi dù có lỗi hay không?\",\"options\":[\"try\",\"catch\",\"finally\",\"throw\"],\"correctAnswerIndex\":2}]');

-- --------------------------------------------------------

--
-- Table structure for table `quizzes`
--

CREATE TABLE `quizzes` (
  `id` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `questions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`questions`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `quizzes`
--

INSERT INTO `quizzes` (`id`, `title`, `description`, `questions`, `created_at`, `updated_at`) VALUES
('quiz1', 'Quiz Cơ bản về Dart', 'Bài kiểm tra kiến thức cơ bản về ngôn ngữ Dart', '[{\"questionText\":\"Dart là ngôn ngữ lập trình nào?\",\"options\":[\"Frontend\",\"Backend\",\"Mobile\",\"Tất cả đều đúng\"],\"correctAnswerIndex\":3},{\"questionText\":\"Kiểu dữ liệu nào dùng để lưu số nguyên?\",\"options\":[\"String\",\"int\",\"double\",\"bool\"],\"correctAnswerIndex\":1},{\"questionText\":\"Từ khóa nào dùng để khai báo hằng số?\",\"options\":[\"var\",\"const\",\"let\",\"final\"],\"correctAnswerIndex\":1},{\"questionText\":\"Phương thức nào dùng để in ra console?\",\"options\":[\"echo\",\"print\",\"console.log\",\"write\"],\"correctAnswerIndex\":1}]', '2026-05-12 02:03:08', '2026-05-12 02:03:08'),
('quiz2', 'Quiz về Flutter', 'Bài kiểm tra kiến thức về framework Flutter', '[{\"questionText\":\"Flutter dùng ngôn ngữ nào?\",\"options\":[\"Java\",\"Kotlin\",\"Dart\",\"Swift\"],\"correctAnswerIndex\":2},{\"questionText\":\"Widget nào dùng để hiển thị text?\",\"options\":[\"Container\",\"Text\",\"Image\",\"Button\"],\"correctAnswerIndex\":1},{\"questionText\":\"StatefulWidget khác StatelessWidget ở điểm nào?\",\"options\":[\"Có thể thay đổi state\",\"Không thể thay đổi state\",\"Chỉ dùng cho layout\",\"Chỉ dùng cho animation\"],\"correctAnswerIndex\":0},{\"questionText\":\"Công cụ nào dùng để build Flutter app?\",\"options\":[\"Android Studio\",\"Xcode\",\"Flutter CLI\",\"Tất cả đều đúng\"],\"correctAnswerIndex\":3}]', '2026-05-12 02:03:08', '2026-05-12 02:03:08');

-- --------------------------------------------------------

--
-- Table structure for table `test_cases`
--

CREATE TABLE `test_cases` (
  `id` int(11) NOT NULL,
  `exercise_id` varchar(255) NOT NULL,
  `input` text NOT NULL,
  `expected_output` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `test_cases`
--

INSERT INTO `test_cases` (`id`, `exercise_id`, `input`, `expected_output`) VALUES
(1, 'ex1', '123', '6'),
(2, 'ex1', '456', '15'),
(3, 'ex1', '9999', '36'),
(4, 'ex2', '3', '*\n**\n***'),
(5, 'ex2', '5', '*\n**\n***\n****\n*****'),
(6, 'ex3', '4', 'Chẵn'),
(7, 'ex3', '7', 'Lẻ'),
(8, 'ex3', '100', 'Chẵn'),
(9, 'ex4', '10\\n20\\n15', '20'),
(10, 'ex4', '5\\n3\\n8', '8'),
(11, 'ex5', '5', '120'),
(12, 'ex5', '1', '1');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`email`, `password`, `display_name`, `is_admin`) VALUES
('admin@admin.com', 'admin123', 'Admin', 1),
('nhuan@gmail.com', '123456', 'nhuan', 0),
('nhuanoi00@gmail.com', '123456', 'nhuan', 0);

-- --------------------------------------------------------

--
-- Table structure for table `user_fill_blank_progress`
--

CREATE TABLE `user_fill_blank_progress` (
  `user_email` varchar(255) NOT NULL,
  `exercise_id` varchar(50) NOT NULL,
  `score` int(11) DEFAULT 0,
  `total_blanks` int(11) DEFAULT 0,
  `completed` tinyint(1) DEFAULT 0,
  `last_attempt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_fill_blank_progress`
--

INSERT INTO `user_fill_blank_progress` (`user_email`, `exercise_id`, `score`, `total_blanks`, `completed`, `last_attempt`) VALUES
('admin@admin.com', '1777913931826', 1, 1, 1, '2026-05-13 11:23:57'),
('admin@admin.com', 'fb005', 2, 2, 1, '2026-05-13 05:49:47'),
('admin@admin.com', 'fb006', 2, 2, 1, '2026-05-13 05:50:02'),
('admin@admin.com', 'fb010', 1, 1, 1, '2026-05-13 05:50:17');

-- --------------------------------------------------------

--
-- Table structure for table `user_progress`
--

CREATE TABLE `user_progress` (
  `id` int(11) NOT NULL,
  `user_email` varchar(255) NOT NULL,
  `lesson_id` varchar(255) DEFAULT NULL,
  `exercise_id` varchar(255) DEFAULT NULL,
  `type` enum('lesson','exercise') NOT NULL,
  `completed` tinyint(1) DEFAULT 0,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_progress`
--

INSERT INTO `user_progress` (`id`, `user_email`, `lesson_id`, `exercise_id`, `type`, `completed`, `completed_at`) VALUES
(6, 'admin@admin.com', '1', NULL, 'lesson', 1, '2026-05-13 05:42:25'),
(7, 'admin@admin.com', '2', NULL, 'lesson', 1, '2026-05-13 05:46:17'),
(8, 'admin@admin.com', '1', NULL, 'lesson', 1, '2026-05-13 05:55:23'),
(9, 'admin@admin.com', '2', NULL, 'lesson', 1, '2026-05-13 05:55:36'),
(10, 'admin@admin.com', NULL, '1778572160027', 'exercise', 1, '2026-05-13 05:57:26');

-- --------------------------------------------------------

--
-- Table structure for table `user_progress_backup`
--

CREATE TABLE `user_progress_backup` (
  `user_email` varchar(255) NOT NULL,
  `lesson_id` varchar(255) NOT NULL,
  `exercise_id` varchar(255) NOT NULL,
  `type` enum('lesson','exercise') NOT NULL,
  `completed` tinyint(1) DEFAULT 0,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `exercises`
--
ALTER TABLE `exercises`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `fill_blank_answers`
--
ALTER TABLE `fill_blank_answers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_blank` (`exercise_id`,`blank_index`);

--
-- Indexes for table `fill_blank_exercises`
--
ALTER TABLE `fill_blank_exercises`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `lessons`
--
ALTER TABLE `lessons`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `quizzes`
--
ALTER TABLE `quizzes`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `test_cases`
--
ALTER TABLE `test_cases`
  ADD PRIMARY KEY (`id`),
  ADD KEY `exercise_id` (`exercise_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `user_fill_blank_progress`
--
ALTER TABLE `user_fill_blank_progress`
  ADD PRIMARY KEY (`user_email`,`exercise_id`),
  ADD KEY `exercise_id` (`exercise_id`);

--
-- Indexes for table `user_progress`
--
ALTER TABLE `user_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_progress` (`user_email`,`type`,`lesson_id`,`exercise_id`),
  ADD KEY `idx_user_progress_type` (`type`),
  ADD KEY `idx_user_progress_completed` (`completed`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `fill_blank_answers`
--
ALTER TABLE `fill_blank_answers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT for table `test_cases`
--
ALTER TABLE `test_cases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT for table `user_progress`
--
ALTER TABLE `user_progress`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `fill_blank_answers`
--
ALTER TABLE `fill_blank_answers`
  ADD CONSTRAINT `fill_blank_answers_ibfk_1` FOREIGN KEY (`exercise_id`) REFERENCES `fill_blank_exercises` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `test_cases`
--
ALTER TABLE `test_cases`
  ADD CONSTRAINT `test_cases_ibfk_1` FOREIGN KEY (`exercise_id`) REFERENCES `exercises` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_fill_blank_progress`
--
ALTER TABLE `user_fill_blank_progress`
  ADD CONSTRAINT `user_fill_blank_progress_ibfk_1` FOREIGN KEY (`user_email`) REFERENCES `users` (`email`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_fill_blank_progress_ibfk_2` FOREIGN KEY (`exercise_id`) REFERENCES `fill_blank_exercises` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
