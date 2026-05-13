import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:code_app/theme/app_theme.dart';
import 'package:code_app/services/progress_service.dart';
import 'package:code_app/services/auth_service.dart';
import 'package:code_app/services/backend_api.dart';
import 'package:code_app/screens/exercise_screen.dart';
import 'package:code_app/screens/home_screen.dart';
import 'package:code_app/screens/playground_screen.dart';
import 'package:code_app/screens/admin_screen.dart';
import 'package:code_app/screens/fill_blank_list_screen.dart';
import 'package:code_app/screens/auth/login_screen.dart';
import 'package:code_app/screens/auth/register_screen.dart';
import 'package:code_app/screens/profile/edit_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressService()),
      ],
      child: MaterialApp(
        title: 'CodeLearn',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/admin': (context) => const AdminScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn! ? const MainNavigation() : const LoginScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? _displayName;
  bool _isAdmin = false;
  final List<Widget> _screens = [
    const ExerciseScreen(),
    const HomeScreen(),
    const FillBlankListScreen(),
    const PlaygroundScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final name = await AuthService().getDisplayName();
    final admin = await AuthService().isAdmin();
    if (mounted) {
      setState(() {
        _displayName = name;
        _isAdmin = admin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.code, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'CodeLearn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          if (_displayName != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    _displayName!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.primaryColor),
            onSelected: (value) async {
              if (value == 'profile') {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
                if (updated == true) {
                  _loadDisplayName();
                }
              } else if (value == 'admin') {
                if (mounted) {
                  Navigator.pushNamed(context, '/admin');
                }
              } else if (value == 'logout') {
                await AuthService().logout();
                BackendApi.setUserEmail(null);
                Provider.of<ProgressService>(context, listen: false).onLogout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('Hồ sơ'),
                  ],
                ),
              ),
              if (_isAdmin)
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20),
                      SizedBox(width: 12),
                      Text('Admin Dashboard'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryLight,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            activeIcon: Icon(Icons.assignment, size: 28),
            label: "Bài tập code",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            activeIcon: Icon(Icons.school, size: 28),
            label: "Bài tập trắc nhiệm",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            activeIcon: Icon(Icons.text_fields, size: 28),
            label: "Điền chỗ trống",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code),
            activeIcon: Icon(Icons.code, size: 28),
            label: "Sân chơi dart",
          ),
        ],
      ),
    );
  }
}