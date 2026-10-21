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
    } else {
      print("ТОКЕНА НЕТ!");
    }
    return headers;
  }

  // Хелпер для безопасного парсинга ответов
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
        // Токен протух или его нет
        clearToken();
        return {'success': false, 'error': 'Сессия истекла. Войди заново.'};
      } else {
        return {
          'success': false, 
          'error': data['error'] ?? data['detail'] ?? 'Ошибка сервера (${response.statusCode})'
        };
      }
    } catch (e) {
      print("=== ОШИБКА ПАРСИНГА JSON: $e ===");
      print("=== СЫРОЙ ОТВЕТ СЕРВЕРА: ${response.body} ===");
      return {'success': false, 'error': 'Ошибка парсинга данных от сервера'};
    }
  }

  // ===== РЕГИСТРАЦИЯ =====
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
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

      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await saveToken(data['tokens']['access']);
        return {'success': true, 'data': data};
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {'success': false, 'error': _parseError(data)};
      }
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }

  // ===== ВХОД =====
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await saveToken(data['access']);
        return {'success': true, 'data': data};
      } else {
        // Пытаемся вытащить ошибку из ответа сервера
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return {'success': false, 'error': _parseError(data)};
        } catch (_) {
          return {'success': false, 'error': 'Неверный ник или пароль'};
        }
      }
    } catch (e) {
      // Обработка отсутствия интернета / таймаута
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }

  // ===== ПРОФИЛЬ =====
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/player/me/'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }

  // Парсим ошибки от сервера в читаемый текст
  static String _parseError(Map<String, dynamic> data) {
    if (data.containsKey('username')) return 'Ник: ${data['username'][0]}';
    if (data.containsKey('email')) return 'Email: ${data['email'][0]}';
    if (data.containsKey('password')) {
      final pwd = data['password'];
      if (pwd is List) return 'Пароль: ${pwd[0]}';
      return 'Пароль: $pwd';
    }
    if (data.containsKey('error')) return data['error'];
    if (data.containsKey('detail')) return data['detail'];
    return 'Неизвестная ошибка';
  }

  // ===== ТЕКУЩАЯ СЦЕНА =====
  static Future<Map<String, dynamic>> getCurrentScene() async {
    final response = await http.get(
      Uri.parse('$baseUrl/scene/current/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== СДЕЛАТЬ ВЫБОР =====
  static Future<Map<String, dynamic>> makeChoice(int choiceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scene/choose/'),
      headers: _headers,
      body: jsonEncode({'choice_id': choiceId}),
    );
    return _handleResponse(response);
  }

  // ===== СПИСОК КЛАССОВ =====
  static Future<Map<String, dynamic>> getClasses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/classes/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== ВЫБОР КЛАССА =====
  static Future<Map<String, dynamic>> chooseClass(int classId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/choose-class/'),
      headers: _headers,
      body: jsonEncode({'class_id': classId}),
    );
    return _handleResponse(response);
  }

  // ===== НАЧАТЬ БОЙ =====
  static Future<Map<String, dynamic>> startCombat(String enemySlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/start/'),
      headers: _headers,
      body: jsonEncode({'enemy_slug': enemySlug}),
    );

    // Особая логика для 400 (активный бой)
    if (response.statusCode == 400) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['combat_id'] != null) {
        return {'success': true, 'data': {'combat_id': data['combat_id'], 'existing': true}};
      }
    }
    return _handleResponse(response);
  }

  // ===== ДЕЙСТВИЕ В БОЮ =====
  static Future<Map<String, dynamic>> combatAction(int combatId, String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/$combatId/action/'),
      headers: _headers,
      body: jsonEncode({'action': action}),
    );
    return _handleResponse(response);
  }

  // ===== СОСТОЯНИЕ БОЯ =====
  static Future<Map<String, dynamic>> getCombatState(int combatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/combat/$combatId/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== СЛУЧАЙНЫЙ ВРАГ =====
  static Future<Map<String, dynamic>> huntInLocation(String locationSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/$locationSlug/hunt/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== БОСС =====
  static Future<Map<String, dynamic>> bossInLocation(String locationSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/$locationSlug/boss/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== ОТДЫХ =====
  static Future<Map<String, dynamic>> rest() async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/rest/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== ЗЕЛЬЯ ИГРОКА =====
  static Future<Map<String, dynamic>> getPotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/potions/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== ИСПОЛЬЗОВАТЬ ЗЕЛЬЕ =====
  static Future<Map<String, dynamic>> usePotion(String potionSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/use-potion/'),
      headers: _headers,
      body: jsonEncode({'potion_slug': potionSlug}),
    );
    return _handleResponse(response);
  }

  // ===== КУПИТЬ ЗЕЛЬЕ =====
  static Future<Map<String, dynamic>> buyPotion(String potionSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shop/buy-potion/'),
      headers: _headers,
      body: jsonEncode({'potion_slug': potionSlug}),
    );
    return _handleResponse(response);
  }

  // ===== ТОРГОВЦЫ В ЛОКАЦИИ =====
  static Future<Map<String, dynamic>> getTraders(String locationSlug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/$locationSlug/traders/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTraderItems(String traderSlug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/trader/$traderSlug/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> buyItem(String traderSlug, String itemSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trader/$traderSlug/buy/'),
      headers: _headers,
      body: jsonEncode({'item_slug': itemSlug}),
    );
    return _handleResponse(response);
  }

  // ===== ИНВЕНТАРЬ =====
  static Future<Map<String, dynamic>> getInventory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/inventory/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> equipItem(String itemSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/equip/'),
      headers: _headers,
      body: jsonEncode({'item_slug': itemSlug}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> unequipItem(String slot) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/unequip/'),
      headers: _headers,
      body: jsonEncode({'slot': slot}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEquipment() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/equipment/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ===== СПИСОК ВСЕХ ЛОКАЦИЙ =====
  static Future<Map<String, dynamic>> getLocations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/'), 
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLocationEnemies(String locationSlug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/location/$locationSlug/enemies/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> claimOfflineProgress() async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/offline-reward/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

    // ===== NPC И КВЕСТЫ =====
  static Future<Map<String, dynamic>> getNpc(String npcSlug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/npc/$npcSlug/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPlayerQuests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quests/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptQuest(int questId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quests/accept/'),
      headers: _headers,
      body: jsonEncode({'quest_id': questId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> completeQuest(int playerQuestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quests/complete/'),
      headers: _headers,
      body: jsonEncode({'player_quest_id': playerQuestId}),
    );
    return _handleResponse(response);
  }

    static Future<Map<String, dynamic>> getAllQuests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/quests/all/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }
}