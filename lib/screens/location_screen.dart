import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'combat_screen.dart';

class LocationScreen extends StatefulWidget {
  final String locationSlug;
  final String locationName;
  final String locationDescription;
  final int minLevel;

  const LocationScreen({
    super.key,
    required this.locationSlug,
    required this.locationName,
    required this.locationDescription,
    required this.minLevel,
  });

  @override
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _isLoading = false;

  Future<void> _hunt() async {
    setState(() => _isLoading = true);

    final result = await ApiClient.huntInLocation(widget.locationSlug);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final data = result['data'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombatScreen(
            enemySlug: data['enemy_slug'],
            enemyName: data['enemy_name'],
          ),
        ),
      );
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  Future<void> _doRest() async {
    setState(() => _isLoading = true);

    final result = await ApiClient.rest();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showMessage(result['data']['message'] ?? 'Отдых удался');
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  Future<void> _fightBoss() async {
    setState(() => _isLoading = true);

    final result = await ApiClient.bossInLocation(widget.locationSlug);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final data = result['data'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CombatScreen(
            enemySlug: data['enemy_slug'],
            enemyName: data['enemy_name'],
          ),
        ),
      );
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFF8B0000)),
    );
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                Text(
                  widget.locationName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.locationDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 60),

                _BigButton(
                  text: '🎯 ОХОТИТЬСЯ',
                  subtitle: 'Случайный враг',
                  onPressed: _isLoading ? null : _hunt,
                ),
                const SizedBox(height: 16),
                _BigButton(
                  text: '👑 БОСС',
                  subtitle: 'Лесной повелитель (ур. 10)',
                  onPressed: _isLoading ? null : _fightBoss,
                  isSpecial: true,
                ),
                const SizedBox(height: 16),
                _BigButton(
                  text: '🏕 ОТДОХНУТЬ',
                  subtitle: 'Восстановить HP',
                  onPressed: _isLoading ? null : _doRest,
                ),
                const SizedBox(height: 16),
                _BigButton(
                  text: '⬅ НАЗАД',
                  subtitle: 'На карту',
                  onPressed: () => Navigator.pop(context),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool isSpecial;

  const _BigButton({
    required this.text,
    required this.subtitle,
    required this.onPressed,
    this.isSpecial = false,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final borderColor = isSpecial ? const Color(0xFFD4AF37) : const Color(0xFF8B0000);

    return SizedBox(
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A0A0A),
          foregroundColor: isSpecial ? const Color(0xFFD4AF37) : Colors.white70,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}