import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/components.dart' show PolygonComponent;
import 'package:flutter/material.dart' hide Route, BackButton;
import 'package:flutter_fruit_ninja/src/components/back_button.dart';
import 'package:flutter_fruit_ninja/src/components/pause_button.dart';
import 'package:flutter_fruit_ninja/src/config/app_config.dart';
import 'package:flutter_fruit_ninja/src/game.dart';
import '../components/fruit_component.dart';

class GamePage extends Component
    with TapCallbacks, HasGameReference<MainRouterGame> {
  final Random random = Random();
  late List<double> fruitsTime;
  late double time, countDown;
  TextComponent? _countdownTextComponent, _scoreTextComponent;
  bool _countdownFinished = false;
  late int mistakeCount, score;
  late int lives;
  LivesHud? _livesHud;
  final List<CircleComponent> _snowflakes = [];
  double _lastSpawnTime = 0;

  // Game timer system (30 seconds)
  late double gameTimeLeft;
  TextComponent? _timerTextComponent;

  // Fruit counting system
  final Map<String, int> fruitCounts = {};
  TextComponent? _fruitCountsTextComponent;

  @override
  void onMount() {
    super.onMount();

    fruitsTime = [];
    countDown = 3;
    mistakeCount = 0;
    score = 0;
    lives = 3;
    time = 0;
    _countdownFinished = false;

    // Initialize game timer (30 seconds)
    gameTimeLeft = 30.0;

    // Reset fruit counts when starting new game
    fruitCounts.clear();

    double initTime = 0;
    for (int i = 0; i < 40; i++) {
      if (i != 0) {
        initTime = fruitsTime.last;
      }
      final millySecondTime = random.nextInt(100) / 100;
      final componentTime = random.nextInt(1) + millySecondTime + initTime;
      fruitsTime.add(componentTime);
    }

    // Add continuous spawning
    _lastSpawnTime = time;

    addAll([
      BackButton(onPressed: () {
        removeAll(children);
        game.router.pop();
      }),
      PauseButton(),
      _countdownTextComponent = TextComponent(
        text: '${countDown.toInt() + 1}',
        size: Vector2.all(50),
        position: game.size / 2,
        anchor: Anchor.center,
      ),
      _livesHud = LivesHud(lives: lives)
        ..position = Vector2(game.size.x - 10, 10)
        ..anchor = Anchor.topRight,
      _timerTextComponent = TextComponent(
        text: 'Time: ${gameTimeLeft.toInt()}s',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                  offset: Offset(2, 2), blurRadius: 4, color: Colors.black54),
            ],
          ),
        ),
        position:
            Vector2(game.size.x - 10, 100), // ห่างจาก fruit counts มากขึ้น
        anchor: Anchor.topRight,
      ),
      _fruitCountsTextComponent = TextComponent(
        text: '',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                  offset: Offset(1, 1), blurRadius: 2, color: Colors.black54),
            ],
          ),
        ),
        position: Vector2(game.size.x - 10, 45), // ห่างจากหัวใจมากขึ้น
        anchor: Anchor.topRight,
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_countdownFinished) {
      countDown -= dt;

      _countdownTextComponent?.text = (countDown.toInt() + 1).toString();
      if (countDown < 0) {
        _countdownFinished = true;
      }
    } else {
      _countdownTextComponent?.removeFromParent();

      time += dt;

      // Update game timer
      gameTimeLeft -= dt;
      _updateTimerDisplay();

      // Check if time is up
      if (gameTimeLeft <= 0) {
        gameTimeLeft = 0;
        gameOver();
        return;
      }

      fruitsTime.where((element) => element < time).toList().forEach((element) {
        final gameSize = game.size;

        final double margin = AppConfig.objSize * 1.2;
        final double minX = margin;
        final double maxX = (gameSize.x - margin).clamp(minX + 1, gameSize.x);
        double posX = minX + random.nextDouble() * (maxX - minX);

        Vector2 fruitPosition = Vector2(posX, -AppConfig.objSize);
        
        // Increase fruit speed as time runs out
        final speedMultiplier = _getFruitSpeedMultiplier();
        Vector2 velocity = Vector2(0, game.maxVerticalVelocity * 0.3 * speedMultiplier);

        final randFruit = game.fruits.random();

        add(FruitComponent(
          this,
          fruitPosition,
          acceleration: AppConfig.acceleration,
          fruit: randFruit,
          size: AppConfig.shapeSize,
          image: game.images.fromCache(randFruit.image),
          pageSize: gameSize,
          velocity: velocity,
          fallingFromTop: true,
        ));
        fruitsTime.remove(element);
      });

      // Dynamic spawning - faster as time runs out
      final spawnInterval = _getSpawnInterval();
      if (time - _lastSpawnTime > spawnInterval) {
        // Spawn multiple fruits when time is running low
        final fruitCount = _getFruitSpawnCount();
        
        for (int i = 0; i < fruitCount; i++) {
          final millySecondTime = random.nextInt(100) / 100;
          final nextSpawnTime = time + (spawnInterval * 0.3) + millySecondTime + (i * 0.1);
          fruitsTime.add(nextSpawnTime);
        }
        _lastSpawnTime = time;
      }
    }
  }

  void _spawnSnow() {
    final int flakeCount = (game.size.x / 10).clamp(30, 100).toInt();
    for (int i = 0; i < flakeCount; i++) {
      final x = random.nextDouble() * game.size.x;
      final y = random.nextDouble() * game.size.y;
      final r = 1.0 + random.nextDouble() * 3.0;
      final speed = 15 + random.nextDouble() * 50;
      final opacity = 0.4 + random.nextDouble() * 0.6;
      final flake = CircleComponent(
        position: Vector2(x, y),
        radius: r,
        priority: 5,
      )..paint = (Paint()..color = Color.fromRGBO(255, 255, 255, opacity));
      flake.add(_SnowBehavior(
        speed: speed,
        drift: random.nextDouble() * 0.8 + 0.3,
        swaySpeed: random.nextDouble() * 2.0 + 1.0,
      ));
      _snowflakes.add(flake);
    }
    addAll(_snowflakes);
  }

  void _updateSnow(double dt) {
    for (final flake in _snowflakes) {
      final behavior = flake.children.query<_SnowBehavior>().first;
      flake.position.y += behavior.speed * dt;
      flake.position.x +=
          sin(time * behavior.swaySpeed + flake.position.y * 0.03) *
              behavior.drift;

      // Add slight rotation to snowflakes
      if (flake is CircleComponent) {
        // Create a subtle sparkle effect by varying opacity
        final sparkle =
            0.3 + 0.4 * (1 + sin(time * 3 + flake.position.x * 0.1)) / 2;
        flake.paint = Paint()..color = Color.fromRGBO(255, 255, 255, sparkle);
      }

      if (flake.position.y > game.size.y + 10) {
        flake.position
          ..y = -10
          ..x = random.nextDouble() * game.size.x;
      }
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final position = event.localPosition;
    componentsAtPoint(position).forEach((element) {
      if (element is FruitComponent) {
        element.touchAtPoint(position);
      }
    });
  }

  void gameOver() {
    // Reset fruit counts when game over
    fruitCounts.clear();
    _updateFruitCountsDisplay();

    game.router.pushNamed('game-over');
  }

  void addScore([String? fruitName]) {
    score++;
    // Remove score display - now we only show timer

    // Count fruits if fruitName is provided
    if (fruitName != null && fruitName.isNotEmpty) {
      fruitCounts[fruitName] = (fruitCounts[fruitName] ?? 0) + 1;
      _updateFruitCountsDisplay();
    }
  }

  double _getSpawnInterval() {
    // Calculate spawn interval based on remaining time
    // Start: 1.5 seconds, End: 0.3 seconds (much faster)
    final timeProgress = (30.0 - gameTimeLeft) / 30.0; // 0.0 to 1.0
    final minInterval = 0.3; // Fastest spawn rate
    final maxInterval = 1.5; // Slowest spawn rate
    
    // Linear interpolation from slow to fast
    return maxInterval - (timeProgress * (maxInterval - minInterval));
  }

  double _getFruitSpeedMultiplier() {
    // Calculate speed multiplier based on remaining time
    // Start: 1.0x speed, End: 2.0x speed (twice as fast)
    final timeProgress = (30.0 - gameTimeLeft) / 30.0; // 0.0 to 1.0
    final minSpeed = 1.0; // Normal speed
    final maxSpeed = 2.0; // Double speed
    
    // Linear interpolation from normal to fast
    return minSpeed + (timeProgress * (maxSpeed - minSpeed));
  }

  int _getFruitSpawnCount() {
    // Calculate how many fruits to spawn at once
    // Start: 1 fruit, End: 3 fruits (chaos mode!)
    if (gameTimeLeft > 20) return 1; // Normal: 1 fruit
    if (gameTimeLeft > 10) return 2; // Medium: 2 fruits
    return 3; // Chaos: 3 fruits at once!
  }

  void _updateTimerDisplay() {
    final timeLeft = gameTimeLeft.toInt();
    _timerTextComponent?.text = 'Time: ${timeLeft}s';

    // Add warning effect when time is running low
    if (timeLeft <= 10) {
      // Red color and larger size when time is critical
      _timerTextComponent?.textRenderer = TextPaint(
        style: TextStyle(
          color: timeLeft <= 5 ? Colors.red : Colors.orange,
          fontSize: timeLeft <= 5 ? 22 : 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
                offset: const Offset(2, 2),
                blurRadius: timeLeft <= 5 ? 6 : 4,
                color: Colors.black54),
          ],
        ),
      );

      // Add pulsing effect when very low (simplified)
      if (timeLeft <= 5) {
        // Just change the visual without complex effects for now
        // The color and size changes above are sufficient
      }
    } else {
      // Normal orange color
      _timerTextComponent?.textRenderer = TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black54),
          ],
        ),
      );
    }
  }

  void _updateFruitCountsDisplay() {
    if (fruitCounts.isEmpty) {
      _fruitCountsTextComponent?.text = '';
      return;
    }

    final List<String> fruitTexts = [];
    fruitCounts.forEach((fruitName, count) {
      // Get fruit emoji based on name
      String emoji = _getFruitEmoji(fruitName);
      fruitTexts.add('$emoji x$count');
    });

    // Join with spaces, but limit to 3 items per line
    String displayText = '';
    for (int i = 0; i < fruitTexts.length; i++) {
      if (i > 0 && i % 3 == 0) {
        displayText += '\n';
      } else if (i > 0) {
        displayText += ' ';
      }
      displayText += fruitTexts[i];
    }

    _fruitCountsTextComponent?.text = displayText;
  }

  String _getFruitEmoji(String fruitName) {
    switch (fruitName.toLowerCase()) {
      case 'apple':
        return '🍎';
      case 'banana':
        return '🥤';
      case 'orange':
        return '🍊';
      case 'kiwi':
        return '🥝';
      case 'peach':
        return '🥛';
      case 'pineapple':
        return '🍍';
      default:
        return '🍎';
    }
  }

  void addMistake() {
    mistakeCount++;
    lives = (3 - mistakeCount).clamp(0, 3);
    _livesHud?.setLives(lives);
    if (lives <= 0) gameOver();
  }
}

