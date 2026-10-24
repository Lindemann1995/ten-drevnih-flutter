import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/asset_paths.dart'; // Добавили для красивых иконок

class GuildBankScreen extends StatefulWidget {
  final bool canWithdraw;

  const GuildBankScreen({super.key, required this.canWithdraw});

  @override
  State<GuildBankScreen> createState() => _GuildBankScreenState();
}

class _GuildBankScreenState extends State<GuildBankScreen> {
  List<dynamic> _bankItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBank();
  }

  Future<void> _loadBank() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.getBankItems();
    if (result['success']) {
      setState(() {
        _bankItems = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  // ================= ЗАБРАТЬ ИЗ БАНКА =================
  Future<void> _showWithdrawDialog(String itemName, String itemSlug) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        title: Text('Забрать $itemName', style: const TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Количество',
            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(context);
              
              final result = await ApiClient.withdrawFromBank(itemSlug, amount);
              if (mounted) {
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ресурсы забраны!'), backgroundColor: Colors.green));
                  _loadBank();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  // ================= ПОЛОЖИТЬ В БАНК =================
  Future<void> _showDepositSheet() async {
    final invResult = await ApiClient.getInventory();
    if (!invResult['success']) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invResult['error']), backgroundColor: Colors.red));
      return;
    }

    final inventoryData = invResult['data']['items'] as List<dynamic>;
    final resources = inventoryData.where((i) => i['item_type'] == 'resource').toList();

    if (resources.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('У тебя нет ресурсов в инвентаре')));
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            const Text('ВЫБЕРИ РЕСУРС', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: resources.length,
                itemBuilder: (context, index) {
                  final item = resources[index];
                  final rarity = item['rarity'] ?? 'common';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      // Красивая иконка из твоего инвентаря
                      leading: Image.asset(
                        AssetPaths.forItem(item['image_path'], item['slug']),
                        width: 40, height: 40,
                        errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Color(0xFFD4AF37)),
                      ),
                      title: Text(item['name'] ?? 'Неизвестный ресурс', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('В инвентаре: ${item['quantity']}', style: const TextStyle(color: Colors.white54)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Закрываем окно
                          _showDepositAmountDialog(item['name'], item['slug']);
                        },
                        child: const Text('ПОЛОЖИТЬ'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDepositAmountDialog(String itemName, String itemSlug) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0A),
        title: Text('Положить $itemName', style: const TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Количество',
            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              Navigator.pop(context);
              
              final result = await ApiClient.depositToBank(itemSlug, amount);
              if (mounted) {
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ресурсы положены в Хранилище гильдии!'), backgroundColor: Colors.green));
                  _loadBank();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Хранилище ГИЛЬДИИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : Column(
                children: [
                  Expanded(
                    child: _bankItems.isEmpty
                        ? const Center(child: Text('Банк пуст', style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _bankItems.length,
                            itemBuilder: (context, index) {
                              final item = _bankItems[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A0A0A),
                                  border: Border.all(color: const Color(0xFF3A3A3A)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50, height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A0A0A),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFD4AF37)),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          AssetPaths.forItem(item['item_image'], item['item_slug']),
                                          errorBuilder: (_, __, ___) => const Text('📦', style: TextStyle(fontSize: 24)),
                                        )
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['item_name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text('В Хранилище: ${item['quantity']}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    if (widget.canWithdraw)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                        onPressed: () => _showWithdrawDialog(item['item_name'], item['item_slug']),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16, 
                      16, 
                      16, 
                      MediaQuery.of(context).padding.bottom + 20
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showDepositSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('ПОЛОЖИТЬ РЕСУРСЫ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}