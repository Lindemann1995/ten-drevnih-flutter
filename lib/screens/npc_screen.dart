import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';
import 'craft_screen.dart'; // 🆕 Импортируем наш новый экран

class NpcScreen extends StatefulWidget {
  final String npcSlug;

  const NpcScreen({super.key, required this.npcSlug});

  @override
  State<NpcScreen> createState() => _NpcScreenState();
}

class _NpcScreenState extends State<NpcScreen> {
  bool _isLoading = true;
  String? _error;
  
  Map<String, dynamic>? _npc;
  String _currentDialogueText = '';
  List<dynamic> _currentOptions = [];
  
  List<dynamic> _readyQuests = [];

  @override
  void initState() {
    super.initState();
    _loadNpc();
  }

  Future<void> _loadNpc() async {
    setState(() => _isLoading = true);
    
    final npcResult = await ApiClient.getNpc(widget.npcSlug);
    final questsResult = await ApiClient.getPlayerQuests();
    
    if (!mounted) return;
    
    if (npcResult['success'] == true) {
      setState(() {
        _npc = npcResult['data'];
        // Если диалог не был изменен после сдачи квеста, показываем приветствие
        if (_currentDialogueText.isEmpty) {
           _currentDialogueText = _npc!['greeting_text'] ?? '...';
        }
        _currentOptions = _npc!['dialogue_options'] ?? [];
        
        _readyQuests = [];
        if (questsResult['success'] == true) {
          final allQuests = questsResult['data'] as List;
          _readyQuests = allQuests.where((q) {
            final isReady = q['status'] == 'ready';
            final questDetails = q['quest_details'];
            final turnInNpc = questDetails['turn_in_name'];
            return isReady && (turnInNpc == _npc!['name'] || turnInNpc == null);
          }).toList();
        }
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = npcResult['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOption(dynamic option) async {
    setState(() {
      _currentDialogueText = option['response_text'];
      _currentOptions = [];
    });

    if (option['gives_quest'] != null) {
      final questId = option['gives_quest'];
      final res = await ApiClient.acceptQuest(questId);
      
      if (!mounted) return;
      
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Квест принят!', style: TextStyle(color: Colors.black)), backgroundColor: Color(0xFFD4AF37)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _currentOptions = _npc!['dialogue_options'] ?? [];
      });
    }
  }

  Future<void> _turnInQuest(dynamic playerQuest) async {
    final res = await ApiClient.completeQuest(playerQuest['id']);
    
    if (!mounted) return;

    if (res['success'] == true) {
      int exp = res['exp'] ?? 0;
      int gold = res['gold'] ?? 0;
      List<dynamic> items = res['dropped_items'] ?? [];

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A0A0A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('🏆 КВЕСТ СДАН!', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Опыт: +$exp', style: const TextStyle(color: Colors.white)),
              Text('Золото: +$gold', style: const TextStyle(color: Color(0xFFD4AF37))),
              
              // 🆕 БЛОК ОТОБРАЖЕНИЯ ПРЕДМЕТОВ
              if (items.isNotEmpty) ...[
                const Divider(color: Color(0xFF3A1A1A), height: 24),
                const Text('ПОЛУЧЕННЫЕ ПРЕДМЕТЫ:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items.map((item) {
                    Color rarityColor = Colors.grey;
                    if (item['rarity'] == 'uncommon') rarityColor = const Color(0xFF4A8B4A);
                    if (item['rarity'] == 'rare') rarityColor = const Color(0xFF3A5A8B);
                    if (item['rarity'] == 'epic') rarityColor = const Color(0xFF8B3A8B);
                    if (item['rarity'] == 'legendary') rarityColor = const Color(0xFFD4AF37);

                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1A1A),
                        border: Border.all(color: rarityColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                // 🆕 ИСПОЛЬЗУЕМ НАШУ УТИЛИТУ, А НЕ ЖЕСТКИЙ ПУТЬ
                                AssetPaths.forItem(item['image_path'], item['slug']),
                                errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: rarityColor),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 2, bottom: 2,
                            child: Text('x${item['quantity']}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadNpc(); 
              },
              child: const Text('ЗАБРАТЬ', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Ошибка'), backgroundColor: Colors.red),
      );
    }
  }

  // 🆕 ФУНКЦИЯ ДЛЯ ОТКРЫТИЯ КРАФТА
  void _openCraft() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CraftScreen(
          npcSlug: widget.npcSlug, 
          npcName: _npc!['name'],
        ),
      ),
    ).then((_) => _loadNpc()); // Обновляем диалог после возврата
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
        appBar: AppBar(backgroundColor: const Color(0xFF1A0A0A), iconTheme: const IconThemeData(color: Color(0xFFD4AF37))),
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF1A0A0A),
                    child: _npc!['image_path'] != null && _npc!['image_path'].isNotEmpty
                      ? Image.asset(
                          AssetPaths.forFlutter(_npc!['image_path']),
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFFD4AF37), size: 40),
                        )
                      : const Icon(Icons.person, color: Color(0xFFD4AF37), size: 40),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _npc!['name'],
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(color: const Color(0xFF3A1A1A), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _currentDialogueText,
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🆕 КНОПКА КРАФТА (появляется только у Коваля или если есть рецепты)
                  if (widget.npcSlug == 'koval' || widget.npcSlug == 'smith') // Проверь слаг своего кузнеца!
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _openCraft,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A1A1A),
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('🛠 ОТКРЫТЬ КУЗНИЦУ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                  ..._readyQuests.map((pq) {
                    final title = pq['quest_details']['title'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _turnInQuest(pq),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A8B2A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('✅ Сдать: $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }),
                  
                  ..._currentOptions.map<Widget>((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => _handleOption(opt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A0A0A),
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(opt['text'], style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}