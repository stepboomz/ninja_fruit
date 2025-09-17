import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/image_composition.dart' as composition;
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/utils.dart';
import '../models/fruit_model.dart';
import '../routes/game_page.dart';

class FruitComponent extends SpriteComponent {
  Vector2 velocity;
  final Vector2 pageSize;
  final double acceleration;
  final FruitModel fruit;
  final composition.Image image;
  late Vector2 _initPosition;
  bool canDragOnShape = false;
  GamePage parentComponent;
  bool divided;
  final bool fallingFromTop;
  double _sparkleTimer = 0;

  FruitComponent(
    this.parentComponent,
    Vector2 p, {
    Vector2? size,
    required this.velocity,
    required this.acceleration,
    required this.pageSize,
    required this.image,
    required this.fruit,
    double? angle,
    Anchor? anchor,
    this.divided = false,
    this.fallingFromTop = false,
  }) : super(
          sprite: Sprite(image),
          position: p,
          size: size,
          anchor: anchor ?? Anchor.center,
          angle: angle,
        ) {
    _initPosition = p;
    canDragOnShape = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_initPosition.distanceTo(position) > 60) {
      canDragOnShape = true;
    }
    angle += .5 * dt;
    angle %= 2 * pi;

    _sparkleTimer += dt;

    if (fallingFromTop) {
      // Downward motion from top of screen
      final double g = AppConfig.gravity.abs() * AppConfig.fallSpeedMultiplier;
      position += Vector2(velocity.x * dt, velocity.y * dt + 0.5 * g * dt * dt);
      velocity.y += g * dt;
    } else {
      position += Vector2(
          velocity.x, -(velocity.y * dt - .5 * AppConfig.gravity * dt * dt));
      velocity.y += (AppConfig.acceleration + AppConfig.gravity) * dt;
    }

