# Ứng dụng học lập trình Dart

Một ứng dụng di động được xây dựng bằng Flutter, giúp người dùng học lập trình Dart một cách tương tác thông qua các bài học lý thuyết, ví dụ code mẫu, quiz kiểm tra và sân chơi code trực tiếp ngay trên thiết bị.

## Tính năng chính

- **Học tập theo lộ trình**: Danh sách bài học được phân chia rõ ràng, mỗi bài gồm lý thuyết, code mẫu và bài tập trắc nghiệm.
- **Chạy code mẫu trực tiếp**: Xem kết quả của code mẫu ngay trong bài học.
- **Quiz kiểm tra**: Trả lời câu hỏi trắc nghiệm để đánh giá mức độ hiểu bài. Hoàn thành toàn bộ câu hỏi sẽ đánh dấu bài học đã hoàn thành.
- **Sân chơi code (Playground)**: Soạn thảo code Dart, chạy thử và xem kết quả trực tiếp trên thiết bị – hoàn toàn offline, không cần kết nối Internet.
- **Theo dõi tiến độ**: Ứng dụng lưu lại các bài học đã hoàn thành và hiển thị tổng tiến độ học tập.

## Công nghệ sử dụng

- [Flutter](https://flutter.dev) – Framework giao diện đa nền tảng.
- Dart – Ngôn ngữ lập trình chính.
- `provider` – Quản lý trạng thái.
- `shared_preferences` – Lưu tiến độ học tập.
- `code_text_field` + `flutter_highlight` – Soạn thảo và tô màu code.
- `google_fonts` – Sử dụng font chữ đẹp.

## Cài đặt và chạy ứng dụng

### Yêu cầu

- Flutter SDK (phiên bản >= 3.0)
- Android Studio / VS Code (tuỳ chọn)
- Thiết bị hoặc máy ảo Android/iOS

### Các bước

1. **Clone dự án**
   ```bash
   git clone https://github.com/duongx2004/code_app.git
   cd code_app
