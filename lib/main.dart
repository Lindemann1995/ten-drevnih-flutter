import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'screens/login_screen.dart'; 
import 'services/api_client.dart';

// Глобальный observer для отслеживания переходов между экранами
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadToken(); // Загружаем токен при старте

  runApp(const TenDrevnihApp());
}

class TenDrevnihApp extends StatelessWidget {
  const TenDrevnihApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Тень Древних',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF8B0000),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'serif',
      ),
      navigatorObservers: [routeObserver], 
      // УМНАЯ ПРОВЕРКА: Если токен есть -> Главное меню. Если нет -> Логин.
      home: ApiClient.isAuthenticated ? const MainMenuScreen() : const LoginScreen(),
    );
  }
}