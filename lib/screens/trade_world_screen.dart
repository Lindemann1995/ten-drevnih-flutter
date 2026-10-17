import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'trader_screen.dart';

class TradeWorldScreen extends StatefulWidget {
  const TradeWorldScreen({super.key});

  @override
  @override
  State<TradeWorldScreen> createState() => _TradeWorldScreenState();
}

class _TradeWorldScreenState extends State<TradeWorldScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _traders = [];

  @override
  @override
  void initState() {
    super.initState();
    _loadTraders();
  }

  Future<void> _loadTraders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiClient.getTraders('trade_world');

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _traders = result['data']['traders'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'];
        _isLoading = false;
      });
    }
  }

  @override
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
              onPressed: _loadTraders,
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
        // Заголовок + кнопка назад
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'МИР ТОРГОВЛИ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Оживлённое место, где торговцы предлагают товары со всего мира.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _traders.length,
            itemBuilder: (context, index) {
              final t = _traders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TraderCard(
                  name: t['name'] ?? '',
                  description: t['description'] ?? '',
                  icon: t['icon'] ?? '',
                  itemsCount: t['items_count'] ?? 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TraderScreen(
                          traderSlug: t['slug'],
                          traderName: t['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TraderCard extends StatelessWidget {
  final String name;
  final String description;
  final String icon;
  final int itemsCount;
  final VoidCallback onTap;

  const _TraderCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.itemsCount,
    required this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0A0A),
          border: Border.all(color: const Color(0xFF8B0000), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.store, color: Color(0xFFD4AF37), size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Товаров: $itemsCount',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B8B8B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
          ],
        ),
      ),
    );
  }
}