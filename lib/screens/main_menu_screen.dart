import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'map_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'scene_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});


  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiClient.getProfile();
    if (result['success'] == true && mounted) {
      setState(() {
        _profile = result['data'];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // Список экранов теперь создается прямо здесь, а не в final переменной
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(profile: _profile), // Передаем свежий профиль
          const MapScreen(),
          const InventoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A0A),
          border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  iconPath: 'assets/images/ui/icon_home.png',
                  label: 'ДОМОЙ',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  iconPath: 'assets/images/ui/icon_map.png',
                  label: 'МИР',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  iconPath: 'assets/images/ui/icon_bag.png',
                  label: 'СУМКА',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  iconPath: 'assets/images/ui/icon_profile.png',
                  label: 'ПРОФИЛЬ',
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _HomeTab({this.profile});


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A), Color(0xFF2A0A0A)],
          ),
        ),
        child: Column(
          children: [
            // Верхняя панель со статами
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A0A0A),
                border: Border(bottom: BorderSide(color: Color(0xFF3A1A1A))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(width: 12),
                      // Убрали const у Column, так как внутри динамические данные
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?['username'] ?? 'Герой',
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Ур. ${profile?['level'] ?? 1}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Image.asset('assets/images/ui/icon_hp.png', width: 24, height: 24),
                      const SizedBox(width: 4),
                      Text('${profile?['health'] ?? 0}', style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 12),
                      Image.asset('assets/images/ui/icon_mp.png', width: 24, height: 24),
                      const SizedBox(width: 4),
                      Text('${profile?['mana'] ?? 0}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Image.asset('assets/images/ui/icon_home.png', width: 100, height: 100),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ТЕНЬ ДРЕВНИХ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Твоё приключение продолжается',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 50),

                    SizedBox(
                      width: 280,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SceneScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A0A0A),
                          foregroundColor: const Color(0xFFD4AF37),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 10,
                          shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                        ),
                        child: const Text(
                          'ПРОДОЛЖИТЬ СЮЖЕТ',
                          style: TextStyle(fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 32,
            height: 32,
            opacity: AlwaysStoppedAnimation(isSelected ? 1.0 : 0.4),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF4A3A3A),
            ),
          ),
        ],
      ),
    );
  }
}