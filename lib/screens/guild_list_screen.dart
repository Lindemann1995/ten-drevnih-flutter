import 'package:flutter/material.dart';
import '../services/api_client.dart';

class GuildListScreen extends StatefulWidget {
  const GuildListScreen({super.key});

  @override
  State<GuildListScreen> createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen> {
  List<dynamic> _guilds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuilds();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заявка отправлена!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Возвращаемся на экран гильдии
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('СПИСОК ГИЛЬДИЙ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _guilds.isEmpty
              ? const Center(child: Text('Пока нет ни одной гильдии', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _guilds.length,
                  itemBuilder: (context, index) {
                    final g = _guilds[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A0A),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('[${g['tag']}] ${g['name']}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('Лидер: ${g['leader_username']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('Участников: ${g['members_count']} / 30', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B0000),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _apply(g['id'], g['name']),
                            child: const Text('ВСТУПИТЬ'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}