import 'package:flutter/material.dart';
import '../services/api_client.dart';
import 'widgets/typewriter_text.dart';

class SceneScreen extends StatefulWidget {
  const SceneScreen({super.key});

  @override
  State<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends State<SceneScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _scene;
  bool _isChoosing = false;
  bool _textComplete = false;

  @override
  void initState() {
    super.initState();
    _loadScene();
  }

  Future<void> _loadScene() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _textComplete = false;
    });

    final result = await ApiClient.getCurrentScene();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _scene = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['error'] ?? 'Ошибка';
        _isLoading = false;
      });
    }
  }

  Future<void> _makeChoice(int choiceId) async {
    setState(() => _isChoosing = true);

    final result = await ApiClient.makeChoice(choiceId);

    if (!mounted) return;
    setState(() => _isChoosing = false);

    if (result['success'] == true) {
      final next = result['data']['next_scene'];
      if (next != null) {
        setState(() {
          _scene = next;
          _textComplete = false;
        });
      } else {
        _showMessage('Конец обучения. Скоро — продолжение!');
      }
    } else {
      _showMessage(result['error'] ?? 'Ошибка');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8B0000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                  : _buildScene(),
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
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadScene,
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

  Widget _buildScene() {
    if (_scene == null) {
      return const Center(
        child: Text(
          'Сцена не загружена',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final scene = _scene!;
    final title = scene['title'] ?? 'Без названия';
    final text = scene['text'] ?? '';
    final location = scene['location'] ?? '';
    final choices = scene['choices'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Заголовок сцены
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF3A1A1A), width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 2,
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Текст сцены
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: TypewriterText(
              key: ValueKey(title),
              text: text,
              speed: const Duration(milliseconds: 25),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
              onComplete: () {
                if (mounted) {
                  setState(() => _textComplete = true);
                }
              },
            ),
          ),
        ),

        // Нижний блок: кнопки выбора ИЛИ кнопка пропустить
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: _textComplete && choices.isNotEmpty
              ? _buildChoices(choices)
              : (_textComplete
                  ? const SizedBox(height: 1)
                  : _buildSkipButton(text)),
        ),
      ],
    );
  }

  Widget _buildChoices(List<dynamic> choices) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: choices.map<Widget>((choice) {
        final id = choice['id'] as int;
        final choiceText = choice['text'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isChoosing ? null : () => _makeChoice(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A0A0A),
                foregroundColor: const Color(0xFFD4AF37),
                side: const BorderSide(color: Color(0xFF8B0000), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                choiceText,
                style: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkipButton(String text) {
    if (text.isEmpty) {
      return const SizedBox(height: 1);
    }
    return TextButton(
      onPressed: () {
        setState(() => _textComplete = true);
      },
      child: const Text(
        'ПРОПУСТИТЬ',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }
}