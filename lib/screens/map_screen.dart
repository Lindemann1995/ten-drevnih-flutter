import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_client.dart';
import 'siege_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  List<dynamic> _castles = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadCastles();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCastles() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getCastles();
    if (result['success']) {
      setState(() {
        _castles = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _onCastleTap(dynamic castle) {
    final isFree = castle['owner'] == null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
            ),
            border: Border.all(
              color: isFree ? Colors.white54 : const Color(0xFFD4AF37), 
              width: 2
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (!isFree) BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      castle['name'],
                      style: TextStyle(
                        color: isFree ? Colors.white : const Color(0xFFD4AF37),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Icon(
                      isFree ? Icons.lock_open : Icons.lock,
                      color: isFree ? Colors.white54 : const Color(0xFFD4AF37),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isFree ? 'Свободный замок' : 'Владелец: [${castle['owner']}]',
                  style: TextStyle(
                    color: isFree ? Colors.white54 : const Color(0xFFD4AF37),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const Divider(color: Color(0xFF3A1A1A), height: 30),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(Icons.star, '+${castle['buff_xp_percent']}% XP', Colors.greenAccent),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _buildStatChip(Icons.monetization_on, '+${castle['buff_gold_percent']}% Gold', Colors.amber),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (isFree)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        shadowColor: const Color(0xFF8B0000).withValues(alpha: 0.5),
                      ),
                      onPressed: () async {
                        final siegeResult = await ApiClient.startSiege(castle['id']);
                        if (!context.mounted) return;

                        if (siegeResult['success']) {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => SiegeScreen(
                              siegeId: siegeResult['data']['siege_id'],
                              castleName: castle['name'],
                            ),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(siegeResult['error']), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 24),
                          SizedBox(width: 10),
                          Text('АТАКОВАТЬ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'Объявить войну можно будет позже...',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'КАРТА ЗАМКОВ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 3),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                      onPressed: _loadCastles,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/world_map.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                              color: const Color(0xFF1A0A0A),
                              child: const Center(child: Text('Карта не найдена', style: TextStyle(color: Colors.white54))),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(color: Colors.black.withValues(alpha: 0.4)),
                        ),
                        
                        ..._castles.map((castle) {
                          final isFree = castle['owner'] == null;
                          
                          return Positioned(
                            left: constraints.maxWidth * (castle['map_x'] ?? 0.5) - 35,
                            top: constraints.maxHeight * (castle['map_y'] ?? 0.5) - 35,
                            child: GestureDetector(
                              onTap: () => _onCastleTap(castle),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF1A0A0A).withValues(alpha: 0.9),
                                          border: Border.all(
                                            color: isFree 
                                                ? Colors.white54.withValues(alpha: 0.5 + _pulseController.value * 0.5)
                                                : const Color(0xFFD4AF37),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            if (!isFree)
                                              BoxShadow(
                                                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                                                blurRadius: 15,
                                                spreadRadius: 2 + _pulseController.value * 3,
                                              )
                                            else
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.1 * _pulseController.value),
                                                blurRadius: 10,
                                              ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.castle,
                                          color: isFree ? Colors.white54 : const Color(0xFFD4AF37),
                                          size: 36,
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  if (castle['owner'] != null) ...[
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A0A0A),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFD4AF37)),
                                      ),
                                      child: Text(
                                        castle['owner'],
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ] else if (castle['siege_cooldown_until'] != null) ...[
                                    CastleCooldownTimer(cooldownUntil: castle['siege_cooldown_until']),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A).withValues(alpha: 0.8),
                  border: const Border(top: BorderSide(color: Color(0xFF3A1A1A))),
                ),
                child: const Center(
                  child: Text(
                    'Нажми на замок, чтобы атаковать или посмотреть информацию', 
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ВИДЖЕТ ТАЙМЕРА КД (ДОБАВЛЕН В КОНЕЦ ФАЙЛА)
// ==========================================
class CastleCooldownTimer extends StatefulWidget {
  final String cooldownUntil;

  const CastleCooldownTimer({super.key, required this.cooldownUntil});

  @override
  State<CastleCooldownTimer> createState() => _CastleCooldownTimerState();
}

class _CastleCooldownTimerState extends State<CastleCooldownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final cooldownUntil = DateTime.tryParse(widget.cooldownUntil)?.toLocal();
    if (cooldownUntil == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    if (cooldownUntil.isAfter(now)) {
      setState(() => _remaining = cooldownUntil.difference(now));
    } else {
      setState(() => _remaining = Duration.zero);
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) return const SizedBox.shrink();

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '🛡 ${hours}ч ${minutes}м ${seconds}с',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}