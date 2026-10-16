import 'package:flutter/material.dart';
import 'scene_screen.dart';
import 'combat_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A), Color(0xFF2A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'КАРТА МИРА',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 4,
                  ),
                ),
              ),
              const Text(
                'Выбери, куда отправиться',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 30),

              // Локации
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _LocationCard(
                      title: 'Мир Древних',
                      subtitle: 'Рекомендуемый уровень: 1+',
                      icon: Icons.auto_awesome,
                      isAvailable: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SceneScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _LocationCard(
                      title: 'Деревня Кайроса',
                      subtitle: 'Откроется после обучения',
                      icon: Icons.home,
                      isAvailable: false,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),

                    _LocationCard(
                      title: 'Тёмный лес',
                      subtitle: 'Уровень 2+ • Волки, пауки, медведи',
                      icon: Icons.forest,
                      isAvailable: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CombatScreen(
                              enemySlug: 'forest_wolf',
                              enemyName: 'Лесной волк',
                            ),
                          ),
                        );
                      },
                    ),

                    _LocationCard(
                      title: 'Гробница Павшего Бога',
                      subtitle: 'Рекомендуемый уровень: 40+',
                      icon: Icons.castle,
                      isAvailable: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isAvailable;
  final VoidCallback onTap;

  const _LocationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? const Color(0xFFD4AF37) : Colors.white24;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          border: Border.all(
            color: isAvailable ? const Color(0xFF8B0000) : const Color(0xFF2A2A2A),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (!isAvailable)
              const Icon(Icons.lock, color: Colors.white24, size: 24),
          ],
        ),
      ),
    );
  }
}