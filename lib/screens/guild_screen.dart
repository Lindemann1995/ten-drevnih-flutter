import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'guild_create_screen.dart';
import 'guild_members_screen.dart';
import 'guild_treasury_screen.dart';
import 'guild_chat_screen.dart';
import 'guild_list_screen.dart';
import 'guild_applications_screen.dart';
import 'guild_bank_screen.dart';
import 'guild_upgrades_screen.dart';

class GuildScreen extends StatefulWidget {
  const GuildScreen({super.key});

  @override
  State<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends State<GuildScreen> {
  Map<String, dynamic>? _guildData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuild();
  }

  Future<void> _loadGuild() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiClient.getMyGuild();

    if (result['success']) {
      setState(() {
        _guildData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ГИЛЬДИЯ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 3, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }

    // Если не в гильдии
    if (_guildData == null || _guildData!['in_guild'] == false) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 20),
            const Text('Ты не состоишь в гильдии', style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A0A),
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFFD4AF37)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuildCreateScreen()),
                );
                if (result == true) _loadGuild();
              },
              child: const Text('СОЗДАТЬ ГИЛЬДИЮ', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildListScreen()));
                _loadGuild();
              },
              child: const Text('ИЛИ ВСТУПИТЬ В СУЩЕСТВУЮЩУЮ', style: TextStyle(color: Colors.white54, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      );
    }

    // Если в гильдии
    final g = _guildData!;
    final canManageApplications = g['permissions'] != null && g['permissions']['accept_members'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // КАРТОЧКА ГИЛЬДИИ
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
              ),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.15), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.shield, size: 60, color: Color(0xFFD4AF37)),
                const SizedBox(height: 10),
                Text('[${g['tag']}] ${g['name']}', 
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    border: Border.all(color: _parseColor(g['rank_color'])),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(g['rank_display'], 
                    style: TextStyle(color: _parseColor(g['rank_color']), fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Участники', '${g['members_count']}/30', Icons.people),
                    _buildStatColumn('Казна', '${g['treasury_gold']}', Icons.monetization_on),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // МЕНЮ УПРАВЛЕНИЯ (Сетка)
          const Text('УПРАВЛЕНИЕ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _buildActionIcon('👥', 'Состав', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildMembersScreen()));
              }),
              _buildActionIcon('💰', 'Казна', () async {
                final canWithdraw = g['permissions'] != null && g['permissions']['manage_treasury'] == true;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GuildTreasuryScreen(
                      currentTreasury: g['treasury_gold'],
                      canWithdraw: canWithdraw,
                    ),
                  ),
                );
                _loadGuild();
              }),
              _buildActionIcon('💬', 'Чат', () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuildChatScreen(
                    guildId: g['guild_id'],
                    myUsername: g['username'] ?? 'user',
                  )
                ));
              }),
              _buildActionIcon('🏦', 'Банк', () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GuildBankScreen(canWithdraw: g['permissions'] != null && g['permissions']['manage_treasury'] == true)
                ));
              }),
                            _buildActionIcon('⚒️', 'Кузня', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildUpgradesScreen()));
              }),
              if (canManageApplications)
                _buildActionIcon('📝', 'Заявки', () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildApplicationsScreen()));
                })
              else
                _buildActionIcon('⚙️', 'Настройки', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('В разработке')));
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String icon, String label, VoidCallback onTap) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0A).withValues(alpha: 0.8),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.white;
    final buffer = StringBuffer();
    buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}