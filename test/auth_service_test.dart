import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:code_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService Unit Test', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
    });

    test('Đăng ký người dùng mới thành công', () async {
      final result = await authService.register('test@gmail.com', '123456', 'Tester');
      expect(result, true);
      
      // Đăng ký lại cùng email phải thất bại
      final resultDuplicate = await authService.register('test@gmail.com', '654321', 'Tester 2');
      expect(resultDuplicate, false);
    });

    test('Đăng nhập đúng tài khoản mật khẩu', () async {
      await authService.register('user@gmail.com', 'password', 'User');
      
      final loginSuccess = await authService.login('user@gmail.com', 'password');
      expect(loginSuccess, true);
      
      final isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, true);
      
      final displayName = await authService.getDisplayName();
      expect(displayName, 'User');
    });

    test('Đăng nhập sai mật khẩu phải thất bại', () async {
      await authService.register('user@gmail.com', 'password', 'User');
      
      final loginFail = await authService.login('user@gmail.com', 'wrong_pass');
      expect(loginFail, false);
    });

    test('Cập nhật hồ sơ (Display Name)', () async {
      await authService.register('user@gmail.com', 'password', 'Old Name');
      await authService.login('user@gmail.com', 'password');
      
      final updateSuccess = await authService.updateProfile('New Name');
      expect(updateSuccess, true);
      
      final newName = await authService.getDisplayName();
      expect(newName, 'New Name');
    });

    test('Đăng xuất xóa sạch thông tin phiên làm việc', () async {
      await authService.register('user@gmail.com', 'password', 'User');
      await authService.login('user@gmail.com', 'password');
      
      await authService.logout();
      
      final isLoggedIn = await authService.isLoggedIn();
      expect(isLoggedIn, false);
      expect(await authService.getDisplayName(), isNull);
    });
  });
}
