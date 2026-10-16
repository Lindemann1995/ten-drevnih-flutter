import 'package:flutter/material.dart';
import 'location_screen.dart';
import 'profile_screen.dart';
import 'trade_world_screen.dart';
import 'scene_screen.dart';
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  final List<MapLocation> _locations = [
    MapLocation(
      slug: 'world_ancient',
      name: 'Мир Древних',
      description: 'Руины храма, где ты очнулся. Здесь началось твоё путешествие.',
      x: 0.22,
      y: 0.18,
      icon: Icons.auto_awesome,
      isAvailable: true,
      isStory: true,
      recommendedLevel: '1+',
    ),
    MapLocation(
      slug: 'kairos_village',
      name: 'Деревня Кайроса',
      description: 'Обиталище выживших. Здесь живёт старик Кайрос.',
      x: 0.38,
      y: 0.45,
      icon: Icons.home,
      isAvailable: false,
      recommendedLevel: 'Сюжет',
    ),
    MapLocation(
      slug: 'dark_forest',
      name: 'Тёмный лес',
      description: 'Мрачный лес, полный волков, пауков и медведей.',
      x: 0.52,
      y: 0.38,
      icon: Icons.forest,
      isAvailable: true,
      isCombat: true,
      recommendedLevel: '2+',
    ),
    MapLocation(
      slug: 'guild_city',
      name: 'Город Гильдий',
      description: 'Три гильдии, три пути. Орден Света, Культ Тени или Свободные.',
      x: 0.75,
      y: 0.30,
      icon: Icons.castle,
      isAvailable: false,
      recommendedLevel: 'Сюжет',
    ),
    MapLocation(
      slug: 'trade_world',
      name: 'Мир Торговли',
      description: 'Оживлённое место, где торговцы предлагают товары.',
      x: 0.72,
      y: 0.60,
      icon: Icons.store,
      isAvailable: true,
      isTrade: true,
      recommendedLevel: '1+',
    ),
    MapLocation(
      slug: 'crypt',
      name: 'Склеп Сердце Дракона',
      description: 'Древнее подземелье. В его глубинах спит Сердце Дракона.',
      x: 0.55,
      y: 0.78,
      icon: Icons.dark_mode,
      isAvailable: false,
      recommendedLevel: 'Сюжет',
    ),
    MapLocation(
      slug: 'dark_tower',
      name: 'Тёмная Башня',
      description: 'Обитель Тени Древних. Здесь решится судьба мира.',
      x: 0.22,
      y: 0.72,
      icon: Icons.temple_buddhist,
      isAvailable: false,
      recommendedLevel: '50+',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onLocationTap(MapLocation loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LocationSheet(
        location: loc,
        onEnter: () {
          Navigator.pop(context);
          _enterLocation(loc);
        },
      ),
    );
  }

  void _enterLocation(MapLocation loc) {
    if (loc.slug == 'world_ancient') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SceneScreen()),
      );
      return;
    }
    if (loc.slug == 'trade_world') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TradeWorldScreen()),
      );
      return;
    }
    if (loc.slug == 'dark_forest') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LocationScreen(
            locationSlug: 'dark_forest',
            locationName: 'Тёмный лес',
            locationDescription:
                'Мрачный лес, полный волков и пауков. Здесь начинается путь охотника.',
            minLevel: 2,
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Локация "${loc.name}" — сюжетная, скоро откроется.'),
        backgroundColor: const Color(0xFF8B0000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF1A0A0A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFFD4AF37)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'КАРТА МИРА',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person,
                          color: Color(0xFFD4AF37)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Карта
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/world_map.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                              color: const Color(0xFF1A0A0A),
                              child: const Center(
                                child: Text(
                                  'Карта не найдена',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                        ..._locations.map((loc) {
                          return Positioned(
                            left: constraints.maxWidth * loc.x - 40,
                            top: constraints.maxHeight * loc.y - 40,
                            child: _LocationMarker(
                              location: loc,
                              pulseController: _pulseController,
                              onTap: () => _onLocationTap(loc),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
              // Подсказка
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Тапни по локации',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapLocation {
  final String slug;
  final String name;
  final String description;
  final double x;
  final double y;
  final IconData icon;
  final bool isAvailable;
  final bool isStory;
  final bool isCombat;
  final bool isTrade;
  final String recommendedLevel;

  MapLocation({
    required this.slug,
    required this.name,
    required this.description,
    required this.x,
    required this.y,
    required this.icon,
    required this.isAvailable,
    required this.recommendedLevel,
    this.isStory = false,
    this.isCombat = false,
    this.isTrade = false,
  });
}

class _LocationMarker extends StatelessWidget {
  final MapLocation location;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _LocationMarker({
    required this.location,
    required this.pulseController,
    required this.onTap,
  });

  Color get _color {
    if (!location.isAvailable) return const Color(0xFF3A3A3A);
    if (location.isStory) return const Color(0xFFD4AF37);
    if (location.isCombat) return const Color(0xFF8B0000);
    if (location.isTrade) return const Color(0xFF4A8B4A);
    return const Color(0xFFD4AF37);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (location.isAvailable)
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  return Container(
                    width: 40 + pulseController.value * 40,
                    height: 40 + pulseController.value * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _color.withValues(
                        alpha: 0.3 * (1 - pulseController.value),
                      ),
                    ),
                  );
                },
              ),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0A0A).withValues(alpha: 0.85),
                border: Border.all(color: _color, width: 2),
                boxShadow: location.isAvailable
                    ? [
                        BoxShadow(
                          color: _color.withValues(alpha: 0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                location.isAvailable ? location.icon : Icons.lock,
                color: _color,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationSheet extends StatelessWidget {
  final MapLocation location;
  final VoidCallback onEnter;

  const _LocationSheet({
    required this.location,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
        ),
        border: Border.all(
          color: location.isAvailable
              ? const Color(0xFFD4AF37)
              : const Color(0xFF3A3A3A),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(
                    color: location.isAvailable
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF3A3A3A),
                    width: 2,
                  ),
                ),
                child: Icon(
                  location.isAvailable ? location.icon : Icons.lock,
                  color: location.isAvailable
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF3A3A3A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Рекомендуемый уровень: ${location.recommendedLevel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            location.description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          if (location.isAvailable)
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onEnter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A0A0A),
                  foregroundColor: const Color(0xFFD4AF37),
                  side: const BorderSide(
                    color: Color(0xFF8B0000),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ВОЙТИ',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(
                  color: const Color(0xFF3A3A3A),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, color: Color(0xFF3A3A3A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'ЗАКРЫТО',
                    style: TextStyle(
                      color: Color(0xFF3A3A3A),
                      fontSize: 14,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}