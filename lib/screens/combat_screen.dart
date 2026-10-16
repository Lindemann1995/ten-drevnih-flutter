import 'package:flutter/material.dart';
import '../services/api_client.dart';

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

class _CombatScreenState extends State<CombatScreen> {
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;
  int? _combatId;

  Map<String, dynamic>? _player;
  Map<String, dynamic>? _enemy;
  List<dynamic> _log = [];
  String _status = 'active';
  bool _resultShown = false;

  @override
  void initState() {
    super.initState();
    _startCombat();
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
        // Уже есть активный бой — загружаем состояние
        await _loadState();
      } else {
        setState(() {
          _enemy = {
            'name': data['enemy_name'],
            'hp': data['enemy_hp'],
            'max_hp': data['enemy_hp'],
            'level': 1,
          };
          _player = {
            'hp': data['player_hp'],
            'max_hp': data['player_max_hp'],
            'username': 'Ты',
          };
          _log = data['log'] ?? [];
          _isLoading = false;
        });
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
    setState(() {
      _player = data['player'];
      _enemy = data['enemy'];
      _log = data['log'] ?? [];
      _status = data['status'];
      _isLoading = false;
      _isActing = false;
    });

    if (_status != 'active' && !_resultShown) {
      _resultShown = true;
      _showResult();
    }
  }

  Future<void> _doAction(String action) async {
    if (_combatId == null || _isActing) return;

    setState(() => _isActing = true);

    final result = await ApiClient.combatAction(_combatId!, action);

    if (!mounted) return;

    if (result['success'] == true) {
      _applyState(result['data']);
    } else {
      setState(() => _isActing = false);
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  void _showResult() {
    String title;
    String message;
    Color color;

    if (_status == 'won') {
      title = '🏆 ПОБЕДА!';
      message = 'Ты победил ${_enemy?['name']}';
      color = const Color(0xFF2A5A2A);
    } else if (_status == 'lost') {
      title = '💀 ПОРАЖЕНИЕ';
      message = 'Ты пал в бою...';
      color = const Color(0xFF5A0A0A);
    } else {
      title = '🏃 ПОБЕГ';
      message = 'Ты сбежал с поля боя.';
      color = const Color(0xFF3A3A3A);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: color,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
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
                side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
              child: const Text('ЗАКРЫТЬ'),
            ),
          ),
        ],
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
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A), Color(0xFF2A0A0A)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                )
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
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A0A),
                foregroundColor: const Color(0xFFD4AF37),
              ),
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

    return Column(
      children: [
        // ЗАГОЛОВОК С ВРАГОМ
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '⚔️ ${_enemy?['name'] ?? 'Враг'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _buildHpBar(enemyHp, enemyMaxHp, const Color(0xFF8B0000)),
            ],
          ),
        ),

        // ЛОГ БОЯ
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A0A),
              border: Border.all(color: const Color(0xFF3A1A1A), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: _log.length,
              itemBuilder: (context, index) {
                final reversedIndex = _log.length - 1 - index;
                final entry = _log[reversedIndex];
                final actor = entry['actor'] ?? '';
                
                Color color;
                if (actor == 'player') {
                  color = const Color(0xFFD4AF37);
                } else if (actor == 'enemy') {
                  color = const Color(0xFFFF6B6B);
                } else {
                  color = Colors.white54;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    entry['message'] ?? '',
                    style: TextStyle(color: color, fontSize: 14, height: 1.4),
                  ),
                );
              },
            ),
          ),
        ),

        // HP ИГРОКА
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHpBar(playerHp, playerMaxHp, const Color(0xFF2A8B2A), 
                  label: '${_player?['username'] ?? 'Ты'}: $playerHp/$playerMaxHp'),
              const SizedBox(height: 16),

              // КНОПКИ ДЕЙСТВИЙ
              if (_status == 'active')
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        text: '⚔ АТАКА',
                        color: const Color(0xFF8B0000),
                        onPressed: _isActing ? null : () => _doAction('attack'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        text: '🛡 ЗАЩИТА',
                        color: const Color(0xFF3A5A8B),
                        onPressed: _isActing ? null : () => _doAction('defend'),
                      ),
                    ),
                  ],
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '🏃 ПОБЕГ',
                      style: TextStyle(fontSize: 16, letterSpacing: 1),
                    ),
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
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
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
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '$hp / $maxHp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
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

  const _ActionButton({
    required this.text,
    required this.color,
    required this.onPressed,
  });

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}