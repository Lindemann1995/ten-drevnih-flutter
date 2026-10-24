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
import 'castles_list_screen.dart';
import 'duel_list_screen.dart';
import 'map_screen.dart';
import 'guild_daily_quests_screen.dart';
import 'dart:math' as math;
import 'guild_admin_panel_screen.dart';

class GuildScreen extends StatefulWidget {
  const GuildScreen({super.key});

  @override
  State<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends State<GuildScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _guildData;
  bool _isLoading = true;
  String? _error;

  late AnimationController _bgController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _loadGuild();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadGuild() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiClient.getMyGuild();

    if (result['success']) {
      setState(() {
        _guildData = result['data'];
        _isLoading = false;
      });
      
      _bgController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _entranceController.forward(from: 0);
      
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
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 1. Анимированный фон
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_bgController.value * math.pi * 2) * 0.7,
                      math.cos(_bgController.value * math.pi * 2) * 0.7,
                    ),
                    radius: 1.8,
                    colors: const [
                      Color(0xFF2A0A0A),
                      Color(0xFF050505),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Летающие искры (Particle Effect)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: SparklePainter(animation: _bgController),
              ),
            ),
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
                            'ГИЛЬДИЯ',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    if (_guildData == null || _guildData!['in_guild'] == false) return _buildNoGuild();

    final g = _guildData!;
    final canManageApplications = g['permissions'] != null && g['permissions']['accept_members'] == true;
    final hasCastle = g['castles_count'] != null && g['castles_count'] > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Главная карточка
          _animatedEntrance(
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // 🆕 Пульсирующий щит
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1.0 + (_pulseController.value * 0.05);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.3 + (_pulseController.value * 0.2)),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF1A0A0A),
                            child: const Icon(Icons.shield, size: 50, color: Color(0xFFD4AF37)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    '[${g['tag']}] ${g['name']}',
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      border: Border.all(color: _parseColor(g['rank_color'])),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _parseColor(g['rank_color']).withOpacity(0.2), blurRadius: 10)],
                    ),
                    child: Text(
                      g['rank_display'],
                      style: TextStyle(color: _parseColor(g['rank_color']), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn('Участники', '${g['members_count']}/30', Icons.people),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _buildStatColumn('Казна', '${g['treasury_gold']}', Icons.monetization_on),
                    ],
                  ),
                ],
              ),
            ),
            delay: 0.0,
          ),
          
          if (hasCastle) ...[
            const SizedBox(height: 16),
            _animatedEntrance(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.castle, color: Color(0xFFD4AF37), size: 24),
                    const SizedBox(width: 8),
                    const Text('Владеет замком: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('+${g['castle_buff_xp'] ?? 10}% XP, ', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('+${g['castle_buff_gold'] ?? 10}% Gold', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              delay: 0.1,
            ),
          ],

          const SizedBox(height: 30),

          _animatedEntrance(
            const Text('УПРАВЛЕНИЕ', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
            delay: 0.2,
          ),
          const SizedBox(height: 12),
          
          _animatedEntrance(
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
              children: [
                _buildActionIcon(Icons.group, 'Состав', Colors.blueAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildMembersScreen()));
                }),
                
                _buildActionIcon(Icons.assignment, 'Квесты', Colors.amber, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildDailyQuestsScreen()));
                }),
                _buildActionIcon(Icons.sports_kabaddi, 'Дуэли', Colors.redAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DuelListScreen()));
                }),
                                // 🆕 Панель командования (видна только Лидеру и Замам)
                if (g['permissions'] != null && (g['permissions']['manage_guild'] == true || g['permissions']['accept_members'] == true))
                  _buildActionIcon(Icons.admin_panel_settings, 'Штаб', Colors.cyan, () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => GuildAdminPanelScreen(guildData: g))
                    );
                  }),
                _buildActionIcon(Icons.account_balance, 'Налоги', Colors.greenAccent, () => _collectTaxes()),
                
                _buildActionIcon(Icons.monetization_on, 'Казна', Colors.amberAccent, () async {
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
                
                _buildActionIcon(Icons.chat, 'Чат', Colors.lightBlueAccent, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GuildChatScreen(
                      guildId: g['guild_id'],
                      myUsername: g['username'] ?? 'user',
                    )
                  ));
                }),
                
                _buildActionIcon(Icons.inventory, 'Хранилище', Colors.orangeAccent, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GuildBankScreen(canWithdraw: g['permissions'] != null && g['permissions']['manage_treasury'] == true)
                  ));
                }),
                
                _buildActionIcon(Icons.handyman, 'Кузня', Colors.purpleAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildUpgradesScreen()));
                }),
                
                if (canManageApplications)
                  _buildActionIcon(Icons.pending_actions, 'Заявки', Colors.cyanAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildApplicationsScreen()));
                  })
                else
                  _buildActionIcon(Icons.settings, 'Настройки', Colors.grey, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('В разработке')));
                  }),
                  
                _buildActionIcon(Icons.castle, 'Замки', Colors.deepOrangeAccent, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                }),
              ],
            ),
            delay: 0.3,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNoGuild() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 30, spreadRadius: 10)],
            ),
            child: const Icon(Icons.shield_outlined, size: 80, color: Colors.white24),
          ),
          const SizedBox(height: 20),
          const Text('Ты не состоишь в гильдии', style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 5,
              shadowColor: const Color(0xFFD4AF37).withOpacity(0.5),
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

  // 🆕 Кнопки с эффектом нажатия (вдавливание)
  Widget _buildActionIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: onTap,
          child: AnimatedScale(
            scale: isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A0A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      if (!isPressed) BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, spreadRadius: 1),
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white54, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  void _collectTaxes() async {
    final result = await ApiClient.collectTaxes();
    if (mounted) {
      if (result['success']) {
        final data = result['data'];
        final income = data['total_income'] ?? 0;
        final tax = data['total_tax'] ?? 0;
        final treasury = data['treasury_gold'] ?? 0;
        final msgs = (data['messages'] as List?)?.join('\n') ?? '';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A0A0A),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Column(
              children: [
                Icon(Icons.account_balance, color: Color(0xFFD4AF37), size: 40),
                SizedBox(height: 8),
                Text('СБОР НАЛОГОВ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2), textAlign: TextAlign.center),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFinanceRow('Доход с замков', '+$income', Colors.greenAccent),
                const SizedBox(height: 8),
                _buildFinanceRow('Налог на содержание', '-$tax', Colors.redAccent),
                const Divider(color: Color(0xFF3A3A3A), height: 24),
                _buildFinanceRow('Золото в казне', '$treasury', Colors.amber),
                if (msgs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3A3A3A))),
                    child: Text(msgs, style: const TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
                  ),
                ]
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _loadGuild(); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('ПРИНЯТЬ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildFinanceRow(String title, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _animatedEntrance(Widget child, {double delay = 0.0}) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        final progress = _entranceController.value;
        final adjustedProgress = (progress - delay).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(adjustedProgress);
        
        return Transform.translate(
          offset: Offset(0, 30 * (1 - curve)),
          child: Opacity(
            opacity: curve,
            child: child,
          ),
        );
      },
    );
  }
}

// 🆕 КАСТОМНЫЙ ПЕЙНТЕР ДЛЯ ЛЕТАЮЩИХ ИСКР
class SparklePainter extends CustomPainter {
  final Animation<double> animation;

  SparklePainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); 

    for (int i = 0; i < 25; i++) {
      // Позиция зависит от времени и случайного числа (чтобы искры летали по-разному)
      final progress = (animation.value + (i * 0.1)) % 1.0;
      
      final x = random.nextDouble() * size.width;
      // Искра поднимается снизу вверх
      final y = size.height - (progress * size.height * 1.2); 
      
      // Искры мерцают (меняют размер)
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0) * 0.6;
      final radius = random.nextDouble() * 2.0 + 1.0;

      paint.color = const Color(0xFFD4AF37).withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) => true;
}