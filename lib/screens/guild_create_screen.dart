import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'dart:math' as math;

class GuildCreateScreen extends StatefulWidget {
  const GuildCreateScreen({super.key});

  @override
  State<GuildCreateScreen> createState() => _GuildCreateScreenState();
}

class _GuildCreateScreenState extends State<GuildCreateScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Медленное переливание фона
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Пульсация щита
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final tag = _tagController.text.trim().toUpperCase();

    if (name.isEmpty || tag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполни название и тег'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await ApiClient.createGuild(name, tag);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Гильдия успешно основана!'), 
          backgroundColor: Colors.green
        ));
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error']), 
          backgroundColor: Colors.redAccent
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // 🆕 Анимированный фон
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      math.sin(_bgController.value * math.pi * 2) * 0.5,
                      math.cos(_bgController.value * math.pi * 2) * 0.5,
                    ),
                    radius: 1.5,
                    colors: const [
                      Color(0xFF2A0A0A),
                      Color(0xFF050505),
                    ],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Кастомный AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'ОСНОВАНИЕ',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // 🆕 Пульсирующий герб
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + (_pulseController.value * 0.05);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(0.3 + (_pulseController.value * 0.2)),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF1A0A0A),
                                  child: const Icon(Icons.shield, size: 60, color: Color(0xFFD4AF37)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),

                        // 🆕 Красивая карточка требований
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4), width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ТРЕБОВАНИЯ', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _buildRequirementRow(Icons.military_tech, 'Уровень персонажа: 8+', Colors.blueAccent),
                              _buildRequirementRow(Icons.monetization_on, 'Стоимость: 20 000 золота', Colors.amber),
                              _buildRequirementRow(Icons.assignment, 'Наличие «Свитка основания»', Colors.greenAccent),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),

                        // 🆕 Поля ввода
                        TextField(
                          controller: _nameController,
                          maxLength: 20,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Название гильдии',
                            labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.5),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            counterStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.edit, color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _tagController,
                          maxLength: 5,
                          style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2),
                          decoration: InputDecoration(
                            labelText: 'Тег (для чата)',
                            labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.5),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            counterStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.tag, color: Colors.white54),
                          ),
                        ),
                        
                        const SizedBox(height: 40),

                        // 🆕 Кнопка с градиентом и свечением
                        _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                            : SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _create,
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B0000), Color(0xFFD4AF37)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
                                      ],
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'СОЗДАТЬ ГИЛЬДИЮ',
                                        style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Вспомогательный виджет для строк требований
  Widget _buildRequirementRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}