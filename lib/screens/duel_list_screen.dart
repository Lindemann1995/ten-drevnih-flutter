import 'dart:async'; // <-- Добавлен импорт для Timer
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'duel_challenge_screen.dart';
import 'duel_screen.dart';

class DuelListScreen extends StatefulWidget {
  const DuelListScreen({super.key});

  @override
  State<DuelListScreen> createState() => _DuelListScreenState();
}

class _DuelListScreenState extends State<DuelListScreen> {
  List<dynamic> _duels = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDuels();
    // Автообновление каждые 2 секунды
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _loadDuels(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDuels({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    final result = await ApiClient.getActiveDuels();
    if (result['success'] && mounted) {
      setState(() {
        _duels = result['data'];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(int duelId) async {
    final result = await ApiClient.acceptDuel(duelId);
    if (mounted) {
      if (result['success']) {
        _loadDuels();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _decline(int duelId) async {
    final result = await ApiClient.declineDuel(duelId);
    if (mounted) {
      if (result['success']) {
        _loadDuels();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('АРЕНА', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const DuelChallengeScreen()));
              _loadDuels();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : _duels.isEmpty
                ? const Center(
                    child: Text(
                      'Активных дуэлей нет.\nНажми + чтобы вызвать кого-то на бой.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _duels.length,
                    itemBuilder: (context, index) {
                      final d = _duels[index];
                      final isPending = d['status'] == 'pending';
                      final isActive = d['status'] == 'active';
                      final isMyChallenge = d['is_my_challenge'] == true;
                      
                      String title;
                      if (isPending) {
                        title = isMyChallenge
                            ? 'Ты вызвал ${d['opponent']}'
                            : '${d['challenger']} вызвал тебя';
                      } else {
                        title = '${d['challenger']} vs ${d['opponent']}';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0A0A),
                          border: Border.all(
                            color: isActive ? const Color(0xFFD4AF37) : const Color(0xFF3A3A3A),
                            width: isActive ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isActive
                              ? [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)]
                              : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.flash_on : Icons.hourglass_top,
                                  color: isActive ? const Color(0xFFD4AF37) : Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (isPending && !isMyChallenge) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('ОТКЛОНИТЬ'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        side: const BorderSide(color: Colors.redAccent),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _decline(d['id']),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('ПРИНЯТЬ'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => _accept(d['id']),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isActive) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.sports_kabaddi),
                                  label: const Text('ВОЙТИ В БОЙ'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B0000),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DuelScreen(
                                          duelId: d['id'],
                                          challenger: d['challenger'],
                                          opponent: d['opponent'],
                                          myUsername: d['my_username'],
                                          currentTurn: d['current_turn'],
                                        ),
                                      ),
                                    );
                                    _loadDuels();
                                  },
                                ),
                              ),
                            ] else if (isPending && isMyChallenge) ...[
                              const Center(
                                child: Text(
                                  'Ожидание ответа противника...',
                                  style: TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}