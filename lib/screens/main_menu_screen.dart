import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_client.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'hunt_screen.dart';
import 'stats_screen.dart';
import 'craft_screen.dart';
import 'trade_world_screen.dart';
import 'world_map_screen.dart';
import '../main.dart';
import 'quest_list_screen.dart';
import 'guild_screen.dart';
import 'friends_screen.dart';
import 'notifications_screen.dart';
import 'dart:async';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with RouteAware, TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _profile;
  int _profileKey = 0;
  int _unreadCount = 0;
  Timer? _notificationTimer;
  
  late AnimationController _navController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadUnreadCount(); 
    _checkOfflineReward();

    // Автообновление каждые 30 секунд
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadUnreadCount();
    });
    
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
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
    _notificationTimer?.cancel(); 
    routeObserver.unsubscribe(this);
    _navController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadProfile(); 
    _loadUnreadCount();
  }

  Future<void> _loadProfile() async {
    final result = await ApiClient.getProfile();
    if (result['success'] == true && mounted) {
      setState(() {
        _profile = result['data'];
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await ApiClient.getUnreadNotificationsCount();
      print('=== ПОЛУЧЕНО УВЕДОМЛЕНИЙ: $count ==='); // Отладка
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('=== ОШИБКА ПОЛУЧЕНИЯ УВЕДОМЛЕНИЙ: $e ==='); // Отладка
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
            Text('Ты отсутствовал ${data['hours']} ч.', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 60),
            const SizedBox(height: 10),
            Text('+${data['gold_earned']} золота', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); _loadProfile(); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: const Color(0xFF0A0A0A)),
              child: const Text('ЗАБРАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      if (index == 3) _profileKey++; 
    });
    _navController.forward(from: 0);
  }

  void _showReportDialog(BuildContext context) {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController commentController = TextEditingController();
    String selectedReason = 'toxic';

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A0A0A), Color(0xFF0A0000)],
                  ),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.8), width: 2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ЖАЛОБА НА ИГРОКА',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.white54, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFD4AF37), height: 1),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ник нарушителя',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      dropdownColor: const Color(0xFF1A0A0A),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Причина жалобы',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.gavel, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'toxic', child: Text('Оскорбления / Токсичность')),
                        DropdownMenuItem(value: 'spam', child: Text('Спам / Реклама')),
                        DropdownMenuItem(value: 'cheat', child: Text('Читерство / Взлом')),
                        DropdownMenuItem(value: 'other', child: Text('Другое')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedReason = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Комментарий (опционально)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.comment, color: Color(0xFFD4AF37)),
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white30),
                              ),
                            ),
                            child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B0000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFFF4D4D), width: 1),
                              ),
                              elevation: 5,
                              shadowColor: const Color(0xFF8B0000).withOpacity(0.8),
                            ),
                            onPressed: () async {
                              final username = usernameController.text.trim();
                              if (username.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Введите ник игрока'), backgroundColor: Colors.orange),
                                );
                                return;
                              }
                              
                              Navigator.of(context).pop(); 
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                      SizedBox(width: 16),
                                      Text('Отправка жалобы...'),
                                    ],
                                  ),
                                  backgroundColor: Color(0xFF1A0A0A),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              Map<String, dynamic> result;
                              try {
                                result = await ApiClient.reportPlayer(
                                  targetUsername: username,
                                  reason: selectedReason,
                                  comment: commentController.text.trim(),
                                );
                              } catch (e) {
                                result = {
                                  'success': false,
                                  'error': 'Сервер вернул ошибку. Проверь логи сервера.\nДетали: $e'
                                };
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).clearSnackBars(); 
                                
                                if (result['success'] == true) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A0A0A),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: Color(0xFF2A8B2A), width: 2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Color(0xFF2A8B2A), size: 60),
                                          const SizedBox(height: 16),
                                          const Text('Жалоба отправлена!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          const Text('Модераторы проверят её в ближайшее время.', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF2A8B2A),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('ПОНЯТНО', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A0A0A),
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.error_outline, color: Color(0xFF8B0000), size: 60),
                                          const SizedBox(height: 16),
                                          const Text('Ошибка отправки', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 8),
                                          Text(result['error'] ?? 'Неизвестная ошибка', style: const TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF8B0000),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('ЗАКРЫТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('ОТПРАВИТЬ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              key: ValueKey('home_$_unreadCount'), // Принудительная перерисовка
              profile: _profile, 
              onRefresh: _loadProfile,
              onNavigate: _onTabTapped,
              onReport: () => _showReportDialog(context),
              unreadCount: _unreadCount,
              onUpdateUnreadCount: _loadUnreadCount,
            ),
            const WorldMapScreen(), 
            const ChatScreen(), 
            ProfileScreen(key: ValueKey(_profileKey)), 
          ],
        ),
        
        bottomNavigationBar: _buildLuxuryNavBar(),
      ),
    );
  }

  Widget _buildLuxuryNavBar() {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A).withOpacity(0.85),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, 10)),
              BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, 'assets/images/ui/icon_home.png', 'ДОМОЙ', Icons.home),
                _buildNavItem(1, 'assets/images/ui/icon_map.png', 'МИР', Icons.map),
                _buildNavItem(2, 'assets/images/ui/icon_chat.png', 'ЧАТ', Icons.chat_bubble),
                _buildNavItem(3, 'assets/images/ui/icon_news.png', 'ПРОФИЛЬ', Icons.person),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label, IconData fallbackIcon) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                ] : [],
              ),
              child: Image.asset(
                iconPath,
                width: 26, height: 26,
                opacity: AlwaysStoppedAnimation(isSelected ? 1.0 : 0.5),
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
                letterSpacing: isSelected ? 1.0 : 0.0,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final VoidCallback onRefresh; 
  final Function(int) onNavigate;
  final VoidCallback onReport;
  final int unreadCount;
  final VoidCallback onUpdateUnreadCount;

  const _HomeTab({
    super.key,
    this.profile, 
    required this.onRefresh,
    required this.onNavigate,
    required this.onReport,
    required this.unreadCount,
    required this.onUpdateUnreadCount,
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF1A0A0A),
                            child: const Icon(Icons.person, color: Color(0xFFD4AF37), size: 32),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37), 
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'УР. $level',
                                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    className,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications, color: Color(0xFFD4AF37)),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              tooltip: 'Уведомления',
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                                onUpdateUnreadCount();
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.report_problem, color: Color(0xFFD4AF37)),
                              tooltip: 'Пожаловаться',
                              onPressed: onReport,
                            ),
                            const SizedBox(width: 8),
                            _buildTopIcon(Icons.people_alt, 'Друзья', () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                            }),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildExpBar(
                      profile?['experience'] ?? 0, 
                      profile?['experience_to_next'] ?? 100
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
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
                childAspectRatio: 1.7, 
                children: [
                  _buildGridButton(Icons.assignment, 'ЗАДАНИЯ', Colors.amber, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestListScreen()));
                  }),
                  _buildGridButton(Icons.person, 'ПРОФИЛЬ', Colors.blueAccent, () {
                    onNavigate(3); 
                  }),
                  _buildGridButton(Icons.shield, 'ГИЛЬДИИ', Colors.orangeAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildScreen()));
                  }),
                  _buildGridButton(Icons.castle, 'ПОДЗЕМЕЛЬЯ', Colors.purpleAccent, () => _showComingSoon(context, 'Подземелья')),
                  _buildGridButton(Icons.backpack, 'СНАРЯЖЕНИЕ', Colors.greenAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                  }),
                  _buildGridButton(Icons.bar_chart, 'СТАТЫ', Colors.redAccent, () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => StatsScreen(
                          initialProfile: profile,
                          onRefresh: onRefresh,
                        )
                      )
                    );
                  }),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'БЫСТРЫЕ ДЕЙСТВИЯ',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
                children: [
                  _buildQuickAction(Icons.pets, 'ОХОТА', Colors.orangeAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HuntScreen()));
                  }),
                  _buildQuickAction(Icons.explore, 'ЛОКАЦИИ', Colors.lightBlueAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorldMapScreen()));
                  }),
                  _buildQuickAction(Icons.storefront, 'ТОРГОВЛЯ', Colors.greenAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TradeWorldScreen()));
                  }),
                  _buildQuickAction(Icons.handyman, 'КУЗНИЦА', Colors.amberAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CraftScreen(npcSlug: 'koval', npcName: 'Коваль'),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ОПЫТ', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
            Text('$currentExp / $maxExp', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A), 
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
          ),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percent),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFFACD)]),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 8)
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 2, left: 4, right: 4, height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'До ур. осталось: $remaining',
          style: const TextStyle(color: Colors.white54, fontSize: 9, fontStyle: FontStyle.italic),
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
            Text('$featureName скоро появятся!', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text('Мы уже работаем над этим. Следи за обновлениями в новостях!', style: TextStyle(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: const Color(0xFF0A0A0A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('ПОНЯТНО', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60, 
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A0A).withOpacity(0.8),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5), 
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)
              ],
            ),
            child: Center(child: Icon(icon, color: color, size: 30)),
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
        ],
      ),
    );
  }

  Widget _buildGridButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), const Color(0xFF1A0A0A)],
          ),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ],
        ),
      ),
    );
  }
}