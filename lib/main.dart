import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/screens/home_screen.dart';
import 'package:code_app/services/progress_service.dart';

void main() {
  // Đảm bảo các plugin (như SharedPreferences) được khởi tạo đúng
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ProgressService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // Bỏ const ở đây nếu HomeScreen() của bạn chưa có constructor const
      home: HomeScreen(),
    );
  }
}