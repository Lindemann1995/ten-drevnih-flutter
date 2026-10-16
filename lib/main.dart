import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';


void main() {
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
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A0A0A),
              Color(0xFF2A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Логотип — пока текст
                const Icon(
                  Icons.auto_awesome,
                  size: 80,
                  color: Color(0xFF8B0000),
                ),
                const SizedBox(height: 20),

                // Название игры
                const Text(
                  'ТЕНЬ ДРЕВНИХ',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Color(0xFF8B0000),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Подзаголовок
                const Text(
                  'Текстовая RPG в мире мёртвых богов',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 60),

                // Кнопки меню
                _MenuButton(
                  text: 'ВОЙТИ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _MenuButton(
                  text: 'РЕГИСТРАЦИЯ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // Версия
                const Text(
                  'v0.0.3 • Quill & Blade Games',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A0A0A),
          foregroundColor: const Color(0xFFD4AF37),
          side: const BorderSide(color: Color(0xFF8B0000), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}