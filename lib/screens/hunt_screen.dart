import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'combat_screen.dart';
import 'npc_screen.dart'; // 🆕 Импорт экрана NPC

class HuntScreen extends StatefulWidget {
  const HuntScreen({super.key});

  @override
  State<HuntScreen> createState() => _HuntScreenState();
}

class _HuntScreenState extends State<HuntScreen> {
  bool _isLoading = true;
  String? _error;
  
  List<dynamic> _farmLocations = [];
  Map<String, dynamic>? _selectedLocation; 
  List<dynamic> _enemies = [];

  @override
  void initState() {
    super.initState();
    _loadFarmLocations();
  }

  // 1. Загружаем список локаций и фильтруем
  Future<void> _loadFarmLocations() async {
    setState(() { _isLoading = true; _error = null; });
    
    final result = await ApiClient.getLocations(); 
    
    if (!mounted) return;
    if (result['success'] == true) {
      // Сервер присылает список локаций
      final allLocations = result['data'] as List<dynamic>;
      
      setState(() {
        // Оставляем только те, где тип 'farm'
        _farmLocations = allLocations.where((loc) => loc['location_type'] == 'farm').toList();
        _isLoading = false;
      });
    } else {
      setState(() { _error = result['error']; _isLoading = false; });
    }
  }

  // 2. Загружаем мобов для выбранной локации
  Future<void> _loadEnemies(String slug) async {
    setState(() { _isLoading = true; _error = null; });

    final result = await ApiClient.getLocationEnemies(slug);
    
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _enemies = result['data']['enemies'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() { _error = result['error']; _isLoading = false; });
    }
  }

  void _startFight(String enemySlug, String enemyName) {
    print("=== НАЖАТА КНОПКА АТАКИ: $enemyName (СЛАГ: $enemySlug) ===");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CombatScreen(enemySlug: enemySlug, enemyName: enemyName),
      ),
    );
  }

  // 🆕 Функция для открытия диалога с NPC
  void _openNpcDialogue() {
    // ВАЖНО: слаг должен совпадать с тем, что ты создал в админке!
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NpcScreen(npcSlug: 'elder')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A0A),
        foregroundColor: const Color(0xFFD4AF37),
        title: const Text('РЕЖИМ ОХОТЫ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        leading: _selectedLocation != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() { _selectedLocation = null; _loadFarmLocations(); }),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
              : _selectedLocation == null
                  ? _buildLocationList()
                  : _buildEnemyList(),
    );
  }

  // Экран 1: Выбор локации
  Widget _buildLocationList() {
    if (_farmLocations.isEmpty) {
      return const Center(child: Text('Нет доступных локаций для охоты', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _farmLocations.length,
      itemBuilder: (context, index) {
        final loc = _farmLocations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFFD4AF37), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.forest, color: Color(0xFF8B0000), size: 40),
            title: Text(loc['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Мин. уровень: ${loc['min_level']}', style: const TextStyle(color: Colors.white54)),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
            onTap: () {
              setState(() {
                _selectedLocation = loc;
              });
              _loadEnemies(loc['slug']);
            },
          ),
        );
      },
    );
  }

  // Экран 2: Список мобов
  Widget _buildEnemyList() {
    if (_enemies.isEmpty) {
      return const Center(child: Text('В этой локации пока нет врагов', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // 🆕 itemCount увеличиваем на 1 для кнопки NPC
      itemCount: _enemies.length + 1,
      itemBuilder: (context, index) {
        // Если это последний элемент — рисуем кнопку NPC
        if (index == _enemies.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
            child: SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _openNpcDialogue,
                icon: const Icon(Icons.person, color: Color(0xFFD4AF37), size: 28),
                label: const Text(
                  'ПОГОВОРИТЬ СО СТАРЕЙШИНОЙ',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A0A),
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          );
        }

        // Обычные мобы
        final enemy = _enemies[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A0A),
            border: Border.all(color: const Color(0xFF3A1A1A), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Text(enemy['icon'] ?? '👹', style: const TextStyle(fontSize: 40)),
            title: Text(enemy['name'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Уровень: ${enemy['level']} | HP: ${enemy['hp']}', style: const TextStyle(color: Colors.white54)),
            trailing: ElevatedButton(
              onPressed: () => _startFight(enemy['slug'], enemy['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('АТАКОВАТЬ', style: TextStyle(fontSize: 12)),
            ),
          ),
        );
      },
    );
  }
}