import 'package:flutter/material.dart';
import '../services/api_client.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await ApiClient.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _profile = result['data']; _isLoading = false; });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/ui/stats_bg.png'), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)), onPressed: () => Navigator.pop(context)),
                          const Expanded(
                            child: Text('СТАТИСТИКА', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 3), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatCard('⚔️ Убито монстров', '${_profile?['enemies_killed'] ?? 0}'),
                          _buildStatCard('🏆 Уровень', '${_profile?['level'] ?? 1}'),
                          _buildStatCard('💰 Золото', '${_profile?['gold'] ?? 0}'),
                          const SizedBox(height: 20),
                          const Text('ХАРАКТЕРИСТИКИ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          _buildStatCard('💪 Сила', '${_profile?['strength'] ?? 0}'),
                          _buildStatCard('🏃 Ловкость', '${_profile?['agility'] ?? 0}'),
                          _buildStatCard('🧠 Интеллект', '${_profile?['intelligence'] ?? 0}'),
                          _buildStatCard('🛡 Выносливость', '${_profile?['endurance'] ?? 0}'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.7),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}