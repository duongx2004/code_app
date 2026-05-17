# 📚 CodeLearn - Ứng dụng Học Lập Trình Dart

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-16+-339933?style=flat&logo=node.js)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql)](https://mysql.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Ứng dụng học lập trình **Dart** toàn diện với giao diện trực quan, hỗ trợ đa nền tảng (Android, iOS, Web, Desktop). Kết hợp **lý thuyết, thực hành code, quiz kiểm tra và sân chơi lập trình trực tiếp**.

---

## ✨ Tính Năng Nổi Bật

### 🎓 **Học Tập Tương Tác**
- **Bài học có cấu trúc**: Lý thuyết chi tiết với code mẫu
- **Chạy code trực tiếp**: Xem kết quả ngay trong bài học
- **Theo dõi tiến độ**: Lưu trạng thái hoàn thành bài học

### 💻 **Bài Tập Đa Dạng**
- **Bài tập code**: Viết code giải quyết bài toán với kiểm tra test case
- **Bài tập trắc nghiệm**: Câu hỏi đa lựa chọn với giải thích chi tiết
- **Bài tập điền chỗ trống**: Hoàn thành code với nhiều đáp án đúng
- **Đánh giá tự động**: Kiểm tra kết quả ngay lập tức

### 🎮 **Sân Chơi Lập Trình (Playground)**
- **Editor code**: Soạn thảo với syntax highlighting
- **Chạy code realtime**: Thực thi code Dart qua server backend
- **Xem kết quả**: Output trực quan, dễ đọc
- **Responsive layout**: Tự động điều chỉnh theo kích thước màn hình

### 👨‍💼 **Quản Trị Viên**
- **Quản lý người dùng**: Xem, chỉnh sửa, xóa tài khoản
- **Quản lý nội dung**: Thêm/sửa bài học, bài tập

### 📱 **Giao Diện Thân Thiện**
- **Responsive Design**: Hoạt động trên mọi kích thước màn hình
- **Dark Mode Support**: Giao diện sáng/tối tùy chỉnh
- **Đa ngôn ngữ**: Hỗ trợ tiếng Việt

---

## 🛠️ Công Nghệ Sử Dụng

### Frontend - Flutter & Dart
```
✓ Framework: Flutter 3.0+
✓ Language: Dart 3.0+
✓ UI Design: Material Design 3
✓ State Management: Provider
✓ Local Storage: SharedPreferences
✓ Code Editing: code_text_field + flutter_highlight
✓ Networking: HTTP/REST APIs
```

### Backend - Node.js
```
✓ Runtime: Node.js 16+
✓ Web Server: Express.js
✓ Code Execution: Child process (sandboxed)
✓ Request Handling: CORS, Input validation
✓ API: RESTful endpoints
```

### Database - MySQL
```
✓ Database: MySQL 8.0+
✓ Character Set: UTF-8MB4 (hỗ trợ tiếng Việt)
✓ Tables: users, lessons, exercises, quiz, progress, etc.
✓ Queries: Optimized for performance
```

---

## 📁 Cấu Trúc Dự Án

```
code_app/
│
├── 📱 lib/                              # Flutter source code (Dart)
│   ├── main.dart                        # Entry point
│   ├── theme/
│   │   └── app_theme.dart              # Styling & colors
│   │
│   ├── models/                          # Data models
│   │   ├── lesson_model.dart
│   │   ├── exercise_model.dart
│   │   ├── quiz_model.dart
│   │   ├── fill_blank_model.dart
│   │   └── question_model.dart
│   │
│   ├── services/                        # API & Business logic
│   │   ├── backend_api.dart            # HTTP client
│   │   ├── auth_service.dart           # Authentication
│   │   ├── lesson_service.dart
│   │   ├── exercise_service.dart
│   │   ├── quiz_service.dart
│   │   ├── fill_blank_service.dart
│   │   ├── dart_code_runner.dart       # Execute Dart code
│   │   ├── progress_service.dart       # Track learning progress
│   │   └── data_service.dart
│   │
│   ├── screens/                         # UI Pages
│   │   ├── home_screen.dart            # Learning roadmap
│   │   ├── lesson_detail_screen.dart   # Lesson content
│   │   ├── exercise_screen.dart        # Code exercises list
│   │   ├── exercise_detail_screen.dart # Code exercise editor
│   │   ├── quiz_list_screen.dart       # Quiz list
│   │   ├── quiz_detail_screen.dart     # Quiz taking
│   │   ├── fill_blank_list_screen.dart # Fill-blank list
│   │   ├── fill_blank_exercise_screen.dart # Fill-blank editor
│   │   ├── playground_screen.dart      # Dart playground
│   │   ├── admin_screen.dart           # Admin panel
│   │   └── auth/
│   │       ├── login_screen.dart
│   │       └── register_screen.dart
│   │
│   ├── widgets/                         # Reusable components
│   │   ├── code_editor.dart            # Code editor widget
│   │   ├── common_widgets.dart         # Progress card, chips, etc.
│   │   └── custom_card.dart
│   │
│   └── data/                            # Local assets
│
├── 🖥️ server/                          # Node.js Backend
│   ├── run_dart_server.js              # Main server file
│   ├── package.json                    # Dependencies
│   ├── .env.example                    # Environment template
│   └── data/                           # Static data
│       └── sample_exercises.json
│
├── 🎨 assets/                          # Static assets
│   └── data/
│       ├── lessons.json                # Lesson data
│       ├── exercises.json              # Exercise data
│       ├── quizzes.json                # Quiz data
│       └── fill_blank_exercises.json
│
├── 📊 build/                           # Build output (generated)
│
├── 🧪 test/                            # Unit tests
│   ├── exercise_service_test.dart
│   └── widget_test.dart
│
├── 📱 android/                         # Android specific config
│
├── 🍎 ios/                             # iOS specific config
│
├── 🖥️ windows/                         # Windows Desktop config
│
├── 🌐 web/                             # Web platform config
│
├── 📄 pubspec.yaml                     # Flutter dependencies
├── 📖 README.md                        # This file
└── ⚙️ analysis_options.yaml            # Lint rules

```

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy

### 📋 Yêu Cầu Hệ Thống

```
✓ Flutter SDK >= 3.0.0
✓ Dart SDK >= 3.0.0
✓ Node.js >= 16.0.0
✓ MySQL Server >= 8.0.0
✓ RAM: 4GB minimum
✓ Storage: 2GB free space
```

### 1️⃣ **Kiểm Tra Môi Trường**

```bash
# Kiểm tra Flutter & Dart
flutter doctor

# Kiểm tra Node.js
node --version
npm --version

# Kiểm tra MySQL
mysql --version
```

### 2️⃣ **Clone & Cài Đặt Dependencies**

```bash
# Clone repository
git clone <repository-url>
cd "CD2 BTL"

# Cài đặt Flutter packages
flutter pub get

# Cài đặt Node.js packages
cd server
npm install
cd ..
```

### 3️⃣ **Cấu Hình Database**

**Tạo database MySQL:**

```sql
-- Đăng nhập MySQL
mysql -u root -p

-- Tạo database (UTF-8 support cho tiếng Việt)
CREATE DATABASE code_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tạo user (tùy chọn)
CREATE USER 'code_app'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON code_app.* TO 'code_app'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4️⃣ **Cấu Hình Biến Môi Trường**

**Tạo file `server/.env`:**

```env
# Server Configuration
PORT=8080
HOST=0.0.0.0

# MySQL Database
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=code_app

# Admin Account (tạo khi server khởi động)
ADMIN_EMAIL=admin@admin.com
ADMIN_PASSWORD=admin123

# Dart SDK Path (tìm đường dẫn của Dart)
# Windows: where dart
# Linux/Mac: which dart
DART_PATH=C:\flutter\bin\cache\dart-sdk\bin\dart.exe
```

**Tìm đường dẫn Dart SDK:**

```bash
# Windows (PowerShell)
where dart

# Linux/Mac
which dart
```

### 5️⃣ **Chạy Server Backend**

```bash
cd server
node run_dart_server.js
```

**Kết quả thành công:**
```
✓ Server running at http://localhost:8080
✓ Database connected
✓ API endpoints ready
```

### 6️⃣ **Chạy Ứng Dụng Flutter**

**Terminal mới - chạy ứng dụng:**

```bash
# Chạy trên thiết bị/emulator mặc định
flutter run

# Chạy trên Android Emulator
flutter run -d emulator-5554

# Chạy trên Chrome (Web)
flutter run -d chrome --web-renderer canvaskit

# Chạy trên Windows Desktop
flutter run -d windows
```

---

## 📱 Các Platform Được Hỗ Trợ

| Platform | Status | Lệnh Chạy |
|----------|--------|-----------|
| Android | ✅ | `flutter run -d android` |
| iOS | ✅ | `flutter run -d ios` |
| Web | ✅ | `flutter run -d chrome` |
| Windows | ✅ | `flutter run -d windows` |
| macOS | ✅ | `flutter run -d macos` |
| Linux | ✅ | `flutter run -d linux` |

---

## 🔧 Các Tính Năng Chính Của Backend

### API Endpoints

| Method | Endpoint | Chức Năng |
|--------|----------|----------|
| `GET` | `/health` | Kiểm tra server |
| `POST` | `/run_dart` | Chạy code Dart |
| `POST` | `/api/auth/login` | Đăng nhập |
| `POST` | `/api/auth/register` | Đăng ký |
| `GET` | `/api/lessons` | Lấy danh sách bài học |
| `POST` | `/api/exercises` | Tạo bài tập |
| `GET` | `/api/progress` | Lấy tiến độ học |
| `POST` | `/api/progress` | Lưu tiến độ |

---

## 🐛 Khắc Phục Sự Cố

### ❌ Lỗi: Không kết nối server

```
Giải pháp:
✓ Kiểm tra server chạy tại port 8080
✓ Kiểm tra firewall cho phép port 8080
✓ Kiểm tra cấu hình `.env` đúng
✓ Restart server: Ctrl+C rồi chạy lại
```

### ❌ Lỗi: Code Dart không chạy

```
Giải pháp:
✓ Kiểm tra DART_PATH trong .env chính xác
✓ Chạy: dart --version (xem Dart SDK có tồn tại)
✓ Trên Windows: dùng đường dẫn đầy đủ (C:\...)
✓ Kiểm tra permissions của file Dart
```

### ❌ Lỗi: Không kết nối MySQL

```
Giải pháp:
✓ Kiểm tra MySQL service chạy
✓ Windows: Services.msc → MySQL80 (Start)
✓ Linux: sudo service mysql start
✓ Kiểm tra credentials trong .env
✓ Chạy: mysql -u root -p (thử đăng nhập)
```

### ❌ Lỗi: Flutter không nhận Android emulator

```
Giải pháp:
✓ Mở Android Emulator trước
✓ Chạy: flutter devices (xem danh sách)
✓ Chạy: flutter run
✓ Kiểm tra Android SDK PATH
```

---

## 🏗️ Build Cho Production

### Web Build
```bash
flutter build web --web-renderer canvaskit
# Output: build/web/
```

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Windows Installer
```bash
flutter build windows
# Output: build/windows/runner/Release/
```

---

## 📚 Cấu Trúc Dữ Liệu

### Database Tables

**users**
```
id | email | password | display_name | is_admin | created_at
```

**lessons**
```
id | title | content | code_example | created_at
```

**exercises**
```
id | title | description | difficulty | test_cases | created_at
```

**quiz**
```
id | title | description | questions | created_at
```

**fill_blank_exercises**
```
id | title | content | blanks | difficulty | created_at
```

**user_progress**
```
user_email | lesson_id | exercise_id | type | completed | completed_at
```

---

## 🤝 Hướng Dẫn Đóng Góp

1. **Fork** project
2. Tạo **feature branch** (`git checkout -b feature/YourFeature`)
3. **Commit** thay đổi (`git commit -m 'Add YourFeature'`)
4. **Push** branch (`git push origin feature/YourFeature`)
5. Tạo **Pull Request**

---

## 👥 Tác Giả

- [GitHub](https://github.com/duongx2004)

---








