import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';

class GuildDailyQuestsScreen extends StatefulWidget {
  const GuildDailyQuestsScreen({super.key});

  @override
  State<GuildDailyQuestsScreen> createState() => _GuildDailyQuestsScreenState();
}

class _GuildDailyQuestsScreenState extends State<GuildDailyQuestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _quests = [];
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiClient.getGuildDailyQuests();

    if (result['success']) {
      setState(() {
        _quests = result['data']['quests'] ?? [];
        _streak = result['data']['streak'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _claimReward(int questId) async {
    final result = await ApiClient.claimDailyQuest(questId);
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['data']['message'] ?? 'Награда получена!', style: const TextStyle(color: Colors.black)),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
        _loadQuests(); // Обновляем список
      }
    } else {
      if (mounted) {
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
        elevation: 0,
        title: const Text('ЕЖЕДНЕВКИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 3, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }

    return Column(
      children: [
        // Плашка с серией
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 10),
              Text('Серия: $_streak дн.', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Список квестов
        Expanded(
          child: _quests.isEmpty
              ? const Center(child: Text('На сегодня квестов нет', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _quests.length,
                  itemBuilder: (context, index) {
                    final q = _quests[index];
                    return _buildQuestCard(q);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuestCard(Map<String, dynamic> q) {
    final isCompleted = q['is_completed'] == true;
    final isClaimed = q['is_claimed'] == true;
    final progress = q['progress'] ?? 0;
    final required = q['required_count'] ?? 1;
    final double percent = (progress / required).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
        ),
        border: Border.all(color: isCompleted ? const Color(0xFFD4AF37) : Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (isCompleted) BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.2), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Картинка квеста (если есть)
              if (q['image_path'] != null && q['image_path'].toString().isNotEmpty)
                Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      // 🆕 Используем AssetPaths для правильного пути
                      image: AssetImage(AssetPaths.forFlutter(q['image_path'])),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q['title'] ?? 'Квест', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(q['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Прогресс-бар
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Прогресс гильдии:', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('$progress / $required', style: TextStyle(color: isCompleted ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.greenAccent : const Color(0xFFD4AF37)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          
          const SizedBox(height: 16),
          
          // Награды и кнопка
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Твои убийства: ${q['my_kills'] ?? 0}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 14),
                      const SizedBox(width: 4),
                      Text('${q['reward_gold']}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.star, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 4),
                      Text('${q['reward_exp']} XP', style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              
              if (isCompleted && !isClaimed)
                ElevatedButton(
                  onPressed: () => _claimReward(q['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ЗАБРАТЬ', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else if (isClaimed)
                const Text('✅ Получено', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
              else
                const Text('В процессе...', style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }
}