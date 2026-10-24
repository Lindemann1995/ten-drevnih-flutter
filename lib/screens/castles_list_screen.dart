import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'siege_screen.dart';

class CastlesListScreen extends StatefulWidget {
  const CastlesListScreen({super.key});

  @override
  State<CastlesListScreen> createState() => _CastlesListScreenState();
}

class _CastlesListScreenState extends State<CastlesListScreen> {
  List<dynamic> _castles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCastles();
  }

  Future<void> _loadCastles() async {
    final result = await ApiClient.getCastles();
    if (result['success']) {
      setState(() {
        _castles = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error']), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _startSiege(int castleId, String castleName) async {
    final result = await ApiClient.startSiege(castleId);
    if (mounted) {
      if (result['success']) {
        final siegeId = result['data']['siege_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SiegeScreen(siegeId: siegeId, castleName: castleName),
          ),
        );
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
        title: const Text('ЗАМКИ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _castles.length,
              itemBuilder: (context, index) {
                final c = _castles[index];
                final isFree = c['owner'] == null;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A0A),
                    border: Border.all(color: isFree ? const Color(0xFF3A3A3A) : const Color(0xFFD4AF37)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Text('🏰', style: TextStyle(fontSize: 32)),
                    title: Text(c['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isFree ? 'Свободен' : 'Владелец: [${c['owner']}]',
                      style: TextStyle(color: isFree ? Colors.white54 : const Color(0xFFD4AF37)),
                    ),
                    trailing: isFree
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B0000)),
                            onPressed: () => _startSiege(c['id'], c['name']),
                            child: const Text('АТАКОВАТЬ', style: TextStyle(fontSize: 12)),
                          )
                        : const Icon(Icons.lock, color: Colors.white24),
                  ),
                );
              },
            ),
    );
  }
}