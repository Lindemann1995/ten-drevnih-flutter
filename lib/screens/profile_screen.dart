import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';
import 'dart:math' as math;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;
  
  late AnimationController _bgController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiClient.getProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _profile = result['data'];
        _isLoading = false;
      });
      _entranceController.forward(from: 0);
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _showClassSelection() {
    ApiClient.getClasses().then((result) {
      if (result['success'] == true) {
        final classes = result['data'] as List<dynamic>;
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF0A0A0A),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  const Text('ВЫБЕРИ СВОЙ ПУТЬ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 2)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final cls = classes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [const Color(0xFF1A0A0A), const Color(0xFF0A0A0A)]),
                            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            title: Text(cls['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(cls['description'] ?? 'Нет описания', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final res = await ApiClient.chooseClass(cls['id']);
                                if (res['success'] == true) {
                                  Navigator.pop(context);
                                  _loadProfile();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Ошибка')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('ВЫБРАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
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
                      Color(0xFF2A0A0A),
                      Color(0xFF050505),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                : _error != null
                    ? _buildError()
                    : _buildProfile(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFF8B0000), size: 60),
          const SizedBox(height: 20),
          Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('ПОВТОРИТЬ'),
          ),
        ],
      ),
    );
  }

  // 🆕 ИСПРАВЛЕНО: Добавлено значение по умолчанию для delay
   // Функция для плавного появления (ИСПРАВЛЕНО: теперь delay — именованный аргумент)
  Widget _animatedEntrance(Widget child, {double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final progress = _entranceController.value;
        final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(adjustedProgress);
        
        return Transform.translate(
          offset: Offset(0, 50 * (1 - curve)),
          child: Opacity(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final p = _profile!;
    final username = p['username'] ?? 'Игрок';
    final level = p['level'] ?? 1;
    final experience = p['experience'] ?? 0;
    final experienceToNext = p['experience_to_next'] ?? 100;
    final health = p['health'] ?? 100;
    final maxHealth = p['max_health'] ?? 100;
    final mana = p['mana'] ?? 50;
    final maxMana = p['max_mana'] ?? 50;
    final gold = p['gold'] ?? 0;
    
    final classData = p['character_class'];
    final hasClass = classData != null;
    final className = hasClass ? classData['name'] : 'Не выбран';
    final classDescription = hasClass ? (classData['description'] ?? '') : '';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A0A0A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _animatedEntrance(
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFF1A0A0A),
                      child: const Icon(Icons.person, size: 60, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      letterSpacing: 2,
                      shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 10)],
                    ),
                  ),
                  Text(
                    'УРОВЕНЬ $level',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              delay: 0.0,
            ),
            
            const SizedBox(height: 30),

            _animatedEntrance(
              GestureDetector(
                onTap: _showClassSelection,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.1), blurRadius: 20)
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(hasClass ? '🎭' : '❓', style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ВАШ КЛАСС', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                            const SizedBox(height: 4),
                            Text(
                              hasClass ? className : 'ВЫБРАТЬ КЛАСС',
                              style: TextStyle(
                                color: hasClass ? const Color(0xFFD4AF37) : Colors.redAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasClass && classDescription.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(classDescription, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                    ],
                  ),
                ),
              ),
              delay: 0.1,
            ),
            
            const SizedBox(height: 20),

            _animatedEntrance(
              Column(
                children: [
                  _buildModernBar('ОПЫТ', experience, experienceToNext, const Color(0xFFD4AF37), Icons.star),
                  const SizedBox(height: 12),
                  _buildModernBar('ЗДОРОВЬЕ', health, maxHealth, const Color(0xFFFF4D4D), Icons.favorite),
                  const SizedBox(height: 12),
                  _buildModernBar('МАНА', mana, maxMana, const Color(0xFF4D4DFF), Icons.water_drop),
                ],
              ),
              delay: 0.2,
            ),
            
            const SizedBox(height: 24),

            _animatedEntrance(
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ХАРАКТЕРИСТИКИ', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatChip('💪', 'Сила', p['strength'] ?? 0),
                        _buildStatChip('🏃', 'Ловкость', p['agility'] ?? 0),
                        _buildStatChip('🧠', 'Интеллект', p['intelligence'] ?? 0),
                        _buildStatChip('🛡', 'Выносливость', p['endurance'] ?? 0),
                        _buildStatChip('👁', 'Рассудок', p['sanity'] ?? 0),
                        _buildStatChip('💰', 'Золото', gold, isGold: true),
                      ],
                    ),
                  ],
                ),
              ),
              delay: 0.3,
            ),

            const SizedBox(height: 30),

            _animatedEntrance(
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                        _loadProfile();
                      },
                      icon: const Icon(Icons.backpack, size: 24),
                      label: const Text('ИНВЕНТАРЬ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: TextButton.icon(
                      onPressed: () async {
                        await ApiClient.clearToken(); 
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('ВЫЙТИ ИЗ АККАУНТА', style: TextStyle(fontSize: 14, letterSpacing: 1)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              delay: 0.4,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBar(String label, int current, int max, Color color, IconData icon) {
    final safeMax = max > 0 ? max : 1;
    final safeCurrent = current < 0 ? 0 : (current > safeMax ? safeMax : current);
    
    // Высчитываем процент (от 0.0 до 1.0)
    double percent = safeCurrent / safeMax;
    
    // 🆕 Если опыт есть, но процент очень маленький, делаем его хотя бы 2% (чтобы было видно)
    if (safeCurrent > 0 && percent < 0.02) {
      percent = 0.02;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, letterSpacing: 1)),
              ],
            ),
            Text('$safeCurrent / $safeMax', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 14, // Сделал чуть толще
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white10),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Сама полоска
                  TweenAnimationBuilder<double>(
                    key: ValueKey('$label-$current-$max'),
                    tween: Tween(begin: 0.0, end: percent),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutQuart, // Чуть другая кривая для плавности
                    builder: (context, value, child) {
                      return Container(
                        width: constraints.maxWidth * value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.6), color],
                          ),
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 1)
                          ],
                        ),
                      );
                    },
                  ),
                  // 🆕 Блик (полупрозрачная белая полоска сверху для объема)
                  Positioned(
                    top: 2, left: 4, right: 4, height: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String emoji, String label, dynamic value, {bool isGold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isGold ? const Color(0xFFD4AF37).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGold ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text(
                '$value',
                style: TextStyle(
                  color: isGold ? const Color(0xFFD4AF37) : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}