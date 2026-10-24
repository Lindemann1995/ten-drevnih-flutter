/// Централизованная работа с путями ассетов.
///
/// Проблема: Flame's images.load() сам добавляет префикс assets/images/,
/// а Flutter's AssetImage — требует полный путь. Дублирование путей
/// приводит к ошибке "assets/images/assets/images/...".

class AssetPaths {
  static const String _prefix = 'assets/images/';

  /// Для Flame: images.load() сам добавит префикс.
  /// Пример: 'assets/images/characters/hero.png' → 'characters/hero.png'
  /// Также очищает двойные префиксы из админки (assets/images/assets/images/...)
  static String forFlame(String serverPath) {
    if (serverPath.isEmpty) return '';
    return serverPath
        .replaceAll('assets/images/assets/images/', '')
        .replaceAll('assets/images/', '')
        .replaceAll('assets/', '');
  }

  /// Для Flutter AssetImage: нужен полный путь.
  /// Пример: 'characters/hero.png' → 'assets/images/characters/hero.png'
  static String forFlutter(String serverPath) {
    if (serverPath.isEmpty) return '$_prefix';
    final clean = serverPath
        .replaceAll('assets/images/assets/images/', '')
        .replaceAll('assets/images/', '')
        .replaceAll('assets/', '');
    return '$_prefix$clean';
  }

  /// 🆕 Универсальный путь для предметов.
  /// Если в админке указан image_path — берем его.
  /// Если нет — ищем по старому слагу.
  static String forItem(String? imagePath, String? slug) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return forFlutter(imagePath);
    }
    return '${_prefix}items/$slug.png';
  }
}