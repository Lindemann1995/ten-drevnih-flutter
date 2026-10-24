import 'package:flutter/material.dart';
import '../services/api_client.dart';

class GuildManageRanksScreen extends StatefulWidget {
  const GuildManageRanksScreen({super.key});

  @override
  State<GuildManageRanksScreen> createState() => _GuildManageRanksScreenState();
}

class _GuildManageRanksScreenState extends State<GuildManageRanksScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getGuildMembers();
    if (result['success']) {
      setState(() {
        _members = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _changeRank(int playerId, String newRank) async {
    final result = await ApiClient.promoteMember(playerId, newRank);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ранг изменен!'), backgroundColor: Colors.green));
        _loadMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('УПРАВЛЕНИЕ РАНГАМИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontSize: 16)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final m = _members[index];
                final rank = m['rank'];
                final isLeader = rank == 'leader';
                final username = m['username'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Аватарка
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0A0A0A),
                        child: Text(username[0].toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37))),
                      ),
                      const SizedBox(width: 12),
                      // Имя и текущий ранг
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text(m['rank_display'] ?? rank, style: TextStyle(color: isLeader ? Colors.amber : Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Кнопки назначения (только если не лидер)
                      if (!isLeader) ...[
                        IconButton(
                          tooltip: 'Сделать Ветераном',
                          icon: const Icon(Icons.military_tech, color: Colors.orangeAccent),
                          onPressed: () => _changeRank(m['player_id'], 'veteran'),
                        ),
                        IconButton(
                          tooltip: 'Сделать Замом',
                          icon: const Icon(Icons.shield, color: Colors.purpleAccent),
                          onPressed: () => _changeRank(m['player_id'], 'deputy'),
                        ),
                        IconButton(
                          tooltip: 'Разжаловать в Новички',
                          icon: const Icon(Icons.arrow_downward, color: Colors.grey),
                          onPressed: () => _changeRank(m['player_id'], 'novice'),
                        ),
                      ] else
                        const Icon(Icons.lock, color: Colors.amber, size: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}