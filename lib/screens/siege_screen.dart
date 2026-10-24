import 'package:flutter/material.dart';
import '../services/api_client.dart';

class SiegeScreen extends StatefulWidget {
  final int siegeId;
  final String castleName;

  const SiegeScreen({super.key, required this.siegeId, required this.castleName});

  @override
  State<SiegeScreen> createState() => _SiegeScreenState();
}

class _SiegeScreenState extends State<SiegeScreen> {
  int _playerHp = 100;
  int _playerMaxHp = 100;
  int _enemiesLeft = 0;
  Map<String, dynamic>? _currentEnemy;
  List<dynamic> _log = [];
  bool _isLoading = true;
  bool _isFinished = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    // Загружаем состояние через первый запрос (например, просто ждем)
    setState(() => _isLoading = true);
    // В реальности здесь был бы GET-запрос состояния, но пока сделаем заглушку
    setState(() => _isLoading = false);
  }

  Future<void> _action(String action) async {
    final result = await ApiClient.siegeAction(widget.siegeId, action);
    if (mounted) {
      if (result['success']) {
        final data = result['data'];
        setState(() {
          if (data['status'] == 'won') {
            _isFinished = true;
            _resultMessage = '🏆 ПОБЕДА! Замок «${widget.castleName}» захвачен!';
          } else if (data['status'] == 'lost') {
            _isFinished = true;
            _resultMessage = '💀 ПОРАЖЕНИЕ... ${data['message'] ?? ''}';
          } else {
            _playerHp = data['player_hp'] ?? _playerHp;
            _enemiesLeft = data['enemies_left'] ?? _enemiesLeft;
            _currentEnemy = data['current_enemy'];
            _log = data['log'] ?? [];
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ОСАДА: ${widget.castleName}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : _isFinished
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _resultMessage ?? 'Осада завершена',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HP игрока
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ТЫ', style: TextStyle(color: Colors.white, fontSize: 16)),
                            Text('$_playerHp HP', style: const TextStyle(color: Colors.green, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _playerMaxHp > 0 ? _playerHp / _playerMaxHp : 0,
                          backgroundColor: Colors.grey[800],
                          color: Colors.green,
                          minHeight: 10,
                        ),
                        const SizedBox(height: 20),

                        // Текущий враг
                        if (_currentEnemy != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0A0A),
                              border: Border.all(color: const Color(0xFF8B0000)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ВРАГ: ${_currentEnemy!['name']}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _currentEnemy!['max_hp'] > 0 ? _currentEnemy!['hp'] / _currentEnemy!['max_hp'] : 0,
                                        backgroundColor: Colors.grey[800],
                                        color: Colors.redAccent,
                                        minHeight: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${_currentEnemy!['hp']}/${_currentEnemy!['max_hp']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const Text('Все защитники повержены!', style: TextStyle(color: Colors.green, fontSize: 16)),
                        ],
                        const SizedBox(height: 10),
                        Text('Осталось врагов: $_enemiesLeft', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        
                        const SizedBox(height: 20),
                        
                        // Лог боя
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0A0A),
                              border: Border.all(color: const Color(0xFF3A3A3A)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: _log.length,
                              itemBuilder: (context, index) {
                                final entry = _log[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    entry['message'] ?? '',
                                    style: TextStyle(
                                      color: entry['actor'] == 'player' ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Кнопки действий
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B0000),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => _action('attack'),
                                child: const Text('АТАКОВАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A5A2A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () => _action('defend'),
                                child: const Text('ЗАЩИТА', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white54,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => _action('flee'),
                            child: const Text('СБЕЖАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}