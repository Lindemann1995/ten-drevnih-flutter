import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'dart:async';

class DuelScreen extends StatefulWidget {
  final int duelId;
  final String challenger;
  final String opponent;
  final String myUsername;
  final String currentTurn;

  const DuelScreen({
    super.key,
    required this.duelId,
    required this.challenger,
    required this.opponent,
    required this.myUsername,
    required this.currentTurn,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  int _challengerHp = 100;
  int _opponentHp = 100;
  int _challengerMaxHp = 100;
  int _opponentMaxHp = 100;
  
  bool _isFinished = false;
  String? _winner;
  List<dynamic> _log = [];
  bool _isLoading = false;
  
  late String _currentTurn;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTurn = widget.currentTurn;
    _loadState(); // Загружаем начальное состояние
    _startAutoRefresh(); // Запускаем автообновление
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isFinished && mounted) {
        _loadState();
      }
    });
  }

  Future<void> _loadState() async {
    final result = await ApiClient.getDuelStatus(widget.duelId);
    if (result['success'] && mounted) {
      final data = result['data'];
      setState(() {
        _challengerHp = data['challenger_hp'] ?? _challengerHp;
        _opponentHp = data['opponent_hp'] ?? _opponentHp;
        _currentTurn = data['current_turn'] ?? _currentTurn;
        _log = data['log'] ?? _log;

        if (data['status'] == 'finished') {
          _isFinished = true;
          _winner = data['winner'];
          _timer?.cancel();
        }
      });
    }
  }

  Future<void> _attack() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.duelAction(widget.duelId, 'attack');
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        final data = result['data'];
        setState(() {
          if (data['status'] == 'finished') {
            _isFinished = true;
            _winner = data['winner'];
            _timer?.cancel();
          } else {
            _challengerHp = data['challenger_hp'] ?? _challengerHp;
            _opponentHp = data['opponent_hp'] ?? _opponentHp;
            _currentTurn = data['current_turn'] ?? _currentTurn;
            _log = data['log'] ?? [];
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _surrender() async {
    final result = await ApiClient.declineDuel(widget.duelId);
    if (mounted && result['success']) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ДУЭЛЬ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: _isFinished ? _buildVictoryScreen() : _buildBattleScreen(),
      ),
    );
  }

  Widget _buildVictoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 120, color: Color(0xFFD4AF37)),
          const SizedBox(height: 20),
          const Text('ПОБЕДА', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
          const SizedBox(height: 10),
          Text(_winner ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ВЕРНУТЬСЯ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleScreen() {
    final isMyTurn = (widget.myUsername == widget.challenger && _currentTurn == 'challenger') ||
                     (widget.myUsername == widget.opponent && _currentTurn == 'opponent');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFighterCard(widget.challenger, _challengerHp, _challengerMaxHp, Colors.greenAccent, Icons.shield)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const Text('VS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ],
                ),
              ),
              Expanded(child: _buildFighterCard(widget.opponent, _opponentHp, _opponentMaxHp, Colors.redAccent, Icons.gavel)),
            ],
          ),
          
          const SizedBox(height: 30),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isMyTurn ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isMyTurn ? Colors.greenAccent : Colors.redAccent),
            ),
            child: Text(
              isMyTurn ? 'ТВОЙ ХОД' : 'ОЖИДАНИЕ ХОДА ПРОТИВНИКА...',
              style: TextStyle(color: isMyTurn ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0A),
                border: Border.all(color: const Color(0xFF3A3A3A)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  final entry = _log[index];
                  final isPlayer = entry['actor'] != widget.opponent;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: isPlayer ? MainAxisAlignment.start : MainAxisAlignment.end,
                      children: [
                        if (isPlayer) const Icon(Icons.arrow_forward, color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 4),
                        Flexible(child: Text(entry['message'] ?? '', style: TextStyle(color: isPlayer ? Colors.greenAccent : Colors.redAccent, fontSize: 14))),
                        const SizedBox(width: 4),
                        if (!isPlayer) const Icon(Icons.arrow_back, color: Colors.redAccent, size: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isMyTurn ? const Color(0xFF8B0000) : const Color(0xFF3A3A3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: isMyTurn ? 10 : 0,
                side: BorderSide(color: isMyTurn ? const Color(0xFFD4AF37) : Colors.transparent, width: 2),
              ),
              onPressed: (!isMyTurn || _isLoading) ? null : _attack,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.gavel, size: 28, color: isMyTurn ? Colors.white : Colors.white54),
                        const SizedBox(width: 10),
                        Text(
                          isMyTurn ? 'АТАКОВАТЬ' : 'ЖДИТЕ...',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 3, color: isMyTurn ? Colors.white : Colors.white54),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: _surrender,
              child: const Text('СДАТЬСЯ', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterCard(String name, int hp, int maxHp, Color color, IconData icon) {
    double hpPercent = maxHp > 0 ? (hp / maxHp).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: color, width: 3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)],
          ),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 10),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 5),
        Container(
          height: 18,
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(9), border: Border.all(color: color, width: 1.5)),
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: hpPercent,
                child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(7))),
              ),
              Center(child: Text('$hp / $maxHp', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ],
    );
  }
}