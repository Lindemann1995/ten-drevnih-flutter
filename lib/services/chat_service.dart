import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  
  Function(Map<String, dynamic>)? _onMessageCallback;

  void connect(Function(Map<String, dynamic>) onMessage) {
    _onMessageCallback = onMessage;
    _connect();
  }

  void _connect() {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      print("ПОДКЛЮЧАЮСЬ К ЧАТУ...");
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://dev.api.code-nest.ru/ws/chat/'), // Твой адрес
      );

      _channel!.stream.listen(
        (message) {
          _isConnecting = false;
          final data = jsonDecode(message);
          if (_onMessageCallback != null) {
            _onMessageCallback!(data);
          }
        },
        onError: (error) {
          print("!!! ОШИБКА WEBSOCKET: $error");
          _reconnect();
        },
        onDone: () {
          print("!!! WEBSOCKET ЗАКРЫТ. Переподключаюсь...");
          _reconnect();
        },
      );
    } catch (e) {
      print("!!! ОШИБКА ПОДКЛЮЧЕНИЯ: $e");
      _reconnect();
    }
  }

  void _reconnect() {
    if (_channel != null) {
      _channel!.sink.close();
    }
    _isConnecting = false;
    
    // Пытаемся переподключиться каждые 3 секунды
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _connect();
    });
  }

  void sendMessage(String message, String username) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode({
        'message': message,
        'username': username,
      }));
    } catch (e) {
      print("Ошибка отправки: $e");
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _onMessageCallback = null;
  }
}