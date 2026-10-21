import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart'; // 🆕 Добавили импорт

class TraderScreen extends StatefulWidget {
  final String traderSlug;
  final String traderName;

  const TraderScreen({
    super.key,
    required this.traderSlug,
    required this.traderName,
  });

  @override
  State<TraderScreen> createState() => _TraderScreenState();
}

class _TraderScreenState extends State<TraderScreen> {
  bool _isLoading = true;
  bool _isBuying = false;
  String? _error;
  List<dynamic> _items = [];
  int _playerGold = 0;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadGold();
  }

  Future<void> _loadGold() async {
    final result = await ApiClient.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _playerGold = result['data']['gold'] ?? 0);
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiClient.getTraderItems(widget.traderSlug);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _items = result['data']['items'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _buyItem(String itemSlug, String itemName, int price) async {
    if (_playerGold < price) {
      _showMessage('Не хватает золота. Нужно: $price');
      return;
    }

    setState(() => _isBuying = true);

    final result = await ApiClient.buyItem(widget.traderSlug, itemSlug);

    if (!mounted) return;
    setState(() => _isBuying = false);

    if (result['success'] == true) {
      _showMessage('Куплено: $itemName');
      setState(() => _playerGold = result['data']['player_gold'] ?? _playerGold);
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
      case 'uncommon':
        return const Color(0xFF4A8B4A);
      case 'rare':
        return const Color(0xFF3A5A8B);
      case 'epic':
        return const Color(0xFF8B3A8B);
      case 'legendary':
        return const Color(0xFFD4AF37);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  String _rarityName(String rarity) {
    switch (rarity) {
      case 'uncommon':
        return 'Необычный';
      case 'rare':
        return 'Редкий';
      case 'epic':
        return 'Эпический';
      case 'legendary':
        return 'Легендарный';
      default:
        return 'Обычный';
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                )
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
            Text(_error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadItems,
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
        // Заголовок
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.traderName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        // Баланс
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('💰 Твоё золото:',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                '$_playerGold',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Товары
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _ItemCard(
                item: item,
                rarityColor: _rarityColor(item['rarity'] ?? 'common'),
                rarityName: _rarityName(item['rarity'] ?? 'common'),
                playerGold: _playerGold,
                isBuying: _isBuying,
                onBuy: () => _buyItem(
                  item['slug'],
                  item['name'],
                  item['price'],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color rarityColor;
  final String rarityName;
  final int playerGold;
  final bool isBuying;
  final VoidCallback onBuy;

  const _ItemCard({
    required this.item,
    required this.rarityColor,
    required this.rarityName,
    required this.playerGold,
    required this.isBuying,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final price = item['price'] ?? 0;
    final canAfford = playerGold >= price;

    final bonuses = <String>[];
    if ((item['bonus_strength'] ?? 0) > 0) bonuses.add('+${item['bonus_strength']} Сила');
    if ((item['bonus_agility'] ?? 0) > 0) bonuses.add('+${item['bonus_agility']} Ловк');
    if ((item['bonus_intelligence'] ?? 0) > 0) bonuses.add('+${item['bonus_intelligence']} Инт');
    if ((item['bonus_endurance'] ?? 0) > 0) bonuses.add('+${item['bonus_endurance']} Вын');
    if ((item['bonus_sanity'] ?? 0) > 0) bonuses.add('+${item['bonus_sanity']} Расс');
    if ((item['bonus_health'] ?? 0) > 0) bonuses.add('+${item['bonus_health']} HP');
    if ((item['bonus_mana'] ?? 0) > 0) bonuses.add('+${item['bonus_mana']} MP');

    final requiredClasses = (item['required_classes'] as List<dynamic>?) ?? [];
    final requiredLevel = item['required_level'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(color: rarityColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  border: Border.all(color: rarityColor, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rarityName,
                  style: TextStyle(color: rarityColor, fontSize: 11),
                ),
              ),
            ],
          ),
          if (bonuses.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              bonuses.join(' • '),
              style: const TextStyle(color: Color(0xFF6BBF6B), fontSize: 12),
            ),
          ],
          if (requiredClasses.isNotEmpty || requiredLevel > 1) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (requiredLevel > 1) 'Ур. $requiredLevel+',
                if (requiredClasses.isNotEmpty) requiredClasses.join(', '),
              ].join(' • '),
              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$price 💰',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFD4AF37) : const Color(0xFF8B0000),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isBuying || !canAfford ? null : onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A0A),
                  foregroundColor: const Color(0xFFD4AF37),
                  side: BorderSide(
                    color: canAfford ? const Color(0xFF8B0000) : const Color(0xFF3A3A3A),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('КУПИТЬ', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}