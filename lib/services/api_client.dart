import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Адрес API (dev — пока dev, потом поменяем на прод)
  static const String baseUrl = 'https://dev.api.code-nest.ru/api/game';

  // Токен (для авторизованных запросов)
  static String? _token;

  // Загрузка токена из памяти телефона
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  // Сохранение токена
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Удаление токена (выход)
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // Есть ли токен?
  static bool get isAuthenticated => _token != null;

  // Заголовки для запросов
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ===== РЕГИСТРАЦИЯ =====
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201) {
      // Успех — сохраняем токен
      await saveToken(data['tokens']['access']);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': _parseError(data)};
    }
  }

  // ===== ВХОД =====
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      await saveToken(data['access']);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Неверный ник или пароль'};
    }
  }

  // ===== ПРОФИЛЬ =====
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/me/'),
      headers: _headers,
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Ошибка загрузки профиля'};
    }
  }

  // Парсим ошибки от сервера в читаемый текст
  static String _parseError(Map<String, dynamic> data) {
    if (data.containsKey('username')) {
      return 'Ник: ${data['username'][0]}';
    }
    if (data.containsKey('email')) {
      return 'Email: ${data['email'][0]}';
    }
    if (data.containsKey('password')) {
      final pwd = data['password'];
      if (pwd is List) return 'Пароль: ${pwd[0]}';
      return 'Пароль: $pwd';
    }
    if (data.containsKey('error')) {
      return data['error'];
    }
    return 'Неизвестная ошибка';
  }
    // ===== ТЕКУЩАЯ СЦЕНА =====
  static Future<Map<String, dynamic>> getCurrentScene() async {
    final response = await http.get(
      Uri.parse('$baseUrl/scene/current/'),
      headers: _headers,
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else if (response.statusCode == 401) {
      return {'success': false, 'error': 'Не авторизован. Войди заново.'};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка загрузки сцены'};
    }
  }

  // ===== СДЕЛАТЬ ВЫБОР =====
  static Future<Map<String, dynamic>> makeChoice(int choiceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scene/choose/'),
      headers: _headers,
      body: jsonEncode({'choice_id': choiceId}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка выбора'};
    }
  }

    // ===== СПИСОК КЛАССОВ =====
  static Future<Map<String, dynamic>> getClasses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/classes/'),
      headers: _headers,
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Ошибка загрузки классов'};
    }
  }

  // ===== ВЫБОР КЛАССА =====
  static Future<Map<String, dynamic>> chooseClass(int classId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/choose-class/'),
      headers: _headers,
      body: jsonEncode({'class_id': classId}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка выбора класса'};
    }
  }

    // ===== НАЧАТЬ БОЙ =====
  static Future<Map<String, dynamic>> startCombat(String enemySlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/start/'),
      headers: _headers,
      body: jsonEncode({'enemy_slug': enemySlug}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else if (response.statusCode == 400 && data['combat_id'] != null) {
      // Уже есть активный бой — возвращаем его
      return {'success': true, 'data': {'combat_id': data['combat_id'], 'existing': true}};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка старта боя'};
    }
  }

  // ===== ДЕЙСТВИЕ В БОЮ =====
  static Future<Map<String, dynamic>> combatAction(int combatId, String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/$combatId/action/'),
      headers: _headers,
      body: jsonEncode({'action': action}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка действия'};
    }
  }

  // ===== СОСТОЯНИЕ БОЯ =====
  static Future<Map<String, dynamic>> getCombatState(int combatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/combat/$combatId/'),
      headers: _headers,
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Ошибка загрузки боя'};
    }
  }
}