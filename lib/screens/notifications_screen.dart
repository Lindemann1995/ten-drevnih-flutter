import 'package:flutter/material.dart';
import '../services/api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final result = await ApiClient.getNotifications();
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _notifications = result['data']['notifications'] ?? [];
        _isLoading = false;
      });
      ApiClient.markNotificationsRead();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        title: const Text('УВЕДОМЛЕНИЯ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _notifications.isEmpty
              ? const Center(child: Text('У вас пока нет уведомлений.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final isRead = note['is_read'] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead ? const Color(0xFF1A0A0A) : const Color(0xFF2A1A1A),
                        border: Border.all(color: isRead ? Colors.white12 : const Color(0xFFD4AF37).withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                note['title'] ?? 'Уведомление',
                                style: TextStyle(
                                  color: isRead ? Colors.white70 : const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                note['created_at'] ?? '',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note['message'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}