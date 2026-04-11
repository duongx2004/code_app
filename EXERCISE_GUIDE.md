# Hướng dẫn: Chức năng Bài tập Dart

## 📝 Tổng quan
Chức năng Bài tập Dart cho phép người dùng thực hành lập trình Dart bằng cách:
1. Đọc mô tả bài tập chi tiết
2. Xem input/output format
3. Viết code Dart tương ứng
4. Chạy code và kiểm tra kết quả với các test case được cấp sẵn

## 📂 Cấu trúc file tạo mới

```
lib/
├── models/
│   └── exercise_model.dart        # Model cho bài tập
├── screens/
│   ├── exercise_screen.dart       # Danh sách bài tập
│   └── exercise_detail_screen.dart # Chi tiết bài tập & code editor
├── services/
│   └── exercise_service.dart      # Service load & kiểm tra bài tập
└── widgets/
    └── code_editor.dart           # Widget code editor

assets/
└── data/
    └── exercises.json             # Dữ liệu bài tập
```

## 🎯 Các bài tập có sẵn

1. **EX1: Tính tổng các chữ số** (Cơ bản)
   - Tính tổng chữ số trong một số

2. **EX2: In hình tam giác sao** (Cơ bản)
   - In hình tam giác từ dấu sao

3. **EX3: Kiểm tra số chẵn lẻ** (Cơ bản)
   - Xác định số là chẵn hay lẻ

4. **EX4: Tìm số lớn nhất trong 3 số** (Cơ bản)
   - So sánh 3 số để tìm max

5. **EX5: Tính giai thừa** (Trung bình)
   - Tính n!

## ⚙️ Cách sử dụng

### 1. Thêm bài tập mới
Chỉnh sửa file `assets/data/exercises.json`:
```json
{
  "id": "ex6",
  "title": "Tên bài tập",
  "description": "Mô tả chi tiết...",
  "input": "Định dạng input",
  "output": "Định dạng output",
  "difficulty": "cơ bản|trung bình|nâng cao",
  "time_limit": 30,
  "hint": "// Gợi ý code",
  "test_cases": [
    {
      "input": "5",
      "output": "120"
    }
  ]
}
```

### 2. Cập nhật logic kiểm tra
Trong `_checkTestCase()` của `exercise_detail_screen.dart`:
```dart
if (widget.exercise.id == 'ex6') {
  // Thêm logic kiểm tra cho bài tập mới
  try {
    // Xử lý input & so sánh output
    return result == testCase.expectedOutput;
  } catch (e) {
    return false;
  }
}
```

## 🚀 Tính năng hiện tại

✅ Danh sách bài tập với filter theo mức độ
✅ Mô tả chi tiết & định dạng input/output
✅ Code editor có hỗ trợ syntax
✅ Kiểm tra tự động với multiple test cases
✅ Gợi ý code khi cần
✅ Phản hồi kết quả (✅ pass / ❌ fail)

## 🔄 Cải tiến trong tương lai

1. **Backend Dart Execution**
   - Gửi code tới server để chạy thực
   - Bảo mật hơn, hỗ trợ tất cả bài tập

2. **Lưu tiến trình**
   - Lưu code đã viết
   - Theo dõi bài tập đã hoàn thành

3. **Leaderboard**
   - So sánh kết quả giữa người dùng
   - Thời gian chiến thắng

4. **Bài tập phức tạp hơn**
   - Classes, Streams, Futures
   - Regex, JSON parsing

5. **Code style feedback**
   - Kiểm tra theo chuẩn Dart conventions
   - Gợi ý tối ưu hóa code

## 📖 Ví dụ: Thêm bài tập FizzBuzz

```json
{
  "id": "ex6",
  "title": "FizzBuzz",
  "description": "Viết program in từ 1 đến n, nhưng:\n- In 'Fizz' nếu chia hết cho 3\n- In 'Buzz' nếu chia hết cho 5\n- In 'FizzBuzz' nếu chia hết cho 15\n- Không thì in số đó",
  "input": "Một số nguyên n",
  "output": "In kết quả FizzBuzz từ 1 đến n",
  "difficulty": "trung bình",
  "test_cases": [
    {
      "input": "15",
      "output": "1\\n2\\nFizz\\n4\\nBuzz\\nFizz\\n7\\n8\\nFizz\\nBuzz\\n11\\nFizz\\n13\\n14\\nFizzBuzz"
    }
  ]
}
```

Sau đó thêm logic check:
```dart
if (widget.exercise.id == 'ex6') {
  // FizzBuzz logic
  StringBuffer result = StringBuffer();
  int n = int.parse(testCase.input);
  for (int i = 1; i <= n; i++) {
    if (i % 15 == 0) {
      result.writeln('FizzBuzz');
    } else if (i % 3 == 0) {
      result.writeln('Fizz');
    } else if (i % 5 == 0) {
      result.writeln('Buzz');
    } else {
      result.writeln(i);
    }
  }
  return result.toString().trim() == testCase.expectedOutput;
}
```

## 🎓 Tips cho người học

1. Bắt đầu từ bài tập "Cơ bản"
2. Đọc kỹ mô tả & ví dụ input/output
3. Sử dụng "Gợi ý" nếu cần
4. Chạy code để kiểm tra từng test case
5. Tối ưu code sau khi hoàn thành

## 🐛 Debug

Nếu bài tập không load:
1. Kiểm tra `assets/data/exercises.json` có hợp lệ không
2. Kiểm tra import/export trong `models.dart`
3. Xem console log có error gì không

---
**Tác giả**: nhuan
**Ngày tạo**: 2026-04-07
**Phiên bản**: 1.0
