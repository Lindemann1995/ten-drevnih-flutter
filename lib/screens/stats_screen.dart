import 'package:flutter/material.dart';
import '../services/api_client.dart';

class StatsScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  final VoidCallback? onRefresh;

  const StatsScreen({super.key, this.initialProfile, this.onRefresh});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  bool _isUpgrading = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      _profile = widget.initialProfile;
      _isLoading = false;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiClient.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _profile = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _upgradeStat(String statKey) async {
    if (_isUpgrading) return;
    setState(() => _isUpgrading = true);

    final res = await ApiClient.upgradeStat(statKey);
    
    if (!mounted) return;
    setState(() => _isUpgrading = false);

    if (res['success'] == true) {
      setState(() {
        _profile![statKey] = res['data']['new_value'];
        _profile!['stat_points'] = res['data']['stat_points'];
      });
      if (widget.onRefresh != null) widget.onRefresh!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Ошибка'), backgroundColor: const Color(0xFF8B0000)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. ФОН
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ui/stats_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. ВИНЬЕТКА
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.4, 1.0],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // 3. КОНТЕНТ
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : Column(
                    children: [
                      // Шапка
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                              onPressed: () {
                                if (widget.onRefresh != null) widget.onRefresh!();
                                Navigator.pop(context);
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'СТАТИСТИКА',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                  letterSpacing: 4,
                                  fontFamily: 'serif',
                                  shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(2, 2))],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      
                      // Плашка со свободными очками
                      _buildPointsBanner(),

                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // 🆕 КВАДРАТНЫЕ ПЛИТКИ БАЗОВЫХ СТАТОВ
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSquareStatTile(
                                    title: 'Убийства',
                                    value: '${_profile?['enemies_killed'] ?? 0}',
                                    icon: Icons.local_fire_department,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSquareStatTile(
                                    title: 'Уровень',
                                    value: '${_profile?['level'] ?? 1}',
                                    icon: Icons.military_tech,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSquareStatTile(
                                    title: 'Золото',
                                    value: '${_profile?['gold'] ?? 0}',
                                    icon: Icons.monetization_on,
                                    color: const Color(0xFFD4AF37),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            Center(
                              child: Text(
                                'ХАРАКТЕРИСТИКИ',
                                style: TextStyle(
                                  color: const Color(0xFFD4AF37).withOpacity(0.8),
                                  fontSize: 16,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 🆕 СЕТКА ХАРАКТЕРИСТИК (2 КОЛОНКИ)
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3, // Чуть шире, чем высота
                              children: [
                                _buildStatTile('Сила', '${_profile?['strength'] ?? 0}', 'strength', Icons.fitness_center, Colors.redAccent),
                                _buildStatTile('Ловкость', '${_profile?['agility'] ?? 0}', 'agility', Icons.directions_run, Colors.greenAccent),
                                _buildStatTile('Интеллект', '${_profile?['intelligence'] ?? 0}', 'intelligence', Icons.psychology, Colors.blueAccent),
                                _buildStatTile('Выносливость', '${_profile?['endurance'] ?? 0}', 'endurance', Icons.shield, Colors.orangeAccent),
                                _buildStatTile('Рассудок', '${_profile?['sanity'] ?? 0}', 'sanity', Icons.visibility, Colors.purpleAccent),
                                // Пустой контейнер, чтобы сетка была ровной (если нечетное количество)
                                const SizedBox.shrink(), 
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 🆕 КВАДРАТНАЯ ПЛИТКА ДЛЯ БАЗОВЫХ СТАТОВ
  Widget _buildSquareStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0F0F), Color(0xFF0A0505)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 4)),
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 ПЛИТКА ДЛЯ ХАРАКТЕРИСТИК (с кнопкой +)
  Widget _buildStatTile(String title, String value, String statKey, IconData icon, Color color) {
    int points = _profile?['stat_points'] ?? 0;
    bool canUpgrade = points > 0 && !_isUpgrading;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0F0F), Color(0xFF0A0505)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, 4)),
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          // Золотой блик сверху
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 15,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 24),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Кнопка +
                    GestureDetector(
                      onTap: canUpgrade ? () => _upgradeStat(statKey) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: canUpgrade ? const Color(0xFF2A8B2A) : const Color(0xFF2A1A1A),
                          shape: BoxShape.circle,
                          border: Border.all(color: canUpgrade ? Colors.greenAccent : Colors.transparent),
                          boxShadow: canUpgrade ? [
                            BoxShadow(color: const Color(0xFF2A8B2A).withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
                          ] : [],
                        ),
                        child: Icon(
                          Icons.add, 
                          color: canUpgrade ? Colors.white : Colors.white24, 
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsBanner() {
    int points = _profile?['stat_points'] ?? 0;
    bool hasPoints = points > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasPoints 
              ? [const Color(0xFF3A0A0A), const Color(0xFF1A0A0A)] 
              : [const Color(0xFF1A0A0A), const Color(0xFF0A0A0A)],
        ),
        border: Border.all(
          color: hasPoints ? const Color(0xFFD4AF37) : Colors.white12, 
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: hasPoints ? [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 4,
          )
        ] : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: hasPoints ? const Color(0xFFD4AF37) : Colors.white24, size: 28),
              const SizedBox(width: 12),
              Text('Свободные очки:', style: TextStyle(color: hasPoints ? Colors.white : Colors.white54, fontSize: 16)),
            ],
          ),
          Text(
            '$points', 
            style: TextStyle(
              color: hasPoints ? const Color(0xFFD4AF37) : Colors.white38, 
              fontSize: 28, 
              fontWeight: FontWeight.bold,
              shadows: hasPoints ? [const Shadow(color: Colors.black, blurRadius: 10)] : [],
            )
          ),
        ],
      ),
    );
  }
}