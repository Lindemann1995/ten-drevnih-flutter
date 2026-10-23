import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';

class GuildUpgradesScreen extends StatefulWidget {
  const GuildUpgradesScreen({super.key});

  @override
  State<GuildUpgradesScreen> createState() => _GuildUpgradesScreenState();
}

class _GuildUpgradesScreenState extends State<GuildUpgradesScreen> {
  List<dynamic> _upgrades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpgrades();
  }

  Future<void> _loadUpgrades() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getGuildUpgrades();
    if (result['success']) {
      setState(() {
        _upgrades = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _upgrade(String type, String name) async {
    final result = await ApiClient.upgradeBuilding(type);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name улучшено!'), backgroundColor: Colors.green));
        _loadUpgrades();
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
        title: const Text('КУЗНЯ ГИЛЬДИИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).padding.bottom + 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72, // Оптимальная высота
                ),
                itemCount: _upgrades.length,
                itemBuilder: (context, index) {
                  final up = _upgrades[index];
                  final level = up['level'] as int;
                  final maxLevel = level >= 3;
                  final nextCost = up['next_level_cost'];
                  
                  Color borderColor = const Color(0xFF3A3A3A);
                  Color glowColor = Colors.transparent;
                  
                  if (level == 1) {
                    borderColor = const Color(0xFFCD7F32);
                    glowColor = const Color(0xFFCD7F32).withValues(alpha: 0.2);
                  } else if (level == 2) {
                    borderColor = const Color(0xFFC0C0C0);
                    glowColor = const Color(0xFFC0C0C0).withValues(alpha: 0.2);
                  } else if (level == 3) {
                    borderColor = const Color(0xFFD4AF37);
                    glowColor = const Color(0xFFD4AF37).withValues(alpha: 0.3);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
                      ),
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (level > 0) BoxShadow(color: glowColor, blurRadius: 10, spreadRadius: 1)
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Верхняя часть: Иконка и Название
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                          child: Column(
                            children: [
                              Text(up['icon'] ?? '🏰', style: const TextStyle(fontSize: 32)),
                              const SizedBox(height: 4),
                              Text(
                                up['name'],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: borderColor, fontSize: 14, fontWeight: FontWeight.bold, height: 1.1),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                up['description'],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        
                        // Звезды
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            return Icon(
                              Icons.star,
                              size: 16,
                              color: i < level ? const Color(0xFFD4AF37) : const Color(0xFF3A3A3A),
                            );
                          }),
                        ),

                        // Стоимость (Золото + Иконка ресурса с тултипом)
                        if (!maxLevel && nextCost != null)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF3A3A3A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Золото
                                Text('${nextCost['gold']}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 2),
                                const Icon(Icons.monetization_on, color: Colors.amber, size: 14),
                                
                                // Ресурс (если есть)
                                if (nextCost['item_name'] != null) ...[
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: '${nextCost['item_name']}\n\n${nextCost['item_description'] ?? ''}',
                                    triggerMode: TooltipTriggerMode.tap, // Тултип по нажатию
                                    showDuration: const Duration(seconds: 3),
                                    textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A0A0A),
                                      border: Border.all(color: const Color(0xFFD4AF37)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          AssetPaths.forItem(nextCost['item_image'], nextCost['item_slug']),
                                          width: 16, height: 16,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.white70, size: 14),
                                        ),
                                        const SizedBox(width: 2),
                                        Text('${nextCost['quantity']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        
                        // Кнопка
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: maxLevel ? const Color(0xFF3A3A3A) : const Color(0xFF8B0000),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: maxLevel ? 0 : 2,
                              ),
                              onPressed: maxLevel ? null : () => _upgrade(up['type'], up['name']),
                              child: Text(
                                maxLevel ? 'МАКС' : 'УЛУЧШИТЬ', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}