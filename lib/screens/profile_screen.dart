import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'inventory_screen.dart';
import 'login_screen.dart';

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

  // Окно выбора класса
 void _showClassSelection() {
    // ВРЕМЕННО ОТКЛЮЧЕНО ДЛЯ ТЕСТОВ (потом вернем обратно)
    // if (_profile?['character_class'] != null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Вы уже выбрали класс! Изменить выбор нельзя.'), backgroundColor: Color(0xFF8B0000)),
    //   );
    //   return;
    // }

    ApiClient.getClasses().then((result) {
      if (result['success'] == true) {
        final classes = result['data'] as List<dynamic>;
        
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A0A0A),
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            side: BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Text(
                    'ВЫБЕРИ СВОЙ ПУТЬ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ТЕСТОВЫЙ РЕЖИМ: Класс можно менять!',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6BBF6B), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        final cls = classes[index];
                        return Card(
                          color: const Color(0xFF2A0A0A),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            title: Text(cls['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                            subtitle: Text(cls['description'] ?? 'Нет описания', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                final res = await ApiClient.chooseClass(cls['id']);
                                if (res['success'] == true) {
                                  Navigator.pop(context);
                                  _loadProfile(); // Обновляем профиль
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Ошибка')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A0A0A),
                                foregroundColor: const Color(0xFFD4AF37),
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              child: const Text('ВЫБРАТЬ'),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    });
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
            Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
    final hasClass = classData != null;
    final className = hasClass ? classData['name'] : 'Не выбран';
    final classDescription = hasClass ? (classData['description'] ?? '') : '';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF1A0A0A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), 
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
            const SizedBox(height: 30),

            // ЯЧЕЙКА КЛАССА
            GestureDetector(
              onTap: _showClassSelection,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  border: Border.all(
                    color: hasClass ? const Color(0xFFD4AF37) : const Color(0xFF8B0000), 
                    width: hasClass ? 2 : 2
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Иконка или эмодзи
                    Text(
                      hasClass ? '🎭' : '❓',
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ВАШ КЛАСС', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(
                            hasClass ? className : 'ВЫБРАТЬ КЛАСС',
                            style: TextStyle(
                              color: hasClass ? const Color(0xFFD4AF37) : const Color(0xFFFF4D4D),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hasClass && classDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              classDescription,
                              style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ]
                        ],
                      ),
                    ),
                    if (!hasClass)
                      const Icon(Icons.arrow_forward_ios, color: Color(0xFF8B0000), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Уровень
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

            // Кнопка "Инвентарь"
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  );
                  _loadProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A0A),
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '🎒 ИНВЕНТАРЬ И ЭКИПИРОВКА',
                  style: TextStyle(fontSize: 14, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Кнопка "Выйти"
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await ApiClient.clearToken(); 
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false, 
                    );
                  }
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