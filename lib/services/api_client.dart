import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://api.code-nest.ru/api/game';
  static String? _token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static bool get isAuthenticated => _token != null;

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

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      } else if (response.statusCode == 401) {
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

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required bool privacyAccepted,
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
          'privacy_accepted': privacyAccepted, 
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
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return {'success': false, 'error': _parseError(data)};
        } catch (_) {
          return {'success': false, 'error': 'Неверный ник или пароль'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }

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

  static Future<Map<String, dynamic>> getCurrentScene() async {
    final response = await http.get(
      Uri.parse('$baseUrl/scene/current/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> makeChoice(int choiceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scene/choose/'),
      headers: _headers,
      body: jsonEncode({'choice_id': choiceId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getClasses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/classes/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> chooseClass(int classId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/choose-class/'),
      headers: _headers,
      body: jsonEncode({'class_id': classId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> startCombat(String enemySlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/start/'),
      headers: _headers,
      body: jsonEncode({'enemy_slug': enemySlug}),
    );

    if (response.statusCode == 400) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['combat_id'] != null) {
        return {'success': true, 'data': {'combat_id': data['combat_id'], 'existing': true}};
      }
    }
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> combatAction(int combatId, String action) async {
    final response = await http.post(
      Uri.parse('$baseUrl/combat/$combatId/action/'),
      headers: _headers,
      body: jsonEncode({'action': action}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCombatState(int combatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/combat/$combatId/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> huntInLocation(String locationSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/$locationSlug/hunt/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> bossInLocation(String locationSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/location/$locationSlug/boss/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> rest() async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/rest/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/player/potions/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> usePotion(String potionSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/player/use-potion/'),
      headers: _headers,
      body: jsonEncode({'potion_slug': potionSlug}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> buyPotion(String potionSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shop/buy-potion/'),
      headers: _headers,
      body: jsonEncode({'potion_slug': potionSlug}),
    );
    return _handleResponse(response);
  }

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

  static Future<Map<String, dynamic>> getNpcRecipes(String npcSlug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/npc/$npcSlug/recipes/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> learnRecipe(String scrollSlug) async {
    final response = await http.post(
      Uri.parse('$baseUrl/craft/learn/'),
      headers: _headers,
      body: jsonEncode({'scroll_slug': scrollSlug}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> craftItem(int recipeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/craft/create/'),
      headers: _headers,
      body: jsonEncode({'recipe_id': recipeId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPlayerScrolls() async {
    final response = await http.get(
      Uri.parse('$baseUrl/craft/scrolls/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static const String _guildUrl = 'https://api.code-nest.ru/api/guilds';

  static Future<Map<String, dynamic>> getMyGuild() async {
    final response = await http.get(Uri.parse('$_guildUrl/my/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createGuild(String name, String tag) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/create/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'tag': tag}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildMembers() async {
    final response = await http.get(Uri.parse('$_guildUrl/members/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> depositGuildGold(int amount) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/treasury/deposit/'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> withdrawGuildGold(int amount) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/treasury/withdraw/'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    return _handleResponse(response);
  }

  static Future<String?> getToken() async {
    return _token;
  }

  static Future<Map<String, dynamic>> getGuildChatHistory() async {
    final response = await http.get(Uri.parse('$_guildUrl/chat/history/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildList() async {
    final response = await http.get(Uri.parse('$_guildUrl/list/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> applyToGuild(int guildId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/apply/'),
      headers: _headers,
      body: jsonEncode({'guild_id': guildId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildApplications() async {
    final response = await http.get(Uri.parse('$_guildUrl/applications/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptGuildApplication(int appId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/applications/accept/'),
      headers: _headers,
      body: jsonEncode({'application_id': appId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> declineGuildApplication(int appId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/applications/decline/'),
      headers: _headers,
      body: jsonEncode({'application_id': appId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getBankItems() async {
    final response = await http.get(Uri.parse('$_guildUrl/bank/items/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> depositToBank(String itemSlug, int amount) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/bank/deposit/'),
      headers: _headers,
      body: jsonEncode({'item_slug': itemSlug, 'amount': amount}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> withdrawFromBank(String itemSlug, int amount) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/bank/withdraw/'),
      headers: _headers,
      body: jsonEncode({'item_slug': itemSlug, 'amount': amount}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildUpgrades() async {
    final response = await http.get(Uri.parse('$_guildUrl/upgrades/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> upgradeBuilding(String upgradeType) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/upgrades/upgrade/'),
      headers: _headers,
      body: jsonEncode({'upgrade_type': upgradeType}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCastles() async {
    final response = await http.get(Uri.parse('$_guildUrl/castles/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> startSiege(int castleId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/siege/start/'),
      headers: _headers,
      body: jsonEncode({'castle_id': castleId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> siegeAction(int siegeId, String action) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/siege/action/'),
      headers: _headers,
      body: jsonEncode({'siege_id': siegeId, 'action': action}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> collectTaxes() async {
    final response = await http.post(Uri.parse('$_guildUrl/castles/collect-taxes/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildUISettings() async {
    final response = await http.get(Uri.parse('$_guildUrl/ui-settings/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> challengeDuel(String username) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/duels/challenge/'),
      headers: _headers,
      body: jsonEncode({'username': username}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptDuel(int duelId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/duels/accept/'),
      headers: _headers,
      body: jsonEncode({'duel_id': duelId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> declineDuel(int duelId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/duels/decline/'),
      headers: _headers,
      body: jsonEncode({'duel_id': duelId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> duelAction(int duelId, String action) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/duels/action/'),
      headers: _headers,
      body: jsonEncode({'duel_id': duelId, 'action': action}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getActiveDuels() async {
    final response = await http.get(Uri.parse('$_guildUrl/duels/active/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getDuelStatus(int duelId) async {
    final response = await http.get(Uri.parse('$_guildUrl/duels/$duelId/status/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getGuildDailyQuests() async {
    final response = await http.get(Uri.parse('$_guildUrl/daily-quests/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> claimDailyQuest(int questId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/daily-quests/$questId/claim/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static const String _socialUrl = 'https://api.code-nest.ru/api/social';

  static Future<Map<String, dynamic>> getFriends() async {
    final response = await http.get(Uri.parse('$_socialUrl/friends/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendFriendRequest(String username) async {
    final response = await http.post(
      Uri.parse('$_socialUrl/friends/request/'),
      headers: _headers,
      body: jsonEncode({'username': username}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> acceptFriendRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$_socialUrl/friends/accept/'),
      headers: _headers,
      body: jsonEncode({'request_id': requestId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> declineFriendRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$_socialUrl/friends/decline/'),
      headers: _headers,
      body: jsonEncode({'request_id': requestId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPrivateMessages(String username) async {
    final response = await http.get(Uri.parse('$_socialUrl/messages/$username/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> removeFriend(int friendshipId) async {
    final response = await http.post(
      Uri.parse('$_socialUrl/friends/remove/'),
      headers: _headers,
      body: jsonEncode({'friendship_id': friendshipId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> promoteMember(int playerId, String rank) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/promote/'),
      headers: _headers,
      body: jsonEncode({'player_id': playerId, 'rank': rank}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> kickMember(int playerId) async {
    final response = await http.post(
      Uri.parse('$_guildUrl/kick/'),
      headers: _headers,
      body: jsonEncode({'player_id': playerId}),
    );
    return _handleResponse(response);
  }

  // ===== ПРОКАЧКА СТАТОВ =====
  static Future<Map<String, dynamic>> upgradeStat(String stat) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/player/upgrade-stat/'),
        headers: _headers,
        body: jsonEncode({'stat': stat}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }

  static Future<Map<String, dynamic>> reportPlayer({
    required String targetUsername,
    required String reason,
    String comment = '',
  }) async {
    print('=== ОТПРАВКА ЖАЛОБЫ ===');
    print('Токен: $_token');
    print('Заголовки: $_headers');
    print('Ник: $targetUsername, Причина: $reason');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/player/report/'),
        headers: _headers,
        body: jsonEncode({
          'target_username': targetUsername,
          'reason': reason,
          'comment': comment,
        }),
      );
      
      print('ОТВЕТ СЕРВЕРА: ${response.statusCode}');
      print('ТЕЛО ОТВЕТА: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('ОШИБКА СЕТИ: $e');
      return {'success': false, 'error': 'Ошибка сети: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/player/notifications/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> markNotificationsRead() async {
    final response = await http.post(Uri.parse('$baseUrl/player/notifications/read/'), headers: _headers);
    return _handleResponse(response);
  }

  static Future<int> getUnreadNotificationsCount() async {
    try {
      final result = await getNotifications();
      if (result['success'] == true) {
        final notes = result['data']['notifications'] as List;
        return notes.where((n) => n['is_read'] == false).length;
      }
    } catch (e) {
      // Игнорируем ошибку, если сервер недоступен
    }
    return 0;
  }
  static Future<Map<String, dynamic>> getChatHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }
  
    static Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/player/delete/'),
        headers: _headers,
        body: jsonEncode({'password': password}),
      );
      
      final result = _handleResponse(response);
      
      if (result['success'] == true) {
        await clearToken(); // Стираем JWT токен
      }
      
      return result;
    } catch (e) {
      return {'success': false, 'error': 'Ошибка соединения с сервером'};
    }
  }
}