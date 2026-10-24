import 'dart:async';
import 'package:flutter/material.dart';

class CastleCooldownTimer extends StatefulWidget {
  final String cooldownUntil;

  const CastleCooldownTimer({super.key, required this.cooldownUntil});

  @override
  State<CastleCooldownTimer> createState() => _CastleCooldownTimerState();
}

class _CastleCooldownTimerState extends State<CastleCooldownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final cooldownUntil = DateTime.tryParse(widget.cooldownUntil)?.toLocal();
    if (cooldownUntil == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    if (cooldownUntil.isAfter(now)) {
      setState(() => _remaining = cooldownUntil.difference(now));
    } else {
      setState(() => _remaining = Duration.zero);
      _timer?.cancel(); // Если время вышло — останавливаем таймер
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) return const SizedBox.shrink();

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '🛡 ${hours}ч ${minutes}м ${seconds}с',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}