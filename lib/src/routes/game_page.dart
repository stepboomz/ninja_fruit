import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/components.dart' show PolygonComponent;
import 'dart:ui' show Color, Paint;
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
  TextComponent? _countdownTextComponent,
      _scoreTextComponent;
  bool _countdownFinished = false;
  late int mistakeCount, score;
  late int lives;
  LivesHud? _livesHud;
  final List<CircleComponent> _snowflakes = [];
  double _lastSpawnTime = 0;

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
      _scoreTextComponent = TextComponent(
        text: 'Score: $score',
        position: Vector2(game.size.x - 10, 50),
        anchor: Anchor.topRight,
      ),
    ]);

    if (AppConfig.iceTheme) {
      _spawnSnow();
    }
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

      if (AppConfig.iceTheme) {
        _updateSnow(dt);
      }

      fruitsTime.where((element) => element < time).toList().forEach((element) {
        final gameSize = game.size;

        final double margin = AppConfig.objSize * 1.2;
        final double minX = margin;
        final double maxX = (gameSize.x - margin).clamp(minX + 1, gameSize.x);
        double posX = minX + random.nextDouble() * (maxX - minX);

        Vector2 fruitPosition = Vector2(posX, -AppConfig.objSize);
        Vector2 velocity = Vector2(0, game.maxVerticalVelocity * 0.3);

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
      
      // Continuous spawning - add new fruit spawn times
      if (time - _lastSpawnTime > 1.5) { // Spawn every 1.5 seconds
        final millySecondTime = random.nextInt(100) / 100;
        final nextSpawnTime = time + 0.5 + millySecondTime; // 0.5-1.5 seconds from now
        fruitsTime.add(nextSpawnTime);
        _lastSpawnTime = time;
      }
    }
  }

  void _spawnSnow() {
    final int flakeCount = (game.size.x / 12).clamp(20, 80).toInt();
    for (int i = 0; i < flakeCount; i++) {
      final x = random.nextDouble() * game.size.x;
      final y = random.nextDouble() * game.size.y;
      final r = 1.5 + random.nextDouble() * 2.0;
      final speed = 20 + random.nextDouble() * 40;
      final flake = CircleComponent(
        position: Vector2(x, y),
        radius: r,
        priority: 5,
      )..paint = (Paint()..color = const Color(0xCCFFFFFF));
      flake.add(_SnowBehavior(speed: speed, drift: random.nextDouble() * 0.6 + 0.2));
      _snowflakes.add(flake);
    }
    addAll(_snowflakes);
  }

  void _updateSnow(double dt) {
    for (final flake in _snowflakes) {
      flake.position.y += (flake.children.query<_SnowBehavior>().first.speed) * dt;
      flake.position.x += sin(time + flake.position.y * 0.05) *
          flake.children.query<_SnowBehavior>().first.drift;
      if (flake.position.y > game.size.y + 5) {
        flake.position
          ..y = -5
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
        element.onTapIce();
      }
    });
  }

  void gameOver() {
    game.router.pushNamed('game-over');
  }

  void addScore() {
    score++;
    _scoreTextComponent?.text = 'Score: $score';
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
  _SnowBehavior({required this.speed, required this.drift});
}
