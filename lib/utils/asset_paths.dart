/// Централизованная работа с путями ассетов.
class AssetPaths {
  static const String _prefix = 'assets/images/';

  /// Для Flame: images.load() сам добавит префикс.
  static String forFlame(String serverPath) {
    if (serverPath.isEmpty) return '';
    return serverPath
        .replaceAll('assets/images/assets/images/', '')
        .replaceAll('assets/images/', '')
        .replaceAll('assets/image/', '') // на случай опечатки
        .replaceAll('assets/', '');
  }

  /// Для Flutter AssetImage: нужен полный путь.
  static String forFlutter(String serverPath) {
    if (serverPath.isEmpty) return '$_prefix';
    final clean = serverPath
        .replaceAll('assets/images/assets/images/', '')
        .replaceAll('assets/images/', '')
        .replaceAll('assets/image/', '') // на случай опечатки
        .replaceAll('assets/', '');
    return '$_prefix$clean';
  }

  /// 🆕 Универсальный путь для предметов.
  static String forItem(String? imagePath, String? slug) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return forFlutter(imagePath);
    }
    return '${_prefix}items/$slug.png';
  }
}