import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'guild_applications_screen.dart';
import 'guild_members_screen.dart';
import 'guild_treasury_screen.dart';
import 'guild_manage_ranks_screen.dart';

class GuildAdminPanelScreen extends StatefulWidget {
  final Map<String, dynamic> guildData;

  const GuildAdminPanelScreen({super.key, required this.guildData});

  @override
  State<GuildAdminPanelScreen> createState() => _GuildAdminPanelScreenState();
}

class _GuildAdminPanelScreenState extends State<GuildAdminPanelScreen> {
  // Получаем права из данных гильдии, переданных с прошлого экрана
  Map<String, dynamic> get perms => widget.guildData['permissions'] ?? {};
  String get rank => widget.guildData['rank'] ?? 'novice';

  @override
  Widget build(BuildContext context) {
    final isLeader = rank == 'leader';
    final isDeputy = rank == 'deputy';
    
    // Если зашел обычный игрок
    if (!isLeader && !isDeputy) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
          title: const Text('ДОСТУП ЗАКРЫТ', style: TextStyle(color: Colors.redAccent)),
        ),
        body: const Center(
          child: Text('У вас нет прав для доступа к этой панели.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Фоновое свечение
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [Color(0xFF2A0A0A), Color(0xFF050505)],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Кастомная шапка
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
                            'ШТАБ КОМАНДОВАНИЯ',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Плашка с ролью
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              Icon(isLeader ? Icons.star : Icons.security, color: const Color(0xFFD4AF37), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                isLeader ? 'ВЫ — ЛИДЕР ГИЛЬДИИ' : 'ВЫ — ЗАМЕСТИТЕЛЬ',
                                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLeader ? 'Вы обладаете полными правами управления.' : 'Часть функций ограничена правами лидера.',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text('УПРАВЛЕНИЕ', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Сетка кнопок
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            // Заявки (Лидер и Зам)
                            if (perms['accept_members'] == true)
                              _buildAdminButton(
                                Icons.pending_actions, 
                                'ЗАЯВКИ', 
                                'Принимайте новых бойцов в гильдию.',
                                Colors.blueAccent, 
                                () async {
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildApplicationsScreen()));
                                }
                              ),

                            // Состав/Кик (Лидер и Зам)
                            if (perms['kick_members'] == true)
                              _buildAdminButton(
                                Icons.person_remove, 
                                'СОСТАВ', 
                                'Исключайте нарушителей.',
                                Colors.redAccent, 
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildMembersScreen()))
                              ),

                            // Казна (Лидер и Зам)
                            if (perms['manage_treasury'] == true)
                              _buildAdminButton(
                                Icons.monetization_on, 
                                'КАЗНА', 
                                'Управляйте золотом гильдии.',
                                Colors.amber, 
                                () => Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => GuildTreasuryScreen(
                                    currentTreasury: widget.guildData['treasury_gold'] ?? 0,
                                    canWithdraw: true,
                                  ))
                                )
                              ),

                            // Ранги (ТОЛЬКО Лидер)
                            if (perms['manage_ranks'] == true)
                              _buildAdminButton(
                                Icons.workspace_premium, 
                                'РАНГИ', 
                                'Назначайте заместителей.',
                                Colors.purpleAccent, 
                                () {
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (_) => const GuildManageRanksScreen())
                                  );
                                }
                              ),
                          ],
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

  Widget _buildAdminButton(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title, 
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: const TextStyle(color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}