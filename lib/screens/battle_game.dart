import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class BattleGame extends FlameGame {
  final String playerClass; 
  final String enemySlug;

  BattleGame({required this.playerClass, required this.enemySlug});

  // ВОТ ТАК ПРАВИЛЬНО ЗАДАЕТСЯ ПРОЗРАЧНЫЙ ФОН В НОВЫХ ВЕРСИЯХ FLAME
  @override
  Color backgroundColor() => Colors.transparent;

  late SpriteAnimationComponent hero;
  late SpriteComponent enemy;
  
  // ... (дальше идет твой код onLoad и т.д.)
  
  bool _isAttacking = false;
  late SpriteAnimation idleAnim;
  late SpriteAnimation attackAnim;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. ОПРЕДЕЛЯЕМ КЛАСС
    String idlePath = 'characters/hero_idle.png'; // По умолчанию Воин (Рыцарь)
    String attackPath = 'characters/hero_attack.png';
    String cls = playerClass.toLowerCase();

    if (cls.contains('лучник') || cls.contains('archer')) {
      idlePath = 'characters/hero_archer_idle.png';
      attackPath = 'characters/hero_archer_attack.png';
    } else if (cls.contains('копейщик') || cls.contains('копьеносец') || cls.contains('spearman')) {
      idlePath = 'characters/hero_spearman_idle.png';
      attackPath = 'characters/hero_spearman_attack.png';
    } else if (cls.contains('жнец') || cls.contains('reaper')) {
      idlePath = 'characters/hero_reaper_idle.png';
      attackPath = 'characters/hero_reaper_attack.png';
    } else if (cls.contains('варвар') || cls.contains('barbarian')) {
      idlePath = 'characters/hero_barbarian_idle.png';
      attackPath = 'characters/hero_barbarian_attack.png';
    }

    // 2. ЗАГРУЖАЕМ ГЕРОЯ
    final heroIdleImage = await images.load(idlePath);
    final heroAttackImage = await images.load(attackPath);

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

    // 3. ОПРЕДЕЛЯЕМ ВРАГА (ДИНАМИЧЕСКИ)
    // По умолчанию ставим волка
       // 3. ОПРЕДЕЛЯЕМ ВРАГА (по слагу из базы)
    String mobPath = 'characters/enemies/hungry_wolf.png'; // По умолчанию
    bool shouldFlip = false; 

    // Настраиваем картинку и разворот в зависимости от слага
    if (enemySlug.contains('forest_lord')) {
      mobPath = 'characters/enemies/forest_lord.png';
      shouldFlip = true; // Босс разворачивается
    } else if (enemySlug.contains('archer') || enemySlug.contains('лучник')) {
      mobPath = 'characters/enemies/blood_archer.png';
      // shouldFlip = true;  <--- МЫ ЭТО ЗАКОММЕНТИРОВАЛИ (убрали разворот)
    } else if (enemySlug.contains('alpha_wolf')) {
      mobPath = 'characters/enemies/alpha_wolf.png';
    } else if (enemySlug.contains('forest_wolf')) {
      mobPath = 'characters/enemies/forest_wolf.png';
    } else if (enemySlug.contains('mad_bear')) {
      mobPath = 'characters/enemies/mad_bear.png';
    } else if (enemySlug.contains('bear')) {
      mobPath = 'characters/enemies/brown_bear.png';
    } else if (enemySlug.contains('poison_spider')) {
      mobPath = 'characters/enemies/poison_spider.png';
    } else if (enemySlug.contains('spider')) {
      mobPath = 'characters/enemies/giant_spider.png';
    }

    final mobImage = await images.load(mobPath);

    // 4. РАЗМЕЩЕНИЕ
    hero = SpriteAnimationComponent(
      animation: idleAnim,
      size: Vector2(150, 150), 
      position: Vector2(40, size.y - -30), 
      anchor: Anchor.bottomLeft, 
    );

    // Враг (справа)
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

  // Анимация удара
  void heroAttack() async {
    if (_isAttacking) return;
    _isAttacking = true;
    hero.animation = attackAnim;
    int attackFramesCount = attackAnim.frames.length;
    await Future.delayed(Duration(milliseconds: (attackFramesCount * 100)));
    hero.animation = idleAnim;
    _isAttacking = false;
  }

  // Реакция врага на удар
  void enemyHit() {
    enemy.scale = Vector2(1.1, 1.1);
    Future.delayed(const Duration(milliseconds: 150), () {
      enemy.scale = Vector2(1.0, 1.0);
    });
  }

  // Смерть врага
  void enemyDie() {
    enemy.opacity = 0.0; 
  }
}