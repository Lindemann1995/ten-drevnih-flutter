import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../utils/asset_paths.dart';
import '../utils/game_constants.dart';

class BattleGame extends FlameGame {
  final String playerClass;
  final String enemySlug;
  final String enemyImagePath;
  final String bgImagePath;
  final bool shouldFlip;

  BattleGame({
    required this.playerClass,
    required this.enemySlug,
    this.enemyImagePath = '',
    this.bgImagePath = '',
    this.shouldFlip = false,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  late SpriteAnimationComponent hero;
  late SpriteComponent enemy;

  bool _isAttacking = false;
  late SpriteAnimation idleAnim;
  late SpriteAnimation attackAnim;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. ГЕРОЙ
    String idleRelPath = 'characters/hero_idle.png';
    String attackRelPath = 'characters/hero_attack.png';
    String cls = playerClass.toLowerCase();

    if (cls.contains('лучник') || cls.contains('archer')) {
      idleRelPath = 'characters/hero_archer_idle.png';
      attackRelPath = 'characters/hero_archer_attack.png';
    } else if (cls.contains('копейщик') ||
        cls.contains('копьеносец') ||
        cls.contains('spearman')) {
      idleRelPath = 'characters/hero_spearman_idle.png';
      attackRelPath = 'characters/hero_spearman_attack.png';
    } else if (cls.contains('жнец') || cls.contains('reaper')) {
      idleRelPath = 'characters/hero_reaper_idle.png';
      attackRelPath = 'characters/hero_reaper_attack.png';
    } else if (cls.contains('варвар') || cls.contains('barbarian')) {
      idleRelPath = 'characters/hero_barbarian_idle.png';
      attackRelPath = 'characters/hero_barbarian_attack.png';
    }

    final heroIdleImage = await images.load(AssetPaths.forFlame(idleRelPath));
    final heroAttackImage =
        await images.load(AssetPaths.forFlame(attackRelPath));

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

    // 2. ВРАГ — с фоллбэком на случай битого пути
    final mobImage = await _loadEnemySprite(enemyImagePath);

    // 3. РАЗМЕЩЕНИЕ
    hero = SpriteAnimationComponent(
      animation: idleAnim,
      size: Vector2(150, 150),
      position: Vector2(40, size.y - -30),
      anchor: Anchor.bottomLeft,
    );

    // Логика отражения зависит ТОЛЬКО от галочки в админке (shouldFlip)
    enemy = SpriteComponent(
      sprite: Sprite(mobImage),
      size: Vector2(120, 120),
      position: Vector2(size.x - 40, size.y - -10),
      anchor: shouldFlip ? Anchor.bottomLeft : Anchor.bottomRight,
    );

    if (shouldFlip) {
      enemy.scale.x = -1;
    }

    add(hero);
    add(enemy);
  }

  /// Безопасная загрузка спрайта врага с фоллбэком на волка.
  Future<dynamic> _loadEnemySprite(String rawPath) async {
    final cleanPath = rawPath.isEmpty
        ? GameConstants.fallbackEnemySprite
        : AssetPaths.forFlame(rawPath);

    try {
      return await images.load(cleanPath);
    } catch (e) {
      debugPrint('⚠️ Enemy sprite not found: "$cleanPath" — using fallback wolf');
      try {
        return await images.load(GameConstants.fallbackEnemySprite);
      } catch (e2) {
        debugPrint('❌ Fallback sprite also failed: $e2');
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
    // Сохраняем знак scale.x, чтобы не сбросить отражение (shouldFlip)
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