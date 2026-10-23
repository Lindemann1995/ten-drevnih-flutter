import 'package:flutter/material.dart';
import '../services/api_client.dart';

class GuildTreasuryScreen extends StatefulWidget {
  final int currentTreasury;
  final bool canWithdraw; // Лидер или зам?

  const GuildTreasuryScreen({
    super.key,
    required this.currentTreasury,
    required this.canWithdraw,
  });

  @override
  State<GuildTreasuryScreen> createState() => _GuildTreasuryScreenState();
}

class _GuildTreasuryScreenState extends State<GuildTreasuryScreen> {
  final _amountController = TextEditingController();
  bool _isLoading = false;
  late int _treasury;

  @override
  void initState() {
    super.initState();
    _treasury = widget.currentTreasury;
  }

  Future<void> _deposit() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    final result = await ApiClient.depositGuildGold(amount);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Золото в казне!'), backgroundColor: Colors.green));
        setState(() => _treasury += amount);
        _amountController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _withdraw() async {
    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);
    final result = await ApiClient.withdrawGuildGold(amount);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Золото выведено!'), backgroundColor: Colors.green));
        setState(() => _treasury -= amount);
        _amountController.clear();
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
        title: const Text('КАЗНА', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFFD4AF37)),
            const SizedBox(height: 20),
            Text(
              '$_treasury',
              style: const TextStyle(color: Colors.amber, fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const Text('золота в казне', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A0A0A),
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('ПОЛОЖИТЬ'),
                  ),
                ),
                if (widget.canWithdraw) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _withdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A0A0A),
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('ЗАБРАТЬ'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}