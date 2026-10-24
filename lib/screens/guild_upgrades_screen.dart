import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';
import 'dart:math' as math;

class GuildUpgradesScreen extends StatefulWidget {
  const GuildUpgradesScreen({super.key});

  @override
  State<GuildUpgradesScreen> createState() => _GuildUpgradesScreenState();
}

class _GuildUpgradesScreenState extends State<GuildUpgradesScreen> with TickerProviderStateMixin {
  List<dynamic> _upgrades = [];
  bool _isLoading = true;

  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Фон
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Пульсация для максимального уровня
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _loadUpgrades();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUpgrades() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getGuildUpgrades();
    if (result['success']) {
      setState(() {
        _upgrades = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _upgrade(String type, String name) async {
    final result = await ApiClient.upgradeBuilding(type);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name улучшено!'), 
          backgroundColor: Colors.green,
        ));
        _loadUpgrades();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error']), 
          backgroundColor: Colors.red,
        ));
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
                            'КУЗНЯ ГИЛЬДИИ',
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
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _upgrades.length,
                          itemBuilder: (context, index) {
                            return _buildUpgradeCard(_upgrades[index]);
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

  Widget _buildUpgradeCard(Map<String, dynamic> up) {
    final level = up['level'] as int;
    final maxLevel = level >= 3;
    final nextCost = up['next_level_cost'];

    // 🆕 Цвета в зависимости от уровня
    Color borderColor = const Color(0xFF3A3A3A);
    Color glowColor = Colors.transparent;
    if (level == 1) {
      borderColor = const Color(0xFFCD7F32); // Бронза
      glowColor = const Color(0xFFCD7F32).withOpacity(0.3);
    } else if (level == 2) {
      borderColor = const Color(0xFFC0C0C0); // Серебро
      glowColor = const Color(0xFFC0C0C0).withOpacity(0.4);
    } else if (level == 3) {
      borderColor = const Color(0xFFD4AF37); // Золото
      glowColor = const Color(0xFFD4AF37).withOpacity(0.6);
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = maxLevel ? 1.0 + (_pulseController.value * 0.02) : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A1A).withOpacity(0.9),
                  const Color(0xFF0A0A0A).withOpacity(0.9),
                ],
              ),
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (level > 0) BoxShadow(color: glowColor, blurRadius: maxLevel ? 20 : 10, spreadRadius: 2),
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                // Иконка и название
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A0A0A),
                          border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            if (level > 0) BoxShadow(color: glowColor, blurRadius: 10)
                          ],
                        ),
                        child: Text(up['icon'] ?? '🏰', style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        up['name'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: borderColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        up['description'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // 🆕 Полоска прогресса (звезды)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: level,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: level == 3 
                                  ? [const Color(0xFFFFD700), const Color(0xFFD4AF37)]
                                  : [borderColor.withOpacity(0.5), borderColor],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [if (level > 0) BoxShadow(color: glowColor, blurRadius: 8)],
                          ),
                        ),
                      ),
                      if (level < 3) Expanded(flex: 3 - level, child: const SizedBox()),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('УРОВЕНЬ $level / 3', style: TextStyle(color: borderColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                
                const Spacer(),

                // 🆕 Стоимость
                if (!maxLevel && nextCost != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${nextCost['gold']}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 2),
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                        
                        if (nextCost['item_name'] != null) ...[
                          const SizedBox(width: 8),
                          Container(width: 1, height: 12, color: Colors.white12),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: '${nextCost['item_name']}\n\n${nextCost['item_description'] ?? ''}',
                            triggerMode: TooltipTriggerMode.tap,
                            showDuration: const Duration(seconds: 3),
                            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0A0A),
                              border: Border.all(color: const Color(0xFFD4AF37)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  AssetPaths.forItem(nextCost['item_image'], nextCost['item_slug']),
                                  width: 16, height: 16,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.white70, size: 14),
                                ),
                                const SizedBox(width: 4),
                                Text('${nextCost['quantity']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                else if (maxLevel)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    ),
                    child: const Text('МАКС. УРОВЕНЬ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  )
                else
                  const SizedBox(height: 28),

                const SizedBox(height: 8),

                // 🆕 Кнопка "Улучшить"
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maxLevel ? Colors.transparent : const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: maxLevel ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.5), 
                            width: 1.5
                          ),
                        ),
                        elevation: maxLevel ? 0 : 5,
                        shadowColor: const Color(0xFF8B0000).withOpacity(0.5),
                      ),
                      onPressed: maxLevel ? null : () => _upgrade(up['type'], up['name']),
                      child: Text(
                        maxLevel ? 'ГОТОВО' : 'УЛУЧШИТЬ', 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: maxLevel ? const Color(0xFFD4AF37) : Colors.white,
                        )
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}