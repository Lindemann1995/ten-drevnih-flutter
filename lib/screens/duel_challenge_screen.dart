import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'duel_screen.dart';

class DuelChallengeScreen extends StatefulWidget {
  const DuelChallengeScreen({super.key});

  @override
  State<DuelChallengeScreen> createState() => _DuelChallengeScreenState();
}

class _DuelChallengeScreenState extends State<DuelChallengeScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _challenge() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() => _isLoading = true);
    final result = await ApiClient.challengeDuel(username);
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вызов отправлен!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ВЫЗОВ НА ДУЭЛЬ', style: TextStyle(color: Color(0xFFD4AF37), letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.sports_kabaddi, size: 80, color: Color(0xFFD4AF37)),
            const SizedBox(height: 20),
            const Text(
              'Введи ник игрока, которого хочешь вызвать на честный бой.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Ник противника',
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _challenge,
                      child: const Text('ВЫЗВАТЬ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}