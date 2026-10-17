import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirm = _passwordConfirmController.text;

    // Валидация на клиенте
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Заполни все поля');
      return;
    }
    if (username.length < 3) {
      _showError('Ник должен быть минимум 3 символа');
      return;
    }
    if (password.length < 8) {
      _showError('Пароль должен быть минимум 8 символов');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('Пароль должен содержать хотя бы одну цифру');
      return;
    }
    if (password != passwordConfirm) {
      _showError('Пароли не совпадают');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiClient.register(
      username: username,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccess('Регистрация успешна!');
      // Показываем сообщение про email и переходим в меню
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      _showError(result['error'] ?? 'Ошибка регистрации');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[900],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[900],
      ),
    );
  }

  @override
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Заголовок
                const Text(
                  'РЕГИСТРАЦИЯ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Создай своего героя',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 40),

                // Ник
                _buildField(
                  controller: _usernameController,
                  label: 'Ник',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Email
                _buildField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Пароль
                _buildField(
                  controller: _passwordController,
                  label: 'Пароль',
                  icon: Icons.lock,
                  obscure: _obscurePassword,
                  toggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 16),

                // Подтверждение пароля
                _buildField(
                  controller: _passwordConfirmController,
                  label: 'Подтверждение пароля',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  toggleObscure: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
                const SizedBox(height: 30),

                // Кнопка регистрации
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A0A),
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD4AF37),
                            ),
                          )
                        : const Text(
                            'СОЗДАТЬ ГЕРОЯ',
                            style: TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Ссылка на вход
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Уже есть герой? Войти',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: const Color(0xFF8B0000)),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: toggleObscure,
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A1A1A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1A0A0A),
      ),
    );
  }
}