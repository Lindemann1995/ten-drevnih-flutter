import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../services/api_client.dart';
import 'battle_game.dart';
import '../utils/asset_paths.dart';
import 'dart:math' as math; // Для анимации частиц

class CombatScreen extends StatefulWidget {
  final String enemySlug;
  final String enemyName;

  const CombatScreen({
    super.key,
    required this.enemySlug,
    required this.enemyName,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;
  int? _combatId;

  late BattleGame _game;

  Map<String, dynamic>? _player;
  Map<String, dynamic>? _enemy;
  List<dynamic> _log = [];
  String _status = 'active';
  bool _resultShown = false;

  int _healthPotions = 0;
  String _damageText = "";
  bool _isEnemyHit = false;
  int _rewardGold = 0;
  int _rewardExp = 0;
  List<dynamic> _droppedItems = [];

  bool _isCombatStarted = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndStart();
    _loadPotions();
  }

  Future<void> _loadProfileAndStart() async {
    if (_isCombatStarted) return;
    _isCombatStarted = true;

    final result = await ApiClient.getProfile();
    if (!mounted) return;

    if (result['success'] == true) {
      _player = result['data'];
    }

    _startCombat();
  }

  Future<void> _loadPotions() async {
    final result = await ApiClient.getPotions();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _healthPotions = 0;
        for (var p in result['data']['potions']) {
          if (p['slug'] == 'health_potion') _healthPotions = p['quantity'];
        }
      });
    }
  }

  Future<void> _startCombat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiClient.startCombat(widget.enemySlug);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      _combatId = data['combat_id'];

      if (data['existing'] == true) {
        await _loadState();
      } else {
        setState(() {
          _enemy = {
            'name': data['enemy_name'],
            'hp': data['enemy_hp'],
            'max_hp': data['enemy_hp'],
            'level': 1,
            'image': data['enemy_image'],
            'bg': data['enemy_bg'],
          };
          _player = {
            ...?_player,
            'hp': data['player_hp'],
            'max_hp': data['player_max_hp'],
            'username': _player?['username'] ?? 'Ты',
          };
          _log = data['log'] ?? [];
          _isLoading = false;
        });

        String className = _player?['character_class']?['name'] ?? 'Воин';

        _game = BattleGame(
          playerClass: className,
          enemySlug: widget.enemySlug,
          enemyImagePath: data['enemy_image'] ?? '',
          bgImagePath: data['enemy_bg'] ?? '',
          shouldFlip: data['enemy_flip'] ?? false,
          enemyScale: (data['enemy_scale'] as num?)?.toDouble() ?? 1.0,
        );
      }
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadState() async {
    if (_combatId == null) return;
    final result = await ApiClient.getCombatState(_combatId!);
    if (!mounted) return;
    if (result['success'] == true) {
      _applyState(result['data']);
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _applyState(Map<String, dynamic> data) {
    List<dynamic> newLog = data['log'] ?? [];

    for (var entry in newLog) {
      String msg = entry['message'] ?? '';
      if (msg.contains('Победа!')) {
        final expMatch = RegExp(r'\+(\d+)\s*XP').firstMatch(msg);
        final goldMatch = RegExp(r'\+(\d+)\s*золота').firstMatch(msg);

        if (expMatch != null) _rewardExp = int.parse(expMatch.group(1)!);
        if (goldMatch != null) _rewardGold = int.parse(goldMatch.group(1)!);
      }
    }

    setState(() {
      _player = {
        ...?_player,
        ...data['player'],
      };
      _enemy = data['enemy'];
      _log = newLog;
      _status = data['status'];
      _isLoading = false;
      _isActing = false;

      if (data['dropped_items'] != null) {
        _droppedItems = data['dropped_items'];
      }
    });

    if (_status != 'active' && !_resultShown) {
      _resultShown = true;
      _showResult();
    }
  }

  String _getLastDamage() {
    if (_log.isEmpty) return "";
    for (int i = _log.length - 1; i >= 0; i--) {
      final msg = _log[i]['message'] as String;
      if (msg.contains('Ты нанёс')) {
        final match = RegExp(r'\d+').firstMatch(msg);
        if (match != null) return '-${match.group(0)}';
      }
    }
    return "";
  }

  Future<void> _doAction(String action) async {
    if (_combatId == null || _isActing) return;
    setState(() => _isActing = true);

    if (action == 'attack') {
      if (_game != null) {
        _game.heroAttack();
        await Future.delayed(const Duration(milliseconds: 300));
        _game.enemyHit();
      }

      final result = await ApiClient.combatAction(_combatId!, action);
      if (!mounted) return;

      if (result['success'] == true) {
        _applyState(result['data']);

        setState(() {
          _isEnemyHit = true;
          _damageText = _getLastDamage();
        });

        await Future.delayed(const Duration(milliseconds: 400));

        setState(() {
          _isEnemyHit = false;
        });

        if (_status == 'won' && _game != null) {
          _game.enemyDie();
        }
      } else {
        setState(() => _isActing = false);
        _showMessage(result['error'] ?? 'Ошибка');
      }
    } else {
      final result = await ApiClient.combatAction(_combatId!, action);
      if (!mounted) return;
      if (result['success'] == true) {
        _applyState(result['data']);
      } else {
        setState(() => _isActing = false);
        _showMessage(result['error'] ?? 'Ошибка');
      }
    }
  }

  Future<void> _usePotion() async {
    if (_healthPotions <= 0) {
      _showMessage('Нет зелий здоровья');
      return;
    }
    final result = await ApiClient.usePotion('health_potion');
    if (!mounted) return;
    if (result['success'] == true) {
      _showMessage(result['data']['message'] ?? 'Зелье использовано');
      setState(() {
        _player = {..._player!, 'hp': result['data']['player_hp']};
        _healthPotions = result['data']['remaining'] ?? 0;
      });
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  void _showResult() {
    if (_status == 'lost') {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.9),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim1, anim2) => _buildDefeatOverlay(),
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, -0.1), end: Offset.zero)
                  .animate(CurvedAnimation(
                      parent: anim1, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      );
      return;
    }

    if (_status == 'fled') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A0A0A),
          shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF3A3A3A), width: 2),
              borderRadius: BorderRadius.circular(16)),
          title: const Text('🏃 ПОБЕГ',
              style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: const Text('Ты сбежал с поля боя.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A0A0A),
                    foregroundColor: const Color(0xFFD4AF37),
                    side: const BorderSide(
                        color: Color(0xFFD4AF37), width: 2)),
                child: const Text('ЗАКРЫТЬ'),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_status == 'won') {
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim1, anim2) {
          return _buildVictoryOverlay();
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
      );
    }
  }

  // 🆕 ВАУ-ОФОРМЛЕНИЕ ЭКРАНА ПОБЕДЫ
  Widget _buildVictoryOverlay() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0A0A), Color(0xFF0A0000)],
            ),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Фоновые искры (Анимация)
              Positioned.fill(
                child: _SparklesAnimation(),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Титул победы с градиентом
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFFACD), Color(0xFFD4AF37), Color(0xFFFFFACD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      '🏆 ПОБЕДА!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ты победил ${_enemy?['name'] ?? 'врага'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Блок наград (Опыт и Золото)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRewardChip(Icons.star, '+$_rewardExp XP', Colors.greenAccent),
                      _buildRewardChip(Icons.monetization_on, '+$_rewardGold Gold', const Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'ДОБЫЧА:',
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Сетка лута
                  Container(
                    height: 130,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    ),
                    child: _droppedItems.isEmpty
                        ? const Center(
                            child: Text('Добычи нет',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontStyle: FontStyle.italic)),
                          )
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _droppedItems.length,
                            itemBuilder: (context, index) {
                              final item = _droppedItems[index];
                              Color rarityColor = Colors.grey;
                              if (item['rarity'] == 'uncommon') rarityColor = const Color(0xFF4A8B4A);
                              if (item['rarity'] == 'rare') rarityColor = const Color(0xFF3A5A8B);
                              if (item['rarity'] == 'epic') rarityColor = const Color(0xFF8B3A8B);
                              if (item['rarity'] == 'legendary') rarityColor = const Color(0xFFD4AF37);

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 400 + (index * 150)),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Opacity(
                                      opacity: value.clamp(0.0, 1.0),
                                      child: child,
                                    ),
                                  );
                                },
                                child: GestureDetector(
                                  onLongPress: () => _showItemDetails(item),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [const Color(0xFF2A1A1A), rarityColor.withOpacity(0.2)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: rarityColor.withOpacity(0.8), width: 1.5),
                                      boxShadow: [
                                        BoxShadow(color: rarityColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.asset(
                                              AssetPaths.forItem(item['image_path'], item['slug']),
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(Icons.inventory_2, color: rarityColor, size: 30);
                                              },
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 4,
                                          bottom: 2,
                                          child: Text(
                                            'x${item['quantity']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Кнопка забрать
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF1A0A0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 10,
                        shadowColor: const Color(0xFFD4AF37).withOpacity(0.8),
                      ),
                      child: const Text(
                        'ЗАБРАТЬ НАГРАДУ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final rarity = item['rarity'] ?? 'common';
    Color rarityColor = Colors.grey;
    if (rarity == 'uncommon') rarityColor = const Color(0xFF4A8B4A);
    if (rarity == 'rare') rarityColor = const Color(0xFF3A5A8B);
    if (rarity == 'epic') rarityColor = const Color(0xFF8B3A8B);
    if (rarity == 'legendary') rarityColor = const Color(0xFFD4AF37);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: rarityColor, width: 2),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? 'Неизвестный предмет',
                style: TextStyle(color: rarityColor, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Редкость: ${rarity.toString().toUpperCase()}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Divider(color: Color(0xFF3A1A1A), height: 24),
              const Text('Характеристики:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if ((item['bonus_strength'] ?? 0) > 0)
                Text('+${item['bonus_strength']} Сила', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14)),
              if ((item['bonus_agility'] ?? 0) > 0)
                Text('+${item['bonus_agility']} Ловкость', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14)),
              if ((item['bonus_intelligence'] ?? 0) > 0)
                Text('+${item['bonus_intelligence']} Интеллект', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14)),
              if ((item['bonus_endurance'] ?? 0) > 0)
                Text('+${item['bonus_endurance']} Выносливость', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14)),
              if ((item['bonus_health'] ?? 0) > 0)
                Text('+${item['bonus_health']} HP', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14)),
              if ((item['bonus_strength'] ?? 0) == 0 &&
                  (item['bonus_agility'] ?? 0) == 0 &&
                  (item['bonus_health'] ?? 0) == 0)
                const Text('Нет бонусов к характеристикам', style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A1A1A),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: rarityColor),
                  ),
                  child: const Text('ЗАКРЫТЬ'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefeatOverlay() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0000).withOpacity(0.95),
            border: Border.all(color: const Color(0xFF5A0A0A), width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.4), blurRadius: 30, spreadRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.heart_broken, color: Color(0xFF8B0000), size: 64),
              const SizedBox(height: 16),
              const Text('ПОРАЖЕНИЕ', style: TextStyle(color: Color(0xFF8B0000), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
              const SizedBox(height: 16),
              Text('Ты пал в бою с ${_enemy?['name'] ?? 'врагом'}...', style: const TextStyle(color: Colors.white54, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A0A0A),
                    foregroundColor: const Color(0xFF8B0000),
                    side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ПРИНЯТЬ СУДЬБУ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B0000)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _error != null
                  ? _buildError()
                  : _buildCombat(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Color(0xFF8B0000), size: 60),
            const SizedBox(height: 20),
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A0A0A), foregroundColor: const Color(0xFFD4AF37)),
              child: const Text('НАЗАД'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombat() {
    final playerHp = _player?['hp'] ?? 0;
    final playerMaxHp = _player?['max_hp'] ?? 100;
    final enemyHp = _enemy?['hp'] ?? 0;
    final enemyMaxHp = _enemy?['max_hp'] ?? 100;

    String bgPath = AssetPaths.forFlutter('ui/battle_bg.png');
    if (_enemy?['bg'] != null && _enemy!['bg'].toString().isNotEmpty) {
      bgPath = AssetPaths.forFlutter(_enemy!['bg']);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Text(
                '⚔️ ${_enemy?['name'] ?? 'Враг'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              _buildHpBar(enemyHp, enemyMaxHp, const Color(0xFF8B0000)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
              image: DecorationImage(
                image: AssetImage(bgPath),
                fit: BoxFit.cover,
                onError: (error, stack) => debugPrint('⚠️ Battle bg not found: $bgPath'),
              ),
              color: const Color(0xFF1A0A0A),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Positioned.fill(child: Container(color: Colors.black.withOpacity(0.2))),
                  GameWidget(game: _game),
                  if (_isEnemyHit && _damageText.isNotEmpty)
                    Positioned(
                      right: 60,
                      top: 60,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, -40 * value),
                            child: Opacity(
                              opacity: 1.0 - value,
                              child: Text(
                                _damageText,
                                style: const TextStyle(
                                  color: Color(0xFFFF4D4D),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(2, 2))],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFF3A1A1A), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            reverse: true,
            itemCount: _log.length,
            itemBuilder: (context, index) {
              final entry = _log[_log.length - 1 - index];
              final actor = entry['actor'] ?? '';
              Color color = Colors.white54;
              if (actor == 'player') color = const Color(0xFFD4AF37);
              if (actor == 'enemy') color = const Color(0xFFFF6B6B);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(entry['message'] ?? '', style: TextStyle(color: color, fontSize: 13)),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHpBar(playerHp, playerMaxHp, const Color(0xFF2A8B2A), label: '${_player?['username'] ?? 'Ты'}: $playerHp/$playerMaxHp'),
              const SizedBox(height: 16),
              if (_status == 'active')
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(text: '⚔ АТАКА', color: const Color(0xFF8B0000), onPressed: _isActing ? null : () => _doAction('attack')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(text: '🛡 ЗАЩИТА', color: const Color(0xFF3A5A8B), onPressed: _isActing ? null : () => _doAction('defend')),
                    ),
                  ],
                ),
              if (_status == 'active') const SizedBox(height: 8),
              if (_status == 'active')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isActing || _healthPotions <= 0 ? null : _usePotion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A0A),
                      foregroundColor: const Color(0xFF6BBF6B),
                      side: const BorderSide(color: Color(0xFF2A8B2A), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('🧪 ЗЕЛЬЕ HP ($_healthPotions)', style: const TextStyle(fontSize: 16, letterSpacing: 1)),
                  ),
                ),
              if (_status == 'active') const SizedBox(height: 8),
              if (_status == 'active')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isActing ? null : () => _doAction('flee'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A0A),
                      foregroundColor: const Color(0xFF8B8B8B),
                      side: const BorderSide(color: Color(0xFF3A3A3A), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('🏃 ПОБЕГ', style: TextStyle(fontSize: 16, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHpBar(int hp, int maxHp, Color color, {String? label}) {
    final percent = maxHp > 0 ? hp / maxHp : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        Stack(
          children: [
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                height: 24,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text('$hp / $maxHp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({required this.text, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A0A0A),
          foregroundColor: Colors.white,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, letterSpacing: 1, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// 🆕 Анимация летающих золотых искр на фоне окна победы
class _SparklesAnimation extends StatefulWidget {
  @override
  _SparklesAnimationState createState() => _SparklesAnimationState();
}

class _SparklesAnimationState extends State<_SparklesAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SparklePainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  _SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD4AF37).withOpacity(0.6);
    final rnd = math.Random(42); // Фиксированный сид для одинаковых искр

    for (int i = 0; i < 15; i++) {
      double x = rnd.nextDouble() * size.width;
      double baseY = rnd.nextDouble() * size.height;
      // Движение вверх
      double y = baseY - (progress * size.height * 1.5) % size.height;
      
      // Мерцание
      double opacity = math.sin((progress * 10) + i) * 0.5 + 0.5;
      paint.color = const Color(0xFFD4AF37).withOpacity(opacity);
      
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 2 + 1, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) => oldDelegate.progress != progress;
}