# Ứng dụng học lập trình Dart

Ứng dụng này được xây dựng bằng Flutter để giúp học viên luyện tập Dart qua:
- Bài học lý thuyết
- Code mẫu
- Quiz trắc nghiệm
- Trang bài tập Dart có chấm điểm tự động
- Playground biên dịch và chạy code ngay trên thiết bị

## Kiến trúc và luồng chạy của trang bài tập Dart

### 1. Tải dữ liệu bài tập
- Dữ liệu bài tập nằm trong `assets/data/exercises.json`.
- `ExerciseService.loadExercises()` đọc file JSON qua `rootBundle` và tạo danh sách `DartExercise`.

### 2. Hiển thị trang chi tiết bài tập
- `lib/screens/exercise_detail_screen.dart` hiển thị đề bài, yêu cầu input/output, ví dụ và ô nhập code.
- Mỗi bài tập có tập test case với input/expected output.

### 3. Bấm chạy code và kiểm tra cấu trúc
- Khi người dùng bấm chạy, app sẽ kiểm tra nhanh cấu trúc `code` trước:
  - có `import 'dart:io'`
  - có `stdin.readLineSync()`
  - có `print()` hoặc `stdout.write`
  - có vòng lặp
  - có logic đặc thù cho từng bài (ví dụ với `ex1` là tổng chữ số phải có modulo và phép chia nguyên)
- Kiểm tra này thực hiện trong phương thức `_hasExerciseSpecificLogic()`.

### 4. Gửi code sang server chạy
- `lib/services/dart_code_runner.dart` gửi request HTTP tới server runner.
- Request tới endpoint `/run_dart` gồm payload JSON:
  - `code`: mã Dart người dùng viết
  - `input`: dữ liệu test case
  - `timeout`: thời gian chờ
- URL server mặc định:
  - `http://localhost:8080` trên desktop
  - `http://10.0.2.2:8080` trên Android emulator
- Có thể override bằng biến môi trường Dart: `DART_RUNNER_API_BASE_URL`.

### 5. Server chạy code Dart và trả về kết quả
- Server hiện tại được triển khai bằng Dart trong `server/run_dart_server.dart`.
- Nó nhận HTTP POST, ghi mã vào file tạm `main.dart`, chạy bằng `dart`, thu thập `stdout`, `stderr`, `exitCode`, và `timedOut`.
- Server cũng:
  - giới hạn kích thước code và input
  - chặn một số API hệ thống nguy hiểm (`Process`, `File`, `Directory`, `Socket`, ...)
  - truyền đúng `input` vào stdin của process

### 6. So sánh kết quả và hiển thị
- `ExerciseService.compareOutput()` so sánh output thực tế với expected output:
  - loại bỏ whitespace thừa ở cuối dòng
  - loại bỏ các dòng trống phụ
- App hiển thị kết quả từng test case và tổng số test pass.
- Nếu gặp lỗi mạng/không kết nối, app sẽ cảnh báo người dùng kiểm tra server.

## Cấu trúc thư mục chính

- `lib/`
  - `main.dart` - điểm khởi chạy app
  - `screens/` - các màn hình UI
  - `services/` - logic chạy code, tải bài tập, quản lý tiến độ
  - `models/` - định nghĩa `DartExercise`, `TestCase`
  - `widgets/` - widget tái sử dụng
- `assets/data/`
  - `exercises.json`, `lessons.json` - nội dung bài học và bài tập
- `server/`
  - `run_dart_server.dart` - server Dart để chạy code người dùng
  - `README.md` - hướng dẫn khởi động server
  - `Dockerfile` - container hoá server
- `test/` - kiểm thử unit

## Công nghệ sử dụng

- Flutter + Dart: ứng dụng đa nền tảng
- `provider`: quản lý trạng thái
- `shared_preferences`: lưu tiến độ người dùng
- `code_text_field` + `flutter_highlight`: soạn thảo, highlight code
- `http`: gửi request tới server chạy code
- `google_fonts`: font chữ đẹp
- Dart `dart:io` cho server HTTP và chạy process
- Docker: container hoá server nếu cần

## Chạy dự án

### 1. Khởi động server Dart
```bash
cd server
dart run run_dart_server.dart
```

### 2. Chạy ứng dụng Flutter
```bash
cd ..
flutter pub get
flutter run
```

### 3. Nếu dùng Android emulator
- Sử dụng `http://10.0.2.2:8080` cho server runner.
- Nếu dùng thiết bị thật, dùng IP LAN của máy host.

### 4. Nếu server ở địa chỉ khác
```bash
flutter run --dart-define=DART_RUNNER_API_BASE_URL=http://YOUR_SERVER:8080
```

## Kiểm thử

- Chạy unit test:
```bash
flutter test
```
- Có test tập trung cho `DartCodeRunner` trong `test/dart_code_runner_test.dart`.

## Ghi chú

- Bài tập Dart được chạy trong sandbox tạm thời.
- Nếu gặp lỗi “không thể kết nối”, hãy kiểm tra server runner đã khởi động và app đã dùng đúng host.
- Nếu muốn triển khai thực tế, cần chạy server trong môi trường tách biệt và siết chặt chính sách bảo mật.
