/// Константы, которые раньше были захардкожены в разных местах.
class GameConstants {
  // Фоллбэк-спрайт врага, если картинка не загрузилась
  static const String fallbackEnemySprite = 'characters/enemies/hungry_wolf.png';

  // Боевые константы (синхронизировать с Django combat.py!)
  static const double critChance = 0.15;
  static const double critMultiplier = 1.5;

  // Тайминги UI
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration attackCooldown = Duration(milliseconds: 600);
}