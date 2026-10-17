import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';
import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadToken();
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
      // ВСЕГДА открываем Хаб. Если токена нет — Хаб сам покажет кнопку входа.
      home: const MainMenuScreen(),
    );
  }
}