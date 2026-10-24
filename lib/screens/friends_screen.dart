import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'private_chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _onlineFriends = [];
  List<dynamic> _offlineFriends = [];
  List<dynamic> _requests = [];
  final TextEditingController _searchController = TextEditingController();
  
  String _myUsername = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });

    final profileResult = await ApiClient.getProfile();
    if (profileResult['success'] == true) {
      _myUsername = profileResult['data']['username'] ?? '';
    }

    final result = await ApiClient.getFriends();
    if (result['success']) {
      final allFriends = result['data']['friends'] as List? ?? [];
      setState(() {
        _onlineFriends = allFriends.where((f) => f['is_online'] == true).toList();
        _offlineFriends = allFriends.where((f) => f['is_online'] == false).toList();
        _requests = result['data']['incoming_requests'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    final username = _searchController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await ApiClient.sendFriendRequest(username);
    
    if (result['success']) {
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']['message'] ?? 'Заявка отправлена', style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Ошибка'), backgroundColor: Colors.red.shade800),
        );
      }
    }
    _loadData();
  }

  Future<void> _handleRequest(int requestId, bool accept) async {
    final result = accept 
        ? await ApiClient.acceptFriendRequest(requestId)
        : await ApiClient.declineFriendRequest(requestId);
        
    if (result['success']) {
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFriend(int friendshipId) async {
    final result = await ApiClient.removeFriend(friendshipId);
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Удален из друзей'), backgroundColor: Colors.orange),
        );
      }
      _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        elevation: 2,
        shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        title: const Text(
          'ДРУЗЬЯ', 
          style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 3, fontWeight: FontWeight.bold)
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
            onPressed: _loadData,
            tooltip: 'Обновить',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- ПОИСК ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Никнейм игрока...',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF1A0A0A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _sendRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Icon(Icons.person_add, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- ЗАЯВКИ ---
                      if (_requests.isNotEmpty) ...[
                        const Text('ВХОДЯЩИЕ ЗАЯВКИ', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._requests.map((r) => _buildRequestCard(r)),
                        const SizedBox(height: 24),
                      ],

                      // --- ОНЛАЙН ---
                      if (_onlineFriends.isNotEmpty) ...[
                        const Text('ОНЛАЙН', style: TextStyle(color: Colors.greenAccent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._onlineFriends.map((f) => _buildFriendCard(f, true)),
                        const SizedBox(height: 24),
                      ],

                      // --- ОФФЛАЙН ---
                      if (_offlineFriends.isNotEmpty) ...[
                        const Text('ОФФЛАЙН', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._offlineFriends.map((f) => _buildFriendCard(f, false)),
                      ],

                      if (_onlineFriends.isEmpty && _offlineFriends.isEmpty && _requests.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline, size: 60, color: Colors.white24),
                                SizedBox(height: 12),
                                Text('У тебя пока нет друзей :(', style: TextStyle(color: Colors.white38, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> f, bool isOnline) {
    return Dismissible(
      key: Key('friend_${f['friendship_id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A0A0A),
              title: const Text('Удалить друга?', style: TextStyle(color: Color(0xFFD4AF37))),
              content: Text('Вы уверены, что хотите удалить ${f['username']} из друзей?', style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _removeFriend(f['friendship_id']);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrivateChatScreen(
                friendUsername: f['username'],
                myUsername: _myUsername,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, 
              end: Alignment.bottomRight,
              colors: isOnline 
                  ? [const Color(0xFF1A0A0A), const Color(0xFF0A0A0A)]
                  : [const Color(0xFF151515), const Color(0xFF0A0A0A)],
            ),
            border: Border.all(
              color: isOnline ? const Color(0xFFD4AF37).withValues(alpha: 0.6) : const Color(0xFF3A3A3A),
              width: isOnline ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOnline ? const Color(0xFFD4AF37) : Colors.grey.shade700, 
                        width: 2
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF0A0A0A),
                      child: Icon(Icons.person, color: isOnline ? const Color(0xFFD4AF37) : Colors.white38, size: 22),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['username'], 
                      style: TextStyle(
                        color: isOnline ? const Color(0xFFD4AF37) : Colors.white70, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 16
                      )
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f['character_class'] ?? "Без класса"} (Ур. ${f['level']})', 
                      style: TextStyle(color: isOnline ? Colors.white54 : Colors.white30, fontSize: 12)
                    ),
                  ],
                ),
              ),
              // 🆕 Кнопка удаления (Корзина)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1A0A0A),
                        title: const Text('Удалить друга?', style: TextStyle(color: Color(0xFFD4AF37))),
                        content: Text('Вы уверены, что хотите удалить ${f['username']} из друзей?', style: const TextStyle(color: Colors.white)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена', style: TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      );
                    },
                  );
                  if (confirm == true) {
                    _removeFriend(f['friendship_id']);
                  }
                },
              ),
              // Иконка чата
              const Icon(Icons.chat_bubble_outline, color: Color(0xFFD4AF37), size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF3A3A3A),
            child: Icon(Icons.person, size: 18, color: Colors.white54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['from_username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${r['from_class'] ?? "Без класса"} (Ур. ${r['from_level']})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            onPressed: () => _handleRequest(r['request_id'], true),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
            onPressed: () => _handleRequest(r['request_id'], false),
          ),
        ],
      ),
    );
  }
}