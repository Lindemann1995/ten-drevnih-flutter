import 'package:flutter/material.dart';
import '../services/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiClient.getProfile();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _profile = result['data'];
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
                  : _buildProfile(),
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
              onPressed: _loadProfile,
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

  Widget _buildProfile() {
    final p = _profile!;
    final username = p['username'] ?? 'Игрок';
    final level = p['level'] ?? 1;
    final experience = p['experience'] ?? 0;
    final experienceToNext = p['experience_to_next'] ?? 100;
    final health = p['health'] ?? 100;
    final maxHealth = p['max_health'] ?? 100;
    final mana = p['mana'] ?? 50;
    final maxMana = p['max_mana'] ?? 50;
    final gold = p['gold'] ?? 0;
    final classData = p['character_class'];
    final className = classData != null ? classData['name'] : 'Без класса';
    

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // Ник
          Text(
            username.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            className,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 30),

          // Уровень + опыт
          _buildInfoCard('УРОВЕНЬ', '$level'),
          const SizedBox(height: 12),

          // Прогресс-бар опыта
          _buildExpBar(experience, experienceToNext),
          const SizedBox(height: 20),

          // HP / MP
          _buildResourceBar('❤ HP', health, maxHealth, const Color(0xFF8B0000)),
          const SizedBox(height: 10),
          _buildResourceBar('💧 MP', mana, maxMana, const Color(0xFF3A5A8B)),
          const SizedBox(height: 20),

          // Золото
          _buildInfoCard('💰 ЗОЛОТО', '$gold'),
          const SizedBox(height: 20),

          // Статы
          const Text(
            'СТАТЫ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF37),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          _buildStat('💪 Сила', p['strength'] ?? 0),
          _buildStat('🏃 Ловкость', p['agility'] ?? 0),
          _buildStat('🧠 Интеллект', p['intelligence'] ?? 0),
          _buildStat('🛡 Выносливость', p['endurance'] ?? 0),
          _buildStat('👁 Рассудок', p['sanity'] ?? 0),
          const SizedBox(height: 30),

          // Выход
          SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () async {
                await ApiClient.clearToken();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A0A),
                foregroundColor: const Color(0xFF8B8B8B),
                side: const BorderSide(color: Color(0xFF3A3A3A), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ВЫЙТИ ИЗ АККАУНТА',
                style: TextStyle(fontSize: 14, letterSpacing: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A0A),
        border: Border.all(color: const Color(0xFF3A1A1A), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpBar(int current, int max) {
    final percent = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ОПЫТ: $current / $max',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceBar(String label, int current, int max, Color color) {
    final percent = max > 0 ? current / max : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$current / $max',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: color, width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(
            '$value',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}