# Code App - Ứng dụng Học Lập Trình Dart

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-16+-339933?style=flat&logo=node.js)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=flat&logo=mysql)](https://mysql.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Ứng dụng học lập trình Dart toàn diện với giao diện trực quan, hỗ trợ đa nền tảng (Android, iOS, Web, Desktop). Kết hợp lý thuyết, thực hành code, quiz kiểm tra và sân chơi lập trình trực tiếp.

## ✨ Tính năng nổi bật

### 🎓 Học tập tương tác
- **Bài học có cấu trúc**: Lý thuyết, code mẫu, bài tập thực hành
- **Chạy code trực tiếp**: Xem kết quả code mẫu ngay trong bài học
- **Quiz kiểm tra**: Đánh giá kiến thức với câu hỏi trắc nghiệm
- **Tiến độ học tập**: Theo dõi bài học đã hoàn thành

### 💻 Sân chơi lập trình (Playground)
- **Soạn thảo code**: Editor với syntax highlighting
- **Chạy code realtime**: Thực thi code Dart qua server backend
- **Output trực quan**: Xem kết quả và lỗi ngay lập tức
- **Hỗ trợ offline**: Chạy server local khi không có internet

### 📝 Hệ thống bài tập đa dạng
- **Bài tập code**: Viết code giải quyết vấn đề với test cases
- **Bài tập trắc nghiệm**: Câu hỏi đa lựa chọn với giải thích
- **Bài tập điền chỗ trống**: Hoàn thành code với nhiều đáp án đúng

### 👨‍💼 Quản trị viên
- **Quản lý người dùng**: Xem, chỉnh sửa, xóa tài khoản
- **Quản lý nội dung**: Thêm/sửa bài học, bài tập
- **Thống kê**: Theo dõi tiến độ học tập của users

### 📱 Responsive Design
- **Đa nền tảng**: Android, iOS, Web, Windows Desktop
- **Adaptive UI**: Tự động điều chỉnh theo kích thước màn hình
- **Touch & Mouse**: Hỗ trợ tương tác chuột và bàn phím

## 🛠️ Công nghệ sử dụng

### Frontend (Flutter)
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **State Management**: Provider
- **Storage**: SharedPreferences
- **UI Components**: Material Design 3
- **Code Editor**: code_text_field + flutter_highlight
- **Networking**: HTTP client

### Backend (Node.js)
- **Runtime**: Node.js 16+
- **Server**: Express.js
- **Database**: MySQL2
- **Security**: CORS, Input validation
- **Code Execution**: child_process (sandboxed)

### Database
- **MySQL 8.0+**: Relational database
- **Tables**: users, lessons, exercises, progress, etc.

## 📋 Yêu cầu hệ thống

- **Flutter SDK**: >= 3.0.0
- **Dart SDK**: >= 2.19.0
- **Node.js**: >= 16.0.0
- **MySQL Server**: >= 8.0.0
- **RAM**: 4GB minimum
- **Storage**: 2GB free space

## 🚀 Cài đặt và chạy

### 1. Chuẩn bị môi trường

```bash
# Kiểm tra Flutter
flutter doctor

# Kiểm tra Node.js
node --version && npm --version

# Kiểm tra MySQL
mysql --version
```

### 2. Clone và cài đặt

```bash
# Clone repository
git clone <repository-url>
cd code_app

# Cài đặt Flutter dependencies
flutter pub get

# Cài đặt Node.js dependencies
cd server
npm install
cd ..
```

### 3. Cấu hình database

```sql
-- Tạo database
CREATE DATABASE code_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Tạo user (tùy chọn)
CREATE USER 'code_app'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON code_app.* TO 'code_app'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Cấu hình biến môi trường

Sao chép và chỉnh sửa file `server/.env`:

```env
# Server config
PORT=8080
HOST=0.0.0.0

# Database config
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=code_app

# Admin account
ADMIN_EMAIL=admin@admin.com
ADMIN_PASSWORD=admin123

# Dart SDK path (điều chỉnh theo hệ thống)
DART_PATH=C:\flutter\bin\cache\dart-sdk\bin\dart.exe
```

**Tìm đường dẫn Dart SDK:**
- Windows: `where dart`
- Linux/Mac: `which dart`

### 5. Chạy server backend

```bash
cd server
node run_dart_server.js
```

Server sẽ khởi động tại `http://localhost:8080`

### 6. Chạy ứng dụng Flutter

```bash
# Chạy trên thiết bị mặc định
flutter run

# Chạy trên Android
flutter run -d android

# Chạy trên Web
flutter run -d chrome --web-renderer canvaskit

# Chạy trên Windows
flutter run -d windows
```

## 📁 Cấu trúc dự án

```
code_app/
├── 📱 lib/                          # Flutter source code
│   ├── 🏗️ models/                   # Data models
│   ├── 🎨 screens/                  # UI screens
│   │   ├── 🏠 home_screen.dart       # Home dashboard
│   │   ├── 📖 lesson_screen.dart     # Lesson content
│   │   ├── 💻 playground_screen.dart # Code playground
│   │   ├── 👨‍💼 admin_screen.dart     # Admin panel
│   │   └── 🔐 auth/                  # Authentication
│   ├── 🔧 services/                 # API services
│   ├── 🧱 widgets/                  # Reusable widgets
│   │   ├── 📝 code_editor.dart       # Code editor widget
│   │   └── 📊 responsive_scaffold.dart # Adaptive layout
│   ├── 🎭 theme/                    # App theming
│   └── 📦 main.dart                 # App entry point
├── 🖥️ server/                       # Node.js backend
│   ├── 🚀 run_dart_server.js       # Main server file
│   ├── 📋 package.json             # Dependencies
│   ├── ⚙️ .env                     # Environment config
│   └── 🗄️ migrations/              # Database migrations
├── 🎨 assets/                      # Static assets
│   ├── 🖼️ images/                  # Images
│   └── 📚 data/                    # JSON data files
├── 📋 exercise_templates.json      # Exercise templates
├── 📖 EXERCISE_TEMPLATES_README.md # Template usage guide
├── 🧪 test/                        # Unit tests
├── 📱 android/                     # Android config
├── 🖥️ windows/                     # Windows config
├── 🌐 web/                        # Web config
└── 📄 README.md                    # This file
```

## 🔗 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | Health check |
| `POST` | `/run_dart` | Execute Dart code |
| `GET/POST` | `/api/auth/login` | User authentication |
| `GET/POST` | `/api/users` | User management |
| `GET/POST` | `/api/lessons` | Lesson management |
| `GET/POST` | `/api/exercises` | Exercise management |
| `GET/POST` | `/api/progress` | Progress tracking |

## 📚 File mẫu bài tập

Dự án bao gồm các file mẫu và hướng dẫn:

- **🔧 Code Exercises**: 10 mẫu bài tập lập trình với code mẫu hoàn chỉnh có thể chạy được
- **📝 Quiz Questions**: 3 mẫu câu hỏi trắc nghiệm với giải thích
- **📝 Fill Blank Exercises**: 2 mẫu bài tập điền chỗ trống
- **📖 EXERCISE_TEMPLATES_README.md**: Hướng dẫn sử dụng các mẫu
- **📋 EXERCISE_CREATION_GUIDE.md**: Hướng dẫn chi tiết cách điền thông tin tạo bài tập

### Các bài tập lập trình có sẵn:
1. **Hello World** - In ra "Hello, World!"
2. **Tính tổng hai số** - Nhận 2 số, in tổng
3. **Dãy Fibonacci** - In n số Fibonacci đầu tiên
4. **Kiểm tra số nguyên tố** - Kiểm tra số nguyên tố
5. **Đảo ngược chuỗi** - Đảo ngược chuỗi ký tự
6. **Sắp xếp mảng** - Sắp xếp mảng số nguyên
7. **Kiểm tra palindrome** - Chuỗi đối xứng
8. **Tính giai thừa** - Tính n!
9. **Tìm kiếm nhị phân** - Binary search
10. **Nhân ma trận** - Nhân hai ma trận vuông

### Cách import bài tập mẫu:

```bash
# Chạy server backend trước
cd server
node run_dart_server.js

# Trong terminal khác, import bài tập
node import_exercises.js
```

Xem hướng dẫn chi tiết trong `EXERCISE_TEMPLATES_README.md` và `EXERCISE_CREATION_GUIDE.md`

## 🏗️ Build cho Production

```bash
# Build Web
flutter build web --web-renderer canvaskit

# Build Windows
flutter build windows

# Build Android APK
flutter build apk --release

# Build iOS (trên macOS)
flutter build ios --release
```

## 🐛 Troubleshooting

### Lỗi kết nối server
- Kiểm tra server có chạy tại port 8080
- Kiểm tra firewall không block port
- Verify `.env` config đúng

### Lỗi chạy code
- Đảm bảo `DART_PATH` trong `.env` chính xác
- Kiểm tra Dart SDK đã cài đặt
- Test chạy `dart --version` trong terminal

### Lỗi database
- Đảm bảo MySQL service đang chạy
- Kiểm tra credentials trong `.env`
- Verify database và tables đã tạo

## 🤝 Đóng góp

1. Fork project
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👥 Tác giả

- **DuongX** - *Initial work* - [GitHub](https://github.com/duongx2004)

## 

- Flutter team for the amazing framework
- Node.js community for the robust runtime
- MySQL team for the reliable database
- All contributors and users of this project

---








