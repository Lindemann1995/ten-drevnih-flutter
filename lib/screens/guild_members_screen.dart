import 'package:flutter/material.dart';
import '../services/api_client.dart';

class GuildMembersScreen extends StatefulWidget {
  const GuildMembersScreen({super.key});

  @override
  State<GuildMembersScreen> createState() => _GuildMembersScreenState();
}

class _GuildMembersScreenState extends State<GuildMembersScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _permissions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    
    // 1. Получаем права (из инфы о гильдии)
    final guildResult = await ApiClient.getMyGuild();
    if (guildResult['success'] == true) {
      _permissions = guildResult['data']['permissions'] ?? {};
    }

    // 2. Получаем участников
    final result = await ApiClient.getGuildMembers();

    if (result['success']) {
      setState(() {
        _members = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _kickMember(int playerId, String username) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        title: const Text('Исключить игрока?', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Text('Вы уверены, что хотите исключить $username?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Отмена', style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Исключить', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiClient.kickMember(playerId);
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Игрок исключен'), backgroundColor: Colors.green));
          _loadData(); // Перезагружаем
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Ошибка'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.white;
    final buffer = StringBuffer()..write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final canKick = _permissions['kick_members'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('УЧАСТНИКИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final m = _members[index];
                    final isLeader = m['rank'] == 'leader';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A0A),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Аватарка
                          const CircleAvatar(
                            backgroundColor: Color(0xFF0A0A0A),
                            child: Icon(Icons.person, color: Color(0xFFD4AF37)),
                          ),
                          const SizedBox(width: 12),
                          
                          // Имя и уровень
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['username'],
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Ур. ${m['level']}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          
                          // Ранг и взнос
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                m['rank_display'],
                                style: TextStyle(color: _parseColor(m['rank_color']), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Внёс: ${m['contributed_gold']}',
                                style: const TextStyle(color: Colors.amber, fontSize: 11),
                              ),
                            ],
                          ),

                          // 🆕 Кнопка кика (только если есть права и это не лидер)
                          if (canKick && !isLeader) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 20),
                              onPressed: () => _kickMember(m['player_id'], m['username']),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}