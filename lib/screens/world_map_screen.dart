import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';
import 'combat_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  bool _isLoading = true;
  String? _error;
  
  List<dynamic> _locations = [];
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadLocations() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiClient.getLocations();
    
    if (!mounted) return;
    if (result['success'] == true) {
      final locs = result['data'] as List;
      setState(() {
        _locations = locs;
        if (locs.isNotEmpty) {
          _selectedLocation = locs.first;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _selectLocation(dynamic loc) {
    if (_selectedLocation?['id'] == loc['id']) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedLocation = loc);
  }

  void _showEnemyDetails(dynamic enemy) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1A1A), Color(0xFF0A0A0A)], // Эффект старой кожи
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8B0000), width: 2), // Багровая рамка
            boxShadow: [
              BoxShadow(color: const Color(0xFF000000).withOpacity(0.8), blurRadius: 30, spreadRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Мистический ореол
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.6), blurRadius: 30, spreadRadius: 10)],
                      ),
                    ),
                    // Портрет в золотой рамке
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                        image: DecorationImage(
                          image: AssetImage(AssetPaths.forItem(enemy['image_path'], enemy['slug'])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(enemy['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'serif', letterSpacing: 1.5)),
              ),
              Center(
                child: Text('Уровень: ${enemy['level']}', style: const TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic)),
              ),
              const Divider(color: Color(0xFF8B0000), height: 40, thickness: 1.5),
              Text(enemy['description'] ?? 'Описание отсутствует.', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6, fontStyle: FontStyle.italic)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CombatScreen(enemySlug: enemy['slug'], enemyName: enemy['name']),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                    elevation: 10,
                    shadowColor: Colors.black,
                  ),
                  child: const Text('ВСТУПИТЬ В БОЙ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFF0A0A0A), body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }
    if (_error != null) {
      return Scaffold(backgroundColor: const Color(0xFF0A0A0A), body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // 1. ДРЕВНИЙ КАМЕНЬ (Фон)
          Positioned.fill(
            child: CustomPaint(painter: AncientStonePainter()),
          ),
          
          // 2. ЭФФЕКТ ВИНЬЕТКИ (Затемнение по краям для атмосферы)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.6, 1.0],
                  radius: 1.0,
                ),
              ),
            ),
          ),

          // 3. ОСНОВНОЙ КОНТЕНТ
          SafeArea(
            child: Column(
              children: [
                // Заголовок (как старинная вывеска)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Text(
                    'ВЫБОР ЛОКАЦИИ',
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: const Color(0xFFD4AF37), 
                      letterSpacing: 4,
                      fontFamily: 'serif',
                      shadows: [
                        Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(2, 2)),
                      ],
                    ),
                  ),
                ),
                
                Expanded(
                  child: Row(
                    children: [
                      // ЛЕВАЯ ПАНЕЛЬ (Свитки локаций)
                      Container(
                        width: 130,
                        margin: const EdgeInsets.only(left: 16, bottom: 16),
                        child: ListView.builder(
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            final loc = _locations[index];
                            final isSelected = _selectedLocation?['id'] == loc['id'];
                            return GestureDetector(
                              onTap: () => _selectLocation(loc),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isSelected 
                                        ? [const Color(0xFF3A0A0A), const Color(0xFF1A0A0A)]
                                        : [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 5)),
                                    if (isSelected) BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 15, spreadRadius: 2),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.location_on, color: isSelected ? const Color(0xFFD4AF37) : Colors.white30, size: 28),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Ур.${loc['min_level']}+', style: TextStyle(color: isSelected ? Colors.white70 : Colors.white30, fontSize: 10)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ПРАВАЯ ПАНЕЛЬ (Карточки мобов)
                      Expanded(
                        child: _selectedLocation == null 
                            ? const Center(child: Text('Выберите локацию', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)))
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: ListView.builder(
                                  key: ValueKey(_selectedLocation!['id']),
                                  padding: const EdgeInsets.only(left: 8, right: 16, bottom: 16),
                                  itemCount: _selectedLocation!['enemies'].length,
                                  itemBuilder: (context, index) {
                                    final enemy = _selectedLocation!['enemies'][index];
                                    return _buildEnemyCard(enemy, index);
                                  },
                                ),
                              ),
                      ),
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

  // 🆕 КАРТОЧКА МОБА (Свиток/Талыш)
  Widget _buildEnemyCard(dynamic enemy, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _showEnemyDetails(enemy),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12), 
          decoration: BoxDecoration(
            // Текстура старой кожи
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1A1A), Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 10, offset: const Offset(0, 6)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Золотой блик сверху
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [const Color(0xFFD4AF37).withOpacity(0.1), Colors.transparent],
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
                        children: [
                          // Портрет в бронзовой рамке
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF8B0000), width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
                              image: DecorationImage(
                                image: AssetImage(AssetPaths.forItem(enemy['image_path'], enemy['slug'])),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(enemy['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                                const SizedBox(height: 4),
                                Text('Уровень ${enemy['level']}', style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Статы
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBlock(Icons.favorite, '${enemy['health']}', Colors.redAccent),
                          _buildStatBlock(Icons.gavel, '${enemy['attack']}', Colors.orangeAccent),
                          _buildStatBlock(Icons.shield, '${enemy['defense']}', Colors.blueGrey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Награды
                      Row(
                        children: [
                          _buildRewardText(Icons.star, '+${enemy['xp_reward']} XP', Colors.greenAccent),
                          const SizedBox(width: 12),
                          _buildRewardText(Icons.monetization_on, '+${enemy['gold_reward']}', const Color(0xFFD4AF37)),
                        ],
                      ),
                      
                      // Лут
                      if (enemy['loot'] != null && enemy['loot'].isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: enemy['loot'].map<Widget>((loot) {
                            return Container(
                              width: 32, height: 32,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                border: Border.all(color: const Color(0xFF3A1A1A)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Image.asset(
                                AssetPaths.forItem(loot['image_path'], loot['slug']),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 14, color: Colors.white30),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBlock(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRewardText(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// 🆕 ДРЕВНИЙ КАМЕНЬ (Реалистичная грубая кладка)
class AncientStonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()..color = const Color(0xFF050505); // Раствор
    final paintStone = Paint()..color = const Color(0xFF141414); // Темный камень

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBase);

    final rnd = math.Random(99); 
    
    double blockH = 80; // Крупные блоки
    double blockW = 120; 

    for (double y = 0; y < size.height; y += blockH) {
      double offsetX = (y ~/ blockH) % 2 == 0 ? 0 : -blockW / 2;

      for (double x = offsetX; x < size.width; x += blockW) {
        double dx = rnd.nextDouble() * 6 - 3;
        double dy = rnd.nextDouble() * 6 - 3;
        
        Rect blockRect = Rect.fromLTWH(x + dx, y + dy, blockW - 6, blockH - 6);
        
        // Сам блок
        canvas.drawRRect(
          RRect.fromRectAndRadius(blockRect, const Radius.circular(2)),
          paintStone,
        );

        // Блик сверху (объем)
        canvas.drawLine(
          Offset(blockRect.left, blockRect.top),
          Offset(blockRect.right, blockRect.top),
          Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 2,
        );

        // Глубокая тень снизу
        canvas.drawLine(
          Offset(blockRect.left, blockRect.bottom),
          Offset(blockRect.right, blockRect.bottom),
          Paint()..color = Colors.black.withOpacity(0.8)..strokeWidth = 4,
        );

        // Трещины (если повезет)
        if (rnd.nextDouble() < 0.3) {
          final crackPaint = Paint()
            ..color = Colors.black.withOpacity(0.8)
            ..strokeWidth = 1.5;
          
          Path crack = Path();
          crack.moveTo(blockRect.left + rnd.nextDouble() * blockW, blockRect.top + rnd.nextDouble() * blockH);
          crack.lineTo(blockRect.left + rnd.nextDouble() * blockW, blockRect.top + rnd.nextDouble() * blockH);
          canvas.drawPath(crack, crackPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}