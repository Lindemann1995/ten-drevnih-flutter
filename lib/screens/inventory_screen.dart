import 'package:flutter/material.dart';
import '../services/api_client.dart';

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final invResult = await ApiClient.getInventory();
    final eqResult = await ApiClient.getEquipment();

    if (!mounted) return;

    if (invResult['success'] == true) {
      setState(() {
        _items = invResult['data']['items'] as List<dynamic>;
        if (eqResult['success'] == true) {
          _equipment = eqResult['data']['equipment'] ?? {};
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = invResult['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _equip(String itemSlug) async {
    final result = await ApiClient.equipItem(itemSlug);
    if (!mounted) return;
    if (result['success'] == true) {
      _showMessage('Надето');
      _loadAll();
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  Future<void> _unequip(String slot) async {
    final result = await ApiClient.unequipItem(slot);
    if (!mounted) return;
    if (result['success'] == true) {
      _showMessage('Снято');
      _loadAll();
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B0000)),
    );
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

  String _slotName(String slot) {
    switch (slot) {
      case 'weapon': return '⚔ Оружие';
      case 'armor': return '🛡 Броня';
      case 'helmet': return '⛑ Шлем';
      case 'ring': return '💍 Кольцо';
      case 'amulet': return '📿 Амулет';
      default: return slot;
    }
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _error != null
                  ? _buildError()
                  : _buildContent(),
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
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A0A),
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFF8B0000), width: 2),
              ),
              child: const Text('ПОВТОРИТЬ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'ИНВЕНТАРЬ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Экипировка
                const Text(
                  'ЭКИПИРОВКА',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                ..._buildEquipmentSlots(),
                const SizedBox(height: 30),

                // Инвентарь
                const Text(
                  'ПРЕДМЕТЫ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Инвентарь пуст',
                      style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._items.map((item) => _buildItemCard(item)).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEquipmentSlots() {
    final slots = ['weapon', 'armor', 'helmet', 'ring', 'amulet'];
    return slots.map((slot) {
      final eq = _equipment[slot];
      final hasItem = eq != null;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          border: Border.all(
            color: hasItem ? const Color(0xFFD4AF37) : const Color(0xFF3A1A1A),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _slotName(slot),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasItem ? eq['name'] : 'пусто',
                    style: TextStyle(
                      color: hasItem ? const Color(0xFFD4AF37) : Colors.white24,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (hasItem)
              TextButton(
                onPressed: () => _unequip(slot),
                child: const Text('СНЯТЬ', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final rarity = item['rarity'] ?? 'common';
    final rarityColor = _rarityColor(rarity);
    final isEquipped = item['is_equipped'] == true;
    final equipSlot = item['equip_slot'] ?? '';
    final canEquip = equipSlot.isNotEmpty;

    final bonuses = <String>[];
    if ((item['bonus_strength'] ?? 0) > 0) bonuses.add('+${item['bonus_strength']} Сила');
    if ((item['bonus_agility'] ?? 0) > 0) bonuses.add('+${item['bonus_agility']} Ловк');
    if ((item['bonus_intelligence'] ?? 0) > 0) bonuses.add('+${item['bonus_intelligence']} Инт');
    if ((item['bonus_endurance'] ?? 0) > 0) bonuses.add('+${item['bonus_endurance']} Вын');
    if ((item['bonus_sanity'] ?? 0) > 0) bonuses.add('+${item['bonus_sanity']} Расс');
    if ((item['bonus_health'] ?? 0) > 0) bonuses.add('+${item['bonus_health']} HP');
    if ((item['bonus_mana'] ?? 0) > 0) bonuses.add('+${item['bonus_mana']} MP');

    final requiredClasses = (item['required_classes'] as List<dynamic>?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(
          color: isEquipped ? const Color(0xFFD4AF37) : rarityColor,
          width: isEquipped ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item['name']}${item['quantity'] > 1 ? ' x${item['quantity']}' : ''}',
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isEquipped)
                const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 18),
            ],
          ),
          if (bonuses.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              bonuses.join(' • '),
              style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 11),
            ),
          ],
          if (requiredClasses.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Для: ${requiredClasses.join(", ")}',
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 10),
            ),
          ],
          if (canEquip && !isEquipped) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _equip(item['slug']),
                child: const Text('Надеть', style: TextStyle(color: Color(0xFF6BBF6B), fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}