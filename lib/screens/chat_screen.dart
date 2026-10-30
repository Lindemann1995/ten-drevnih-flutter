import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/api_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  String _myUsername = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadHistory(); // 🆕 Загружаем историю при открытии
    ChatService().connect((msg) {
      if (mounted) {
        msg['time'] = _formatServerTime(msg['created_at']);
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMe() async {
    final result = await ApiClient.getProfile();
    if (result['success'] == true && mounted) {
      setState(() {
        _myUsername = result['data']['username'] ?? 'Игрок';
      });
    }
  }

  Future<void> _loadHistory() async {
    final result = await ApiClient.getChatHistory();
    if (result['success'] == true && mounted) {
      final raw = List<Map<String, dynamic>>.from(result['data']['messages'] ?? []);
      for (final m in raw) {
        m['time'] = _formatServerTime(m['created_at']) != '--:--'
            ? _formatServerTime(m['created_at'])
            : (m['time'] ?? '--:--');
      }
      setState(() {
        _messages.clear();
        _messages.addAll(raw);
      });
      _scrollToBottom();
    }
  }

    /// Парсит ISO-8601 из БД (UTC) и возвращает локальное время HH:mm.
  /// Если поле отсутствует/битое — возвращает '--:--'.
  String _formatServerTime(dynamic isoString) {
    if (isoString is! String || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    ChatService().sendMessage(_controller.text.trim(), _myUsername);
    _controller.clear();
  }

  Color _getRoleColor(String role) {
    if (role == 'admin') return Colors.red;
    if (role == 'vip') return const Color(0xFFD4AF37);
    if (role == 'guild_leader') return Colors.purple;
    return const Color(0xFFD4AF37);
  }

  @override
  void dispose() {
    ChatService().dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: OverflowBox(
              minHeight: screenHeight,
              maxHeight: screenHeight,
              alignment: Alignment.topCenter,
              child: Image.asset(
                'assets/images/ui/chat_panel.png',
                fit: BoxFit.cover,
                height: screenHeight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 60, bottom: 10),
                    child: Text(
                      'ГЛОБАЛЬНЫЙ ЧАТ',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                      child: _messages.isEmpty
                          ? const Center(child: Text('Пока нет сообщений...', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final roleColor = _getRoleColor(msg['role'] ?? 'player');
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0A0A).withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF3A1A1A), width: 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: roleColor, width: 2),
                                          color: Colors.black,
                                        ),
                                        child: const Icon(Icons.person, color: Colors.white54),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Профиль ${msg['username']} (в разработке)')),
                                                    );
                                                  },
                                                  child: Text(
                                                    msg['username'],
                                                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                ),
                                                Text(
                                                  msg['time'] ?? '--:--',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              msg['message'],
                                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40, bottom: 60),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Сообщение...',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFFD4AF37), size: 22),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}