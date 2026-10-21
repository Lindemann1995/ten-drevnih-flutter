import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart'; // 🆕 Добавили импорт

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _items = [];
  Map<String, dynamic> _equipment = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    final invResult = await ApiClient.getInventory();
    final eqResult = await ApiClient.getEquipment();

    if (!mounted) return;
    if (invResult['success'] == true) {
      setState(() {
        _items = (invResult['data']['items'] as List<dynamic>)
            .where((item) => item['is_equipped'] != true) // 🆕 Скрываем надетые из рюкзака
    .toList();
        if (eqResult['success'] == true) {
          _equipment = eqResult['data']['equipment'] ?? {};
        }
        _isLoading = false;
      });
    } else {
      setState(() { _error = invResult['error']; _isLoading = false; });
    }
  }

  Future<void> _equip(String itemSlug) async {
    final result = await ApiClient.equipItem(itemSlug);
    if (!mounted) return;
    if (result['success'] == true) { _loadAll(); } 
    else { _showMessage(result['error'] ?? 'Ошибка'); }
  }

  Future<void> _unequip(String slot) async {
    final result = await ApiClient.unequipItem(slot);
    if (!mounted) return;
    if (result['success'] == true) { _loadAll(); } 
    else { _showMessage(result['error'] ?? 'Ошибка'); }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B0000)));
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'uncommon': return const Color(0xFF4A8B4A);
      case 'rare': return const Color(0xFF3A5A8B);
      case 'epic': return const Color(0xFF8B3A8B);
      case 'legendary': return const Color(0xFFD4AF37);
      default: return const Color(0xFF8B8B8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/bg_texture.png'), // Твой темный фон
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _error != null
                  ? _buildError()
                  : Column(
                      children: [
                        // Кнопка НАЗАД
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37), size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // ЦЕНТРАЛЬНАЯ ЧАСТЬ (Манекен и Слоты)
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Манекен (в самом центре)
                              Image.asset(
                                'assets/images/ui/manequin.png', // Твоя картинка манекена
                                height: 400, // Фиксированная высота
                                fit: BoxFit.contain,
                              ),
                              
                              // 2. Рамки слотов (слева и справа)
                              // ЛЕВАЯ КОЛОНКА
                              Positioned(left: 20, top: 50, child: _buildSlot('helmet')),
                              Positioned(left: 20, top: 140, child: _buildSlot('amulet')),
                              Positioned(left: 20, top: 230, child: _buildSlot('weapon')),
                              Positioned(left: 20, top: 320, child: _buildSlot('ring')),
                              
                              // ПРАВАЯ КОЛОНКА
                              Positioned(right: 20, top: 50, child: _buildSlot('armor')),
                              Positioned(right: 20, top: 140, child: _buildSlot('ring')),
                              Positioned(right: 20, top: 230, child: _buildSlot('shield')),
                              Positioned(right: 20, top: 320, child: _buildSlot('boots')),
                            ],
                          ),
                        ),

                        // НИЖНЯЯ ПАНЕЛЬ (Рюкзак)
                        Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5), // Затемнение под сеткой
                            border: const Border(top: BorderSide(color: Color(0xFF3A1A1A), width: 2)),
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final rarity = item['rarity'] ?? 'common';
                              return GestureDetector(
                                onTap: () => _showItemDetails(item, isEquipped: item['is_equipped'] == true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A0A0A).withOpacity(0.8),
                                    border: Border.all(color: _rarityColor(rarity), width: 1.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Image.asset(
                                            // 🆕 ИСПОЛЬЗУЕМ НАШУ УТИЛИТУ
                                            AssetPaths.forItem(item['image_path'], item['slug']),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: _rarityColor(rarity), size: 20),
                                          ),
                                        ),
                                      ),
                                      if (item['quantity'] > 1)
                                        Positioned(
                                          right: 2, bottom: 2,
                                          child: Text('x${item['quantity']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          ElevatedButton(onPressed: _loadAll, child: const Text('ПОВТОРИТЬ')),
        ],
      ),
    );
  }

  // Слот с рамкой
  Widget _buildSlot(String slotType) {
    final eq = _equipment[slotType];
    final hasItem = eq != null;
    
    return GestureDetector(
      onTap: hasItem ? () => _showItemDetails(eq, isEquipped: true) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Сама рамка слота
          Image.asset(
            'assets/images/ui/slot_frame.png', 
            width: 100, 
            height: 100,
          ),
          // Если предмет надет — показываем его картинку поверх рамки
          if (hasItem)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                // 🆕 ИСПОЛЬЗУЕМ НАШУ УТИЛИТУ
                AssetPaths.forItem(eq['image_path'], eq['slug']), 
                width: 56,
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: _rarityColor(eq['rarity'] ?? 'common'), size: 40),
              ),
            ),
        ],
      ),
    );
  }

  void _showItemDetails(Map<String, dynamic> item, {required bool isEquipped}) {
    final rarityColor = _rarityColor(item['rarity'] ?? 'common');
    final bonuses = <String>[];
    if ((item['bonus_strength'] ?? 0) > 0) bonuses.add('+${item['bonus_strength']} Сила');
    if ((item['bonus_agility'] ?? 0) > 0) bonuses.add('+${item['bonus_agility']} Ловкость');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), side: BorderSide(color: rarityColor, width: 2)),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['name'], style: TextStyle(color: rarityColor, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...bonuses.map((b) => Text(b, style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 14))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isEquipped) { _unequip(item['equip_slot']); } 
                    else { _equip(item['slug']); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: isEquipped ? const Color(0xFF8B0000) : const Color(0xFF2A5A2A), foregroundColor: Colors.white),
                  child: Text(isEquipped ? 'СНЯТЬ' : 'НАДЕТЬ'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}