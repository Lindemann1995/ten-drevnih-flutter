import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BattleGame extends FlameGame {
  final String playerClass;
  final String enemySlug;
  final String enemyImagePath;
  final String bgImagePath;
  final bool shouldFlip;
  final double enemyScale;

  BattleGame({
    required this.playerClass,
    required this.enemySlug,
    this.enemyImagePath = '',
    this.bgImagePath = '',
    this.shouldFlip = false,
    this.enemyScale = 1.0,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  late SpriteComponent background;
  late SpriteAnimationComponent hero;
  late SpriteComponent enemy;

  bool _isAttacking = false;
  late SpriteAnimation idleAnim;
  late SpriteAnimation attackAnim;

    @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 0. ЗАГРУЗКА ФОНА
    if (bgImagePath.isNotEmpty) {
      try {
        String cleanBgPath = bgImagePath
            .replaceAll('assets/images/assets/images/', '')
            .replaceAll('assets/images/', '')
            .replaceAll('assets/', '');
        String finalBgPath = 'assets/images/$cleanBgPath';
        
        debugPrint('🔄 Пытаемся загрузить фон: $finalBgPath');
        
        final bgImage = await _loadAssetImage(finalBgPath);
        
        // Используем size из камеры (актуальный размер экрана)
        background = SpriteComponent(
          sprite: Sprite(bgImage),
          size: Vector2(camera.viewport.virtualSize.x, camera.viewport.virtualSize.y),
          position: Vector2.zero(),
          priority: -1, // Самый нижний слой
        );
        add(background);
        debugPrint('✅ Фон успешно загружен');
      } catch (e) {
        debugPrint('❌ Не удалось загрузить фон: $e');
      }
    } else {
      debugPrint('⚠️ bgImagePath пустой, фон не загружается');
    }

    // 1. ГЕРОЙ
    const String charFolder = 'assets/images/characters/';

    String idlePath = '${charFolder}hero_idle.png';
    String attackPath = '${charFolder}hero_attack.png';
    String cls = playerClass.toLowerCase();

    if (cls.contains('лучник') || cls.contains('archer')) {
      idlePath = '${charFolder}hero_archer_idle.png';
      attackPath = '${charFolder}hero_archer_attack.png';
    } else if (cls.contains('копейщик') ||
        cls.contains('копьеносец') ||
        cls.contains('spearman')) {
      idlePath = '${charFolder}hero_spearman_idle.png';
      attackPath = '${charFolder}hero_spearman_attack.png';
    } else if (cls.contains('жнец') || cls.contains('reaper')) {
      idlePath = '${charFolder}hero_reaper_idle.png';
      attackPath = '${charFolder}hero_reaper_attack.png';
    } else if (cls.contains('варвар') || cls.contains('barbarian')) {
      idlePath = '${charFolder}hero_barbarian_idle.png';
      attackPath = '${charFolder}hero_barbarian_attack.png';
    }

    // ВОТ ЗДЕСЬ МЫ ИСПОЛЬЗУЕМ rootBundle (без AssetPaths)
    final heroIdleImage = await _loadAssetImage(idlePath);
    final heroAttackImage = await _loadAssetImage(attackPath);

    double frameSize = heroIdleImage.height.toDouble();
    int idleFramesCount = (heroIdleImage.width / frameSize).round();
    int attackFramesCount = (heroAttackImage.width / frameSize).round();

    idleAnim = SpriteAnimation.fromFrameData(
      heroIdleImage,
      SpriteAnimationData.sequenced(
        amount: idleFramesCount,
        stepTime: 0.15,
        textureSize: Vector2(frameSize, frameSize),
      ),
    );

    attackAnim = SpriteAnimation.fromFrameData(
      heroAttackImage,
      SpriteAnimationData.sequenced(
        amount: attackFramesCount,
        stepTime: 0.1,
        textureSize: Vector2(frameSize, frameSize),
      ),
    );
    attackAnim.loop = false;

    // 2. ВРАГ
    final mobImage = await _loadEnemySprite(enemyImagePath);

    // 3. РАЗМЕЩЕНИЕ
    hero = SpriteAnimationComponent(
      animation: idleAnim,
      size: Vector2(150, 150),
      position: Vector2(40, size.y - 20),
      anchor: Anchor.bottomLeft,
    );

    double baseEnemySize = 120.0;
    double finalEnemySize = baseEnemySize * enemyScale;

    enemy = SpriteComponent(
      sprite: Sprite(mobImage),
      size: Vector2(finalEnemySize, finalEnemySize),
      position: Vector2(size.x - 40, size.y - 20),
      anchor: shouldFlip ? Anchor.bottomLeft : Anchor.bottomRight,
    );

    if (shouldFlip) {
      enemy.scale.x = -1;
    }

    add(hero);
    add(enemy);
  }

  Future<ui.Image> _loadAssetImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки ассета: $path');
      rethrow;
    }
  }

  Future<ui.Image> _loadEnemySprite(String rawPath) async {
    if (rawPath.isEmpty) {
      return await _loadAssetImage('assets/images/characters/wolf.png');
    }

    String cleanPath = rawPath
        .replaceAll('assets/images/assets/images/', '')
        .replaceAll('assets/images/', '')
        .replaceAll('assets/', '');
    
    String finalPath = 'assets/images/$cleanPath';

    try {
      return await _loadAssetImage(finalPath);
    } catch (e) {
      debugPrint('⚠️ Спрайт врага не найден: "$finalPath" — используем волка');
      try {
        return await _loadAssetImage('assets/images/characters/wolf.png'); 
      } catch (e2) {
        debugPrint('❌ Дефолтный спрайт тоже не найден: $e2');
        rethrow;
      }
    }
  }

  void heroAttack() async {
    if (_isAttacking) return;
    _isAttacking = true;
    hero.animation = attackAnim;
    int attackFramesCount = attackAnim.frames.length;
    await Future.delayed(Duration(milliseconds: (attackFramesCount * 100)));
    hero.animation = idleAnim;
    _isAttacking = false;
  }

  void enemyHit() {
    final double signX = shouldFlip ? -1.0 : 1.0;
    enemy.scale = Vector2(1.1 * signX, 1.1);
    Future.delayed(const Duration(milliseconds: 150), () {
      enemy.scale = Vector2(1.0 * signX, 1.0);
    });
  }

  void enemyDie() {
    enemy.opacity = 0.0;
  }
}