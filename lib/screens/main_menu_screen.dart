import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import 'map_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'news_screen.dart';
import 'scene_screen.dart';
import 'hunt_screen.dart';
import 'stats_screen.dart';
import 'craft_screen.dart';
import 'trade_world_screen.dart';
import 'world_map_screen.dart'; // 🆕 Импортируем наш новый экран локаций
import '../main.dart';
import 'quest_list_screen.dart';
import 'guild_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with RouteAware {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  int _profileKey = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkOfflineReward(); 
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
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

  Future<void> _checkOfflineReward() async {
    final result = await ApiClient.claimOfflineProgress();
    if (result['success'] == true) {
      if (!mounted) return;
      _showOfflineRewardDialog(result['data']);
    }
  }

  void _showOfflineRewardDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '⏳ ПОКА ТЕБЯ НЕ БЫЛО',
          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ты отсутствовал ${data['hours']} ч.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 60),
            const SizedBox(height: 10),
            Text(
              '+${data['gold_earned']} золота',
              style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadProfile(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0A0A0A),
              ),
              child: const Text('ЗАБРАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/ui/main_menu_bg.png'), 
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _HomeTab(
              profile: _profile, 
              onRefresh: _loadProfile,
              onNavigate: (index) {
                setState(() {
                  _currentIndex = index; 
                  if (index == 3) _profileKey++; 
                });
              },
            ),
            const MapScreen(), // Пока оставляем старую карту для вкладки "МИР"
            const ChatScreen(), 
            ProfileScreen(key: ValueKey(_profileKey)), 
          ],
        ),
        
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.85),
            border: const Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1)),
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
                    iconPath: 'assets/images/ui/icon_chat.png', 
                    label: 'ЧАТ',
                    isSelected: _currentIndex == 2,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  _NavItem(
                    iconPath: 'assets/images/ui/icon_news.png', 
                    label: 'ПРОФИЛЬ', 
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() {
                      _currentIndex = 3;
                      _profileKey++; 
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onRefresh; 
  final Function(int) onNavigate;

  const _HomeTab({
    this.profile, 
    required this.onRefresh,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final username = profile?['username'] ?? 'Герой';
    final level = profile?['level'] ?? 1;
    final className = profile?['character_class']?['name'] ?? 'Без класса';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF1A0A0A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ШАПКА ПРОФИЛЯ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$className (Ур. $level)',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        
                        // КРАСИВАЯ ПОЛОСКА ОПЫТА
                        _buildExpBar(
                          profile?['experience'] ?? 0, 
                          profile?['experience_to_next'] ?? 100
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildTopIcon('🎉', 'События', () => _showComingSoon(context, 'События')),
                      const SizedBox(width: 8),
                      _buildTopIcon('👥', 'Друзья', () => _showComingSoon(context, 'Друзья')),
                      const SizedBox(width: 8),
                      _buildTopIcon('⚙️', 'Настройки', () => _showComingSoon(context, 'Настройки')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // --- ВАШИ ПРИКЛЮЧЕНИЯ ---
              const Text(
                'ВАШИ ПРИКЛЮЧЕНИЯ',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0, 
                children: [
                  _buildGridButton('📜', 'ЗАДАНИЯ', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestListScreen()));
                  }),
                  _buildGridButton('🎭', 'ПРОФИЛЬ', () {
                    onNavigate(3); 
                  }),
                  _buildGridButton('🏰', 'ГИЛЬДИИ', () {
                    Navigator.push(
       
                      context,
                      MaterialPageRoute(builder: (_) => const GuildScreen()),
                    );
                  }),
                  _buildGridButton('🕸️', 'ПОДЗЕМЕЛЬЯ', () => _showComingSoon(context, 'Подземелья')),
                  _buildGridButton('🎒', 'СНАРЯЖЕНИЕ', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                  }),
                  _buildGridButton('📊', 'СТАТЫ ИГРОКА', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
                  }),
                ],
              ),
              const SizedBox(height: 25),

              // --- БЫСТРЫЕ ДЕЙСТВИЯ ---
              const Text(
                'БЫСТРЫЕ ДЕЙСТВИЯ',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // 🆕 ОБНОВЛЕННЫЙ БЛОК БЫСТРЫХ ДЕЙСТВИЙ (Сеткой 4 в ряд)
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.8,
                children: [
                  // ОХОТА
                  _buildQuickAction('🐺', 'ОХОТА', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HuntScreen()),
                    );
                  }),
                  // ЛОКАЦИИ (новая вкладка)
                  _buildQuickAction('🗺️', 'ЛОКАЦИИ', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorldMapScreen()),
                    );
                  }),
                  // ТОРГОВЛЯ
                  _buildQuickAction('🛒', 'ТОРГОВЛЯ', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TradeWorldScreen()),
                    );
                  }),
                  // КУЗНИЦА (КРАФТ)
                  _buildQuickAction('⚒️', 'КУЗНИЦА', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CraftScreen(
                          npcSlug: 'koval',
                          npcName: 'Коваль',
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpBar(int currentExp, int maxExp) {
    final percent = maxExp > 0 ? (currentExp / maxExp).clamp(0.0, 1.0) : 0.0;
    final remaining = maxExp - currentExp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 16,
          width: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A), 
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5), 
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percent),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '$currentExp / $maxExp',
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'До ур. осталось: $remaining',
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, color: Color(0xFFD4AF37), size: 60),
            const SizedBox(height: 20),
            Text(
              '$featureName скоро появятся!',
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Мы уже работаем над этим. Следи за обновлениями в новостях!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('ПОНЯТНО', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon(String icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37), width: 1),
          ),
          child: Text(icon, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60, 
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A0A).withOpacity(0.8),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1), 
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(String icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A).withOpacity(0.8),
          border: Border.all(color: const Color(0xFF3A1A1A), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
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
            errorBuilder: (context, error, stackTrace) => Icon(
              label == 'ДОМОЙ' ? Icons.home : 
              label == 'МИР' ? Icons.map : 
              label == 'ЧАТ' ? Icons.chat : Icons.person,
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF4A3A3A),
              size: 28,
            ),
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