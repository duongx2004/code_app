# Ứng dụng học lập trình Dart

Một ứng dụng di động được xây dựng bằng Flutter, kết hợp với server backend Node.js và cơ sở dữ liệu MySQL, giúp người dùng học lập trình Dart một cách tương tác thông qua các bài học lý thuyết, ví dụ code mẫu, quiz kiểm tra và sân chơi code trực tiếp. Ứng dụng hỗ trợ chạy code Dart trên server để kiểm tra kết quả một cách an toàn.

## Tính năng chính

- **Học tập theo lộ trình**: Danh sách bài học được phân chia rõ ràng, mỗi bài gồm lý thuyết, code mẫu và bài tập trắc nghiệm.
- **Chạy code mẫu trực tiếp**: Xem kết quả của code mẫu ngay trong bài học thông qua server backend.
- **Quiz kiểm tra**: Trả lời câu hỏi trắc nghiệm để đánh giá mức độ hiểu bài. Hoàn thành toàn bộ câu hỏi sẽ đánh dấu bài học đã hoàn thành.
- **Sân chơi code (Playground)**: Soạn thảo code Dart, chạy thử và xem kết quả trực tiếp thông qua server – hỗ trợ offline với server local.
- **Bài tập lập trình**: Giải các bài tập với test case, chạy code trên server để kiểm tra kết quả.
- **Quản lý người dùng**: Đăng ký, đăng nhập, cập nhật profile.
- **Quản trị viên**: Quản lý người dùng, bài học, bài tập qua giao diện admin.
- **Theo dõi tiến độ**: Ứng dụng lưu lại các bài học đã hoàn thành và hiển thị tổng tiến độ học tập.

## Công nghệ sử dụng

### Frontend (Flutter)
- [Flutter](https://flutter.dev) – Framework giao diện đa nền tảng.
- Dart – Ngôn ngữ lập trình chính.
- `provider` – Quản lý trạng thái.
- `shared_preferences` – Lưu tiến độ học tập.
- `code_text_field` + `flutter_highlight` – Soạn thảo và tô màu code.
- `google_fonts` – Sử dụng font chữ đẹp.
- `http` – Gọi API đến server backend.

### Backend (Node.js)
- Node.js – Runtime JavaScript.
- Express.js (thông qua http module) – Xây dựng API server.
- MySQL2 – Kết nối cơ sở dữ liệu MySQL.
- `child_process` – Chạy code Dart trong sandbox.
- `dotenv` – Quản lý biến môi trường.

### Cơ sở dữ liệu
- MySQL – Lưu trữ dữ liệu người dùng, bài học, bài tập, test case.

## Yêu cầu hệ thống

- Flutter SDK (phiên bản >= 3.0)
- Node.js (phiên bản >= 16)
- MySQL Server (phiên bản >= 8.0)
- Android Studio / VS Code (tuỳ chọn cho phát triển)
- Thiết bị hoặc máy ảo Android/iOS

## Cài đặt và chạy ứng dụng

### 1. Cài đặt Flutter

1. Tải và cài đặt Flutter SDK từ [flutter.dev](https://flutter.dev/docs/get-started/install).
2. Thêm Flutter vào PATH hệ thống.
3. Chạy lệnh kiểm tra:
   ```bash
   flutter doctor
   ```
   Đảm bảo không có lỗi nghiêm trọng.

### 2. Cài đặt Node.js

1. Tải và cài đặt Node.js từ [nodejs.org](https://nodejs.org/).
2. Kiểm tra phiên bản:
   ```bash
   node --version
   npm --version
   ```

### 3. Cài đặt MySQL

1. Tải và cài đặt MySQL Server từ [mysql.com](https://dev.mysql.com/downloads/mysql/).
2. Khởi động MySQL service.
3. Tạo database và user (hoặc sử dụng root).

### 4. Clone và cấu hình dự án

1. Clone dự án:
   ```bash
   git clone https://github.com/duongx2004/code_app.git
   cd code_app
   ```

2. Cài đặt dependencies cho Flutter:
   ```bash
   flutter pub get
   ```

3. Cài đặt dependencies cho server Node.js:
   ```bash
   cd server
   npm install
   cd ..
   ```

4. Cấu hình biến môi trường:
   - Sao chép file `server/.env` và chỉnh sửa các giá trị:
     ```
     PORT=8080
     HOST=0.0.0.0
     MYSQL_HOST=127.0.0.1
     MYSQL_PORT=3306
     MYSQL_USER=root
     MYSQL_PASSWORD=your_password
     MYSQL_DATABASE=code_app
     ADMIN_EMAIL=admin@admin.com
     ADMIN_PASSWORD=admin123
     DART_PATH=D:\flutter\bin\cache\dart-sdk\bin\dart.exe  # Thay bằng đường dẫn Dart thực tế
     ```
   - Đảm bảo đường dẫn DART_PATH chính xác (chạy `where dart` trên Windows hoặc `which dart` trên Linux/macOS để tìm).

5. Khởi tạo cơ sở dữ liệu:
   - Server sẽ tự động tạo database và bảng khi chạy lần đầu.

### 5. Chạy server backend

1. Mở terminal và chạy:
   ```bash
   cd server
   node run_dart_server.js
   ```
   Server sẽ chạy trên `http://localhost:8080` (hoặc port đã cấu hình).

2. Kiểm tra server hoạt động:
   - Truy cập `http://localhost:8080/health` để xem `{ "ok": true }`.

### 6. Chạy ứng dụng Flutter

1. Mở terminal khác và chạy:
   ```bash
   flutter run
   ```
   Chọn thiết bị Android/iOS để chạy.

2. Ứng dụng sẽ kết nối đến server local để chạy code.

## Cấu trúc dự án

```
code_app/
├── android/                 # Cấu hình Android
├── ios/                     # Cấu hình iOS
├── lib/                     # Source code Flutter
│   ├── data/                # Dữ liệu mock và cấu hình
│   ├── models/              # Model dữ liệu
│   ├── screens/             # Màn hình UI
│   ├── services/            # Service gọi API
│   ├── widgets/             # Widget tái sử dụng
│   └── main.dart            # Entry point
├── server/                  # Backend Node.js
│   ├── run_dart_server.js  # Server chính
│   ├── package.json         # Dependencies Node.js
│   ├── .env                 # Biến môi trường
│   └── ...
├── assets/                  # Tài nguyên tĩnh
├── test/                    # Unit tests
├── pubspec.yaml             # Cấu hình Flutter
└── README.md                # Tài liệu này
```

## API Endpoints

Server cung cấp các API sau:

- `POST /run_dart` – Chạy code Dart
- `GET/POST/PUT/DELETE /api/users` – Quản lý người dùng
- `GET/POST/PUT/DELETE /api/lessons` – Quản lý bài học
- `GET/POST/PUT/DELETE /api/exercises` – Quản lý bài tập
- `GET /health` – Kiểm tra trạng thái server






