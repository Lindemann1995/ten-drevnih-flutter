import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'dart:math' as math;

class GuildListScreen extends StatefulWidget {
  const GuildListScreen({super.key});

  @override
  State<GuildListScreen> createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen> with TickerProviderStateMixin {
  List<dynamic> _guilds = [];
  bool _isLoading = true;
  
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    
    _loadGuilds();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadGuilds() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getGuildList();
    if (result['success']) {
      setState(() {
        _guilds = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _apply(int guildId, String guildName) async {
    final result = await ApiClient.applyToGuild(guildId);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Заявка в "$guildName" отправлена!'), 
            backgroundColor: Colors.green,
          )
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 🆕 Анимированный фон
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_bgController.value * math.pi * 2) * 0.5,
                      math.cos(_bgController.value * math.pi * 2) * 0.5,
                    ),
                    radius: 1.5,
                    colors: const [
                      Color(0xFF1A0A0A),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'СПИСОК ГИЛЬДИЙ',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : _guilds.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_outlined, size: 80, color: Colors.white24),
                                  SizedBox(height: 16),
                                  Text('Пока нет ни одной гильдии', style: TextStyle(color: Colors.white54, fontSize: 16)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: _guilds.length,
                              itemBuilder: (context, index) {
                                final g = _guilds[index];
                                return _buildGuildCard(g, index);
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildCard(Map<String, dynamic> g, int index) {
    final bool isFull = (g['members_count'] ?? 0) >= 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.9),
            const Color(0xFF0A0A0A).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, 5)),
          if (index == 0) BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          // 🆕 Щит гильдии
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0A0A),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 15)],
            ),
            child: const Center(child: Icon(Icons.shield, color: Color(0xFFD4AF37), size: 32)),
          ),
          const SizedBox(width: 16),
          
          // Информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '[${g['tag']}] ${g['name']}',
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text('Лидер: ${g['leader_username']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, color: isFull ? Colors.redAccent : Colors.greenAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Состав: ${g['members_count']} / 30', 
                      style: TextStyle(color: isFull ? Colors.redAccent : Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 🆕 Кнопка "Вступить"
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFull ? Colors.grey.shade800 : const Color(0xFF8B0000),
              foregroundColor: isFull ? Colors.white54 : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isFull ? Colors.transparent : const Color(0xFFD4AF37).withOpacity(0.5), width: 1),
              ),
              elevation: isFull ? 0 : 5,
              shadowColor: const Color(0xFF8B0000).withOpacity(0.5),
            ),
            onPressed: isFull ? null : () => _apply(g['id'], g['name']),
            child: Text(
              isFull ? 'ПОЛНО' : 'ВСТУПИТЬ',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}