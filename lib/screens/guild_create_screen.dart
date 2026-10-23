import 'package:flutter/material.dart';
import '../services/api_client.dart';

class GuildCreateScreen extends StatefulWidget {
  const GuildCreateScreen({super.key});

  @override
  State<GuildCreateScreen> createState() => _GuildCreateScreenState();
}

class _GuildCreateScreenState extends State<GuildCreateScreen> {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isLoading = false;

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final tag = _tagController.text.trim().toUpperCase();

    if (name.isEmpty || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заполни название и тег')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Вызываем метод из ApiClient
    final result = await ApiClient.createGuild(name, tag);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Гильдия успешно создана!'), 
          backgroundColor: Colors.green
        ));
        Navigator.pop(context, true); // Возвращаем true на предыдущий экран
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error']), // Покажет ошибку (нет свитка, мало золота и т.д.)
          backgroundColor: Colors.redAccent
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ОСНОВАНИЕ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, letterSpacing: 2)),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A0A),
                border: Border.all(color: const Color(0xFF8B0000)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Требования для создания:\n'
                '• Уровень персонажа: 8+\n'
                '• Стоимость: 20 000 золота\n'
                '• Наличие «Свитка основания»',
                style: TextStyle(color: Colors.white54, height: 1.5, fontSize: 13),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              maxLength: 20,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Название гильдии',
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                counterStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tagController,
              maxLength: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Тег (для чата)',
                labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3A3A3A))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                counterStyle: TextStyle(color: Colors.white38),
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
                        foregroundColor: const Color(0xFFD4AF37),
                        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _create,
                      child: const Text('СОЗДАТЬ ГИЛЬДИЮ', style: TextStyle(fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}