class LivesHud extends PositionComponent {
  final double heartSize;
  final double spacing;
  int lives;

  LivesHud({required this.lives, this.heartSize = 16, this.spacing = 6});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuild();
  }

  void setLives(int value) {
    if (lives == value) return;
    lives = value;
    _rebuild();
  }

  void _rebuild() {
    removeAll(children);
    double x = 0;
    for (int i = 0; i < lives; i++) {
      final heart = HeartIcon(iconSize: heartSize)
        ..position = Vector2(x, 0)
        ..anchor = Anchor.topLeft;
      add(heart);
      x += heartSize + spacing;
    }
    size = Vector2(x > 0 ? x - spacing : 0, heartSize);
  }
}

class HeartIcon extends PositionComponent {
  final double iconSize;
  HeartIcon({required this.iconSize});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final double r = iconSize * 0.32;
    final double w = iconSize;
    final double h = iconSize * 0.9;

    // Two top circles
    add(CircleComponent(
      radius: r,
      position: Vector2(r, r),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFFF5A5A),
      priority: 20,
    ));
    add(CircleComponent(
      radius: r,
      position: Vector2(w - r, r),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFFF5A5A),
      priority: 20,
    ));

    // Bottom diamond/triangle-ish using polygon
    final points = [
      Vector2(0, r),
      Vector2(w, r),
      Vector2(w * 0.5, h),
    ];
    add(PolygonComponent(points,
        paint: Paint()..color = const Color(0xFFFF5A5A), priority: 10));
  }
}

class _SnowBehavior extends Component {
  final double speed;
  final double drift;
  final double swaySpeed;
  _SnowBehavior({
    required this.speed,
    required this.drift,
    this.swaySpeed = 1.0,
  });
}
