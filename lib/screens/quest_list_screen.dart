import 'package:flutter/material.dart';
import '../services/api_client.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _error;
  
  List<dynamic> _activeQuests = [];
  List<dynamic> _allQuests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final activeResult = await ApiClient.getPlayerQuests();
    final allResult = await ApiClient.getAllQuests();
    
    if (!mounted) return;
    
    if (activeResult['success'] == true && allResult['success'] == true) {
      setState(() {
        _activeQuests = activeResult['data'];
        _allQuests = allResult['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = activeResult['error'] ?? allResult['error'] ?? 'Ошибка загрузки';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        title: const Text('📜 ЖУРНАЛ ЗАДАНИЙ', 
          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'АКТИВНЫЕ'),
            Tab(text: 'ОБЩИЕ'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveTab(),
                    _buildAllTab(),
                  ],
                ),
    );
  }

  // Вкладка 1: Активные
  Widget _buildActiveTab() {
    if (_activeQuests.isEmpty) {
      return const Center(
        child: Text('У тебя пока нет активных квестов.\nПоговори с NPC!', 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activeQuests.length,
      itemBuilder: (context, index) {
        final qData = _activeQuests[index];
        final q = qData['quest_details'];
        final status = qData['status'];
        final progress = qData['progress_data'];
        
        return GestureDetector(
          onTap: () => _showQuestDetails(q, isTaken: true, isReady: status == 'ready', progress: progress, pqId: qData['id']),
          child: _buildQuestCard(
            quest: q,
            isReady: status == 'ready',
            progress: progress,
          ),
        );
      },
    );
  }

  // Вкладка 2: Общие (Доступные)
  Widget _buildAllTab() {
    if (_allQuests.isEmpty) {
      return const Center(
        child: Text('Нет доступных квестов для твоего уровня.', 
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16)
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allQuests.length,
      itemBuilder: (context, index) {
        final q = _allQuests[index];
        final isTaken = q['is_taken'] == true;
        
        return GestureDetector(
          onTap: () => _showQuestDetails(q, isTaken: isTaken),
          child: _buildQuestCard(
            quest: q,
            isTaken: isTaken,
            isNew: !isTaken,
          ),
        );
      },
    );
  }

  // Универсальная карточка
  Widget _buildQuestCard({
    required Map<String, dynamic> quest,
    bool isReady = false,
    bool isTaken = false,
    bool isNew = false,
    Map<String, dynamic>? progress,
  }) {
    final title = quest['title'];
    final description = quest['description'];
    final rewardExp = quest['reward_exp'] ?? 0;
    final rewardGold = quest['reward_gold'] ?? 0;
    final hasLoot = quest['reward_item_name'] != null || quest['reward_resource_name'] != null;
    final objectives = quest['objectives'] as List?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(
          color: isReady ? const Color(0xFF2A8B2A) : (isTaken ? Colors.grey : const Color(0xFF3A1A1A)),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isReady) BoxShadow(color: const Color(0xFF2A8B2A).withOpacity(0.2), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: isTaken ? Colors.white54 : const Color(0xFFD4AF37),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isReady)
                  _buildBadge('ГОТОВ', const Color(0xFF2A8B2A))
                else if (isTaken)
                  _buildBadge('ВЗЯТ', Colors.grey)
                else if (isNew)
                  _buildBadge('NEW', const Color(0xFF8B0000)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: isTaken ? Colors.white38 : Colors.white70),
            ),
            const Divider(color: Color(0xFF3A1A1A), height: 24),
            
            // Награды в карточке (по центру)
            Text(
              'Опыт: $rewardExp  |  Золото: $rewardGold',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              hasLoot ? 'Лут: Присутствует' : 'Лут: не предусмотрено',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: hasLoot ? const Color(0xFF6BBF6B) : Colors.white38, 
                fontSize: 12, 
                fontStyle: hasLoot ? FontStyle.normal : FontStyle.italic
              ),
            ),

            // Прогресс (только для активных)
            if (objectives != null && progress != null) ...[
              const SizedBox(height: 12),
              ...objectives.map<Widget>((obj) {
                final current = progress[obj['id'].toString()] ?? 0;
                final required = obj['required_count'];
                final isDone = current >= required;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isDone ? const Color(0xFF2A8B2A) : Colors.white38, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${obj['target_name']}: $current / $required',
                        style: TextStyle(
                          color: isDone ? Colors.white54 : Colors.white,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  // Окно с подробностями
  void _showQuestDetails(Map<String, dynamic> quest, {bool isTaken = false, bool isReady = false, Map<String, dynamic>? progress, int? pqId}) {
    final hasItem = quest['reward_item_name'] != null;
    final hasResource = quest['reward_resource_name'] != null;
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "QuestDetails",
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: const Color.fromARGB(0, 243, 17, 17),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 32, 24, 24),
                border: Border.all(color: const Color.fromARGB(255, 121, 92, 0), width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 160, 139, 139).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, color: Color.fromARGB(255, 165, 34, 34), size: 50),
                  const SizedBox(height: 16),
                  
                  Text(
                    quest['title'], 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color.fromARGB(255, 33, 151, 62), fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif')
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Color.fromARGB(255, 245, 4, 152), thickness: 1),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        quest['description'], 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color.fromARGB(179, 41, 216, 6), fontSize: 16, height: 1.5, fontFamily: 'serif')
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFD4AF37), thickness: 1),
                  const SizedBox(height: 16),

                  // 🆕 БЛОК НАГРАД (ВСЁ ПО ЦЕНТРУ)
                  const Text('НАГРАДА:', style: TextStyle(color: Color.fromARGB(137, 214, 26, 26), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  
                  // Опыт и Золото
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildReward(Icons.star, '+${quest['reward_exp']} Опыта', const Color(0xFF6BBF6B)),
                      const SizedBox(width: 16),
                      _buildReward(Icons.monetization_on, '+${quest['reward_gold']} Золота', const Color(0xFFD4AF37)),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF3A1A1A), thickness: 1),
                  const SizedBox(height: 12),

                  // Лут
                  const Text('Предметы:', style: TextStyle(color: Color.fromARGB(137, 104, 106, 230), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  
                  if (hasItem || hasResource)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (hasItem)
                          _buildItemReward(
                            quest['reward_item_slug'], 
                            quest['reward_item_name'], 
                            quest['reward_item_qty'], 
                            quest['reward_item_rarity']
                          ),
                        if (hasResource)
                          _buildItemReward(
                            quest['reward_resource_slug'], 
                            quest['reward_resource_name'], 
                            quest['reward_resource_qty'], 
                            quest['reward_resource_rarity']
                          ),
                      ],
                    )
                  else
                    const Text('Не предусмотрено', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                  
                  const SizedBox(height: 24),
                  _buildActionButton(quest, isTaken: isTaken, isReady: isReady, pqId: pqId),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  // Виджет для отрисовки предмета в награде (в окне)
  Widget _buildItemReward(String slug, String name, int qty, String rarity) {
    Color rarityColor = Colors.grey;
    if (rarity == 'uncommon') rarityColor = const Color(0xFF4A8B4A);
    if (rarity == 'rare') rarityColor = const Color(0xFF3A5A8B);
    if (rarity == 'epic') rarityColor = const Color(0xFF8B3A8B);
    if (rarity == 'legendary') rarityColor = const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(color: rarityColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/items/$slug.png',
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, size: 24, color: rarityColor),
          ),
          const SizedBox(width: 8),
          Text(
            '${name} (x$qty)',
            style: TextStyle(color: rarityColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> quest, {required bool isTaken, required bool isReady, int? pqId}) {
    if (isReady) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final res = await ApiClient.completeQuest(pqId!);
            if (res['success'] == true) {
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Квест сдан!'), backgroundColor: Color(0xFF2A8B2A)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['error'] ?? 'Ошибка при сдаче'), 
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A8B2A), 
            foregroundColor: Colors.white, 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          child: const Text('СДАТЬ КВЕСТ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      );
    } else if (isTaken) {
      return const Text('Квест уже в активных', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic));
    } else {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final res = await ApiClient.acceptQuest(quest['id']);
            if (res['success'] == true) {
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Квест взят!'), backgroundColor: Color(0xFFD4AF37)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res['error'] ?? 'Ошибка при взятии'), 
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ));
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37), 
            foregroundColor: const Color(0xFF0A0A0A), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          ),
          child: const Text('ВЗЯТЬ КВЕСТ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      );
    }
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReward(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}