    if ((position.y - AppConfig.objSize) > pageSize.y) {
      removeFromParent();

      if (!divided && !fruit.isBomb) {
        parentComponent.addMistake();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw aura effect for fruits (not bombs)
    if (!fruit.isBomb && fallingFromTop) {
      _drawAura(canvas);
    }

    // Draw the fruit sprite
    super.render(canvas);
  }

  void _drawAura(Canvas canvas) {
    final center = size / 2;
    final time = _sparkleTimer;

    // Create pulsing aura effect
    final auraRadius = (size.x / 2) + 8 + (sin(time * 4) * 3);
    final auraOpacity = (0.3 + sin(time * 3) * 0.2).clamp(0.1, 0.5);

    // Choose aura color based on fruit type
    Color auraColor;
    if (fruit.image.contains('apple')) {
      auraColor = Colors.red;
    } else if (fruit.image.contains('banana')) {
      auraColor = Colors.yellow;
    } else if (fruit.image.contains('orange')) {
      auraColor = Colors.orange;
    } else if (fruit.image.contains('kiwi')) {
      auraColor = Colors.green;
    } else if (fruit.image.contains('peach')) {
      auraColor = Colors.pink;
    } else if (fruit.image.contains('pineapple')) {
      auraColor = Colors.amber;
    } else {
      auraColor = Colors.white;
    }

    // Draw outer glow
    final outerPaint = Paint()
      ..color = auraColor.withValues(alpha: auraOpacity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.toOffset(), auraRadius, outerPaint);

    // Draw inner glow
    final innerPaint = Paint()
      ..color = auraColor.withValues(alpha: auraOpacity * 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.toOffset(), auraRadius * 0.7, innerPaint);

    // Draw sparkle particles around the fruit
    final sparkleCount = 8;
    for (int i = 0; i < sparkleCount; i++) {
      final sparkleAngle = (2 * pi * i / sparkleCount) + time * 2;
      final sparkleDistance = auraRadius * 0.8 + sin(time * 5 + i) * 5;
      final sparkleX = center.x + cos(sparkleAngle) * sparkleDistance;
      final sparkleY = center.y + sin(sparkleAngle) * sparkleDistance;

      final sparkleSize = 1.5 + sin(time * 6 + i * 0.5) * 0.8;
      final sparklePaint = Paint()..color = Colors.white.withValues(alpha: 0.8);

      canvas.drawCircle(Offset(sparkleX, sparkleY), sparkleSize, sparklePaint);
    }
  }

  void touchAtPoint(Vector2 vector2) {
    if (divided && !canDragOnShape) {
      return;
    }
    if (fruit.isBomb) {
      parentComponent.addMistake();
      removeFromParent();
      return;
    }

    // Check if this is a falling fruit (from top)
    if (fallingFromTop) {
      // Falling fruits just explode into ice, don't get sliced
      _createIceShatterEffect();
      String fruitName = fruit.image.replaceAll('.png', '');
      parentComponent.addScore(fruitName);
      removeFromParent();
      return;
    }

    // Add ice shatter effect for regular fruits (thrown up)
    _createIceShatterEffect();

    // angleOfTouchPoint
    final a = Utils.getAngleOfTouchPont(
        center: position, initAngle: angle, touch: vector2);

    if (a < 45 || (a > 135 && a < 225) || a > 315) {
      final dividedImage1 = composition.ImageComposition()
            ..add(image, Vector2(0, 0),
                source: Rect.fromLTWH(
                    0, 0, image.width.toDouble(), image.height / 2)),
          dividedImage2 = composition.ImageComposition()
            ..add(image, Vector2(0, 0),
                source: Rect.fromLTWH(0, image.height / 2,
                    image.width.toDouble(), image.height / 2));

      parentComponent.addAll([
        FruitComponent(
          parentComponent,
          center - Vector2(size.x / 2 * cos(angle), size.x / 2 * sin(angle)),
          fruit: fruit,
          image: dividedImage2.composeSync(),
          acceleration: acceleration,
          velocity: Vector2(velocity.x - 2, velocity.y),
          pageSize: pageSize,
          divided: true,
          size: Vector2(size.x, size.y / 2),
          angle: angle,
          anchor: Anchor.topLeft,
        ),
        FruitComponent(
          parentComponent,
          center +
              Vector2(size.x / 4 * cos(angle + 3 * pi / 2),
                  size.x / 4 * sin(angle + 3 * pi / 2)),
          size: Vector2(size.x, size.y / 2),
          angle: angle,
          anchor: Anchor.center,
          fruit: fruit,
          image: dividedImage1.composeSync(),
          acceleration: acceleration,
          velocity: Vector2(velocity.x + 2, velocity.y),
          pageSize: pageSize,
          divided: true,
        )
      ]);
    } else {
      // split image
      final dividedImage1 = composition.ImageComposition()
            ..add(image, Vector2(0, 0),
                source: Rect.fromLTWH(
                    0, 0, image.width / 2, image.height.toDouble())),
          dividedImage2 = composition.ImageComposition()
            ..add(image, Vector2(0, 0),
                source: Rect.fromLTWH(image.width / 2, 0, image.width / 2,
                    image.height.toDouble()));

      parentComponent.addAll([
        FruitComponent(
          parentComponent,
          center - Vector2(size.x / 4 * cos(angle), size.x / 4 * sin(angle)),
          size: Vector2(size.x / 2, size.y),
          angle: angle,
          anchor: Anchor.center,
          fruit: fruit,
          image: dividedImage1.composeSync(),
          acceleration: acceleration,
          velocity: Vector2(velocity.x - 2, velocity.y),
          pageSize: pageSize,
          divided: true,
        ),
        FruitComponent(
          parentComponent,
          center +
              Vector2(size.x / 2 * cos(angle + 3 * pi / 2),
                  size.x / 2 * sin(angle + 3 * pi / 2)),
          size: Vector2(size.x / 2, size.y),
          angle: angle,
          anchor: Anchor.topLeft,
          fruit: fruit,
          image: dividedImage2.composeSync(),
          acceleration: acceleration,
          velocity: Vector2(velocity.x + 2, velocity.y),
          pageSize: pageSize,
          divided: true,
        )
      ]);
    }

    String fruitName = fruit.image.replaceAll('.png', '');
    parentComponent.addScore(fruitName);
    removeFromParent();
  }

  void _createIceShatterEffect() {
    // Create ice shatter particles for banana and peach only
    final particleCount = 15;
    final centerPos = position;
    final random = Random();

    for (int i = 0; i < particleCount; i++) {
      final angle =
          (2 * pi * i / particleCount) + (random.nextDouble() * 0.8 - 0.4);
      final distance = 15 + random.nextDouble() * 25;
      final particlePos = centerPos +
          Vector2(
            cos(angle) * distance,
            sin(angle) * distance,
          );

      // Create ice shard particle with varied properties
      final iceParticle = IceShardParticle(
        position: particlePos,
        velocity: Vector2(
          cos(angle) * (80 + random.nextDouble() * 120),
          sin(angle) * (80 + random.nextDouble() * 120) -
              60, // More upward bias
        ),
        particleSize: 1.5 + random.nextDouble() * 3.5,
        lifespan: 1.0 + random.nextDouble() * 0.6,
        rotationSpeed: (random.nextDouble() - 0.5) * 10, // Random rotation
      );

      parentComponent.add(iceParticle);
    }

    // Add a central burst effect
    final burstParticle = IceBurstEffect(
      position: centerPos,
      burstSize: size.x * 0.8,
    );
    parentComponent.add(burstParticle);
  }
}

// Ice shard particle component
class IceShardParticle extends PositionComponent {
  Vector2 velocity;
  double particleSize;
  double lifespan;
  double rotationSpeed;
  double _currentLife = 0;
  double _rotation = 0;
  final double gravity = 250;

