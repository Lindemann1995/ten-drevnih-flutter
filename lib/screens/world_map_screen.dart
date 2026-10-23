import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart';
import 'combat_screen.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  bool _isLoading = true;
  String? _error;
  
  List<dynamic> _locations = [];
  Map<String, dynamic>? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiClient.getLocations();
    
    if (!mounted) return;
    if (result['success'] == true) {
      final locs = result['data'] as List;
      setState(() {
        _locations = locs;
        if (locs.isNotEmpty) {
          _selectedLocation = locs.first;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  void _showEnemyDetails(dynamic enemy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(enemy['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Уровень: ${enemy['level']}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Divider(color: Color(0xFF3A1A1A), height: 24),
              Text(enemy['description'] ?? 'Описание отсутствует.', style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CombatScreen(
                          enemySlug: enemy['slug'],
                          enemyName: enemy['name'],
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('В БОЙ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
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
      appBar: AppBar(
        title: const Text('Локация', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A0A0A),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЛЕВАЯ ПАНЕЛЬ (СПИСОК ЛОКАЦИЙ)
          Container(
            width: 130,
            decoration: const BoxDecoration(
              color: Color(0xFF0F0505),
              border: Border(right: BorderSide(color: Color(0xFF3A1A1A), width: 1)),
            ),
            child: ListView.builder(
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final loc = _locations[index];
                final isSelected = _selectedLocation?['id'] == loc['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLocation = loc;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A1A1A) : Colors.transparent,
                      border: Border(
                        left: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, width: 4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 20),
                        const SizedBox(height: 4),
                        Text(
                          loc['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.white54,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ур.${loc['min_level']}+',
                          style: const TextStyle(color: Colors.white30, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ПРАВАЯ ПАНЕЛЬ (МОБЫ)
          Expanded(
            child: _selectedLocation == null 
                ? const Center(child: Text('Выберите локацию', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _selectedLocation!['enemies'].length,
                    itemBuilder: (context, index) {
                      final enemy = _selectedLocation!['enemies'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0A0A),
                          border: Border.all(color: const Color(0xFF3A1A1A)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () => _showEnemyDetails(enemy),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Картинка моба
                                    Image.asset(
                                      AssetPaths.forItem(enemy['image_path'], enemy['slug']),
                                      width: 50, height: 50,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white30),
                                    ),
                                    const SizedBox(width: 12),
                                    // Имя и уровень
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(enemy['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text('Ур. ${enemy['level']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Статы
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, color: Colors.red, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${enemy['health']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.gavel, color: Colors.grey, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${enemy['attack']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.shield, color: Colors.blueGrey, size: 14),
                                    const SizedBox(width: 4),
                                    Text('${enemy['defense']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Опыт и золото
                                Row(
                                  children: [
                                    Text('+${enemy['xp_reward']} EXP', style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 12)),
                                    const SizedBox(width: 12),
                                    Text('+${enemy['gold_reward']} 🪙', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Лут
                                if (enemy['loot'] != null && enemy['loot'].isNotEmpty) ...[
                                  const Divider(color: Color(0xFF3A1A1A), height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: enemy['loot'].map<Widget>((loot) {
                                      return Container(
                                        width: 35, height: 35,
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          border: Border.all(color: const Color(0xFF3A1A1A)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Image.asset(
                                          AssetPaths.forItem(loot['image_path'], loot['slug']),
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 16, color: Colors.white30),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}