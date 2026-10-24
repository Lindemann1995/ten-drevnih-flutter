import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_client.dart';

class GuildChatScreen extends StatefulWidget {
  final int guildId;
  final String myUsername;

  const GuildChatScreen({super.key, required this.guildId, required this.myUsername});

  @override
  State<GuildChatScreen> createState() => _GuildChatScreenState();
}

class _GuildChatScreenState extends State<GuildChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  
  WebSocketChannel? _channel;
  bool _isConnected = false;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _loadHistory();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final result = await ApiClient.getGuildChatHistory();
    if (result['success']) {
      final List<dynamic> history = result['data'];
      setState(() {
        _messages.addAll(history.reversed.map((m) {
          // 🆕 Парсим время из created_at (например, "2026-10-25T14:32:00Z" -> "14:32")
          String timeStr = '--:--';
          if (m['created_at'] != null) {
            try {
              final dt = DateTime.parse(m['created_at']).toLocal();
              timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
            } catch (e) {
              print("Ошибка парсинга времени: $e");
            }
          }
          
          return {
            'username': m['username'],
            'message': m['message'],
            'rank_color': m['rank_color'],
            'tag': m['tag'],
            'is_system': false,
            'time': timeStr, // <--- Теперь тут будет реальное время
          };
        }).toList());
      });
      _scrollToBottom();
    }
  }

  void _connectWebSocket() async {
    final token = await ApiClient.getToken();
    if (token == null) return;

    final wsUrl = 'wss://dev.api.code-nest.ru/ws/guild/${widget.guildId}/?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        
        // 🆕 Генерируем текущее время для новых сообщений
        final now = DateTime.now();
        final timeString = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

        setState(() {
          if (data['system'] == true) {
            _messages.add({
              'username': 'СИСТЕМА',
              'message': data['message'],
              'is_system': true,
              'time': timeString,
            });
          } else {
            _messages.add({
              'username': data['username'],
              'message': data['message'],
              'rank_color': data['rank_color'],
              'tag': data['tag'],
              'is_system': false,
              'time': timeString,
            });
          }
        });
        _scrollToBottom();
      },
      onDone: () => setState(() => _isConnected = false),
      onError: (e) => setState(() => _isConnected = false),
    );

    setState(() => _isConnected = true);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_isConnected) return;

    _channel!.sink.add(jsonEncode({'message': text}));
    _messageController.clear();
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

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.white70;
    final buffer = StringBuffer()..write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 🆕 ЭПИЧНЫЙ АНИМИРОВАННЫЙ ФОН
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_bgController.value * math.pi * 2) * 0.7,
                      math.cos(_bgController.value * math.pi * 2) * 0.7,
                    ),
                    radius: 2.0,
                    colors: const [
                      Color(0xFF3A0A0A),
                      Color(0xFF050505),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Кастомный AppBar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border(bottom: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.5)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'ЧАТ ГИЛЬДИИ',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          border: Border.all(color: _isConnected ? Colors.greenAccent : Colors.redAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _isConnected ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: _isConnected ? Colors.greenAccent : Colors.redAccent),
                            const SizedBox(width: 6),
                            Text(
                              _isConnected ? 'ONLINE' : 'OFFLINE',
                              style: TextStyle(
                                color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('Тишина... Начни беседу!', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];

                            if (msg['is_system'] == true) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0A0A).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      msg['message'],
                                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontStyle: FontStyle.italic),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final rankColor = _parseColor(msg['rank_color']);
                            final isMe = msg['username'] == widget.myUsername;
                            final displayName = isMe ? widget.myUsername : msg['username'];

                            // 🆕 Оборачиваем в анимацию появления
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(isMe ? 50 * (1 - value) : -50 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe) ...[
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: rankColor.withOpacity(0.4), blurRadius: 12, spreadRadius: 2)],
                                        ),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFF0A0A0A),
                                          child: Icon(Icons.person, color: rankColor, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: isMe 
                                                ? [const Color(0xFF8B0000).withOpacity(0.8), const Color(0xFF4A0000).withOpacity(0.8)]
                                                : [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
                                          ),
                                          border: Border.all(
                                            color: isMe ? const Color(0xFFD4AF37) : Colors.white12,
                                            width: isMe ? 1.5 : 1,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: const Radius.circular(20),
                                            topRight: const Radius.circular(20),
                                            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                          ),
                                          boxShadow: [
                                            if (isMe) BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5)),
                                            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 6, offset: const Offset(0, 3)),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            // 🆕 НИК И ВРЕМЯ
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (!isMe && msg['tag'] != null)
                                                  Text('[${msg['tag']}] ', style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 11)),
                                                if (!isMe && msg['rank_color'] == '#FFD700')
                                                  const Text('👑 ', style: TextStyle(fontSize: 12)),
                                                Text(
                                                  displayName, 
                                                  style: TextStyle(
                                                    color: isMe ? const Color(0xFFD4AF37) : rankColor, 
                                                    fontWeight: FontWeight.bold, 
                                                    fontSize: 13,
                                                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                                                  )
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  msg['time'] ?? '--:--',
                                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              msg['message'],
                                              style: const TextStyle(
                                                color: Colors.white, 
                                                fontSize: 15, 
                                                height: 1.4,
                                                // 🆕 Легкое свечение текста
                                                shadows: [Shadow(color: Colors.white24, blurRadius: 2)],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // 🆕 ПАРЯЩЕЕ ПОЛЕ ВВОДА
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A0A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, 8)),
                        BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 15, spreadRadius: 2),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              hintText: 'Написать в гильдию...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isConnected ? const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700)]) : null,
                            color: _isConnected ? null : Colors.grey,
                            boxShadow: _isConnected ? [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.6), blurRadius: 12)] : [],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.black, size: 20),
                            onPressed: _isConnected ? _sendMessage : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}