  IceShardParticle({
    required Vector2 position,
    required this.velocity,
    required this.particleSize,
    required this.lifespan,
    this.rotationSpeed = 0,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);

    // Update position
    position += velocity * dt;

    // Apply gravity and air resistance
    velocity.y += gravity * dt;
    velocity *= 0.98; // Air resistance

    // Update rotation
    _rotation += rotationSpeed * dt;

    // Update life
    _currentLife += dt;

    // Remove when lifespan is over
    if (_currentLife >= lifespan) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate alpha based on remaining life
    final alpha = (1.0 - (_currentLife / lifespan)).clamp(0.0, 1.0);

    canvas.save();
    canvas.rotate(_rotation);

    // Draw ice shard as a crystalline shape
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: alpha * 0.9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw more complex ice crystal shape
    final path = Path();
    path.moveTo(0, -particleSize); // Top
    path.lineTo(particleSize * 0.4, -particleSize * 0.3); // Top right
    path.lineTo(particleSize * 0.8, 0); // Right
    path.lineTo(particleSize * 0.4, particleSize * 0.6); // Bottom right
    path.lineTo(0, particleSize); // Bottom
    path.lineTo(-particleSize * 0.4, particleSize * 0.6); // Bottom left
    path.lineTo(-particleSize * 0.8, 0); // Left
    path.lineTo(-particleSize * 0.4, -particleSize * 0.3); // Top left
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    canvas.restore();
  }
}

// Ice burst effect component
class IceBurstEffect extends PositionComponent {
  double burstSize;
  double _currentLife = 0;
  final double lifespan = 0.3;

  IceBurstEffect({
    required Vector2 position,
    required this.burstSize,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);

    _currentLife += dt;

    if (_currentLife >= lifespan) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _currentLife / lifespan;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final currentSize = burstSize * (0.5 + progress * 1.5);

    // Draw expanding ice burst ring
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset.zero, currentSize, paint);
    canvas.drawCircle(Offset.zero, currentSize * 0.7, innerPaint);

    // Draw radiating lines
    for (int i = 0; i < 8; i++) {
      final angle = (2 * pi * i / 8);
      final startRadius = currentSize * 0.3;
      final endRadius = currentSize * 0.9;

      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.7)
        ..strokeWidth = 1.0;

      canvas.drawLine(
        Offset(cos(angle) * startRadius, sin(angle) * startRadius),
        Offset(cos(angle) * endRadius, sin(angle) * endRadius),
        linePaint,
      );
    }
  }
}
