import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_client.dart';

class PrivateChatScreen extends StatefulWidget {
  final String friendUsername;
  final String myUsername;

  const PrivateChatScreen({super.key, required this.friendUsername, required this.myUsername});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  
  WebSocketChannel? _channel;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final result = await ApiClient.getPrivateMessages(widget.friendUsername);
    if (result['success']) {
      final List<dynamic> history = result['data']['messages'];
      setState(() {
        _messages.addAll(history.map((m) => {
          'sender': m['sender'],
          'message': m['message'],
          'created_at': m['created_at'],
          'is_mine': m['is_mine'],
        }).toList());
      });
      _scrollToBottom();
    }
  }

  void _connectWebSocket() async {
    final token = await ApiClient.getToken();
    if (token == null) return;

    // Обрати внимание: здесь путь /ws/chat/private/
    final wsUrl = 'wss://dev.api.code-nest.ru/ws/chat/private/?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        setState(() {
          _messages.add({
            'sender': data['sender'],
            'message': data['message'],
            'created_at': data['created_at'],
            'is_mine': data['sender'] == widget.myUsername,
          });
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

    _channel!.sink.add(jsonEncode({
      'receiver': widget.friendUsername, // <-- Кому отправляем
      'message': text
    }));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        title: Row(
          children: [
            Text('ЧАТ: ${widget.friendUsername}', style: const TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontSize: 18)),
            const SizedBox(width: 10),
            Icon(Icons.circle, size: 12, color: _isConnected ? Colors.green : Colors.red),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['is_mine'] == true;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A0A0A),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                            ),
                            child: const Icon(Icons.person, color: Colors.white54, size: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF8B0000).withValues(alpha: 0.4) : const Color(0xFF1A0A0A),
                              border: Border.all(color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF3A3A3A)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(msg['sender'], style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
                                if (!isMe) const SizedBox(height: 4),
                                Text(msg['message'], style: const TextStyle(color: Colors.white, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1A0A0A),
                border: Border(top: BorderSide(color: Color(0xFF3A3A3A))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Написать сообщение...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF0A0A0A),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isConnected ? const Color(0xFFD4AF37) : Colors.grey,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF0A0A0A), size: 20),
                      onPressed: _isConnected ? _sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}