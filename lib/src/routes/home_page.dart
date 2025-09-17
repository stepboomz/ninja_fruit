import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fruit_ninja/src/game.dart';

class HomePage extends Component
    with TapCallbacks, HasGameReference<MainRouterGame> {
  late final TextComponent _title;
  late final TextComponent _tapToPlay;
  late final TextComponent _rulesTitle;
  late final List<TextComponent> _rulesList;
  late final TextComponent _howToPlay;
  late final TextComponent _objective;
  late final RectangleComponent _rulesBackground;

  @override
  void onLoad() async {
    super.onLoad();

    final titlePaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFEBF5FF),
        fontSize: 56,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(offset: Offset(3, 3), blurRadius: 0, color: Color(0xFF1E88E5)),
          Shadow(
              offset: Offset(-1, -1), blurRadius: 0, color: Color(0xFF0D47A1)),
        ],
      ),
    );

    final tapPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        shadows: [
          Shadow(offset: Offset(2, 2), blurRadius: 0, color: Color(0xFF1976D2)),
        ],
      ),
    );

    final rulesTitlePaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFD700),
        fontSize: 24,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 0, color: Color(0xFF1976D2)),
        ],
      ),
    );

    final rulesPaint = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 0, color: Color(0xFF1976D2)),
        ],
      ),
    );

    final howToPlayPaint = TextPaint(
      style: const TextStyle(
        color: Color(0xFFFFD700),
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 0, color: Color(0xFF1976D2)),
        ],
      ),
    );

    _title = TextComponent(text: 'Fruit Makro', textRenderer: titlePaint)
      ..anchor = Anchor.topCenter;

    // _howToPlay = TextComponent(
    //     text: '🎮 HOW TO PLAY: Tap fruits to slice, avoid bombs! 🎮',
    //     textRenderer: howToPlayPaint)
    //   ..anchor = Anchor.center;

    // _objective = TextComponent(
    //     text: '🎯 OBJECTIVE: Score as many points as possible!',
    //     textRenderer: howToPlayPaint)
    //   ..anchor = Anchor.center;

    _rulesTitle =
        TextComponent(text: 'GAME RULES', textRenderer: rulesTitlePaint)
          ..anchor = Anchor.center;

    final rules = [
      'Slice fruit = +1 point',
      'Touch bomb = Game Over',
      'Start with 3 lives',
      'Miss fruit = -1 life',
      ' Game ends when lives = 0',
      ' Fruits split in 2 when sliced',
    ];

    _rulesList = rules
        .map((rule) => TextComponent(text: rule, textRenderer: rulesPaint)
          ..anchor = Anchor.centerLeft)
        .toList();

    _tapToPlay = TextComponent(text: 'TAP TO START', textRenderer: tapPaint)
      ..anchor = Anchor.center;

    // Create semi-transparent background for rules with border
    _rulesBackground = RectangleComponent(
      paint: Paint()
        ..color = const Color(0xFF1565C0).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    )..anchor = Anchor.center;

    addAll([
      _rulesBackground,
      _title,
      // _howToPlay,
      // _objective,
      _rulesTitle,
      ..._rulesList,
      _tapToPlay
    ]);

    // Pulse and blink effect for TAP TO PLAY
    _tapToPlay.scale = Vector2.all(1);
    _tapToPlay.add(ScaleEffect.to(
      Vector2.all(1.12),
      EffectController(
        duration: 0.6,
        reverseDuration: 0.6,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));
    _tapToPlay.add(MoveByEffect(
      Vector2(0, -6),
      EffectController(
        duration: 0.6,
        reverseDuration: 0.6,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));

    // Add subtle glow effect to title
    _title.add(ScaleEffect.to(
      Vector2.all(1.05),
      EffectController(
        duration: 2.0,
        reverseDuration: 2.0,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));

    // Add effects for rules
    for (int i = 0; i < _rulesList.length; i++) {
      // Add subtle bounce effect with different timing for each rule
      _rulesList[i].add(ScaleEffect.to(
        Vector2.all(1.03),
        EffectController(
          duration: 1.8 + (i * 0.2),
          reverseDuration: 1.8 + (i * 0.2),
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ));

      // Add slight floating effect
      _rulesList[i].add(MoveByEffect(
        Vector2(0, -2),
        EffectController(
          duration: 2.5 + (i * 0.3),
          reverseDuration: 2.5 + (i * 0.3),
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ));
    }

    // Add bounce effect to rules title
    _rulesTitle.add(ScaleEffect.to(
      Vector2.all(1.08),
      EffectController(
        duration: 1.5,
        reverseDuration: 1.5,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));

    // Add subtle pulse effect to rules background
    _rulesBackground.add(ScaleEffect.to(
      Vector2.all(1.02),
      EffectController(
        duration: 3.0,
        reverseDuration: 3.0,
        infinite: true,
        curve: Curves.easeInOut,
      ),
    ));

    // Add floating effect to how to play text
    // _howToPlay.add(MoveByEffect(
    //   Vector2(0, -4),
    //   EffectController(
    //     duration: 2.0,
    //     reverseDuration: 2.0,
    //     infinite: true,
    //     curve: Curves.easeInOut,
    //   ),
    // ));

    // Add glow effect to objective text
    // _objective.add(ScaleEffect.to(
    //   Vector2.all(1.06),
    //   EffectController(
    //     duration: 1.8,
    //     reverseDuration: 1.8,
    //     infinite: true,
    //     curve: Curves.easeInOut,
    //   ),
    // )
    // );

    // _objective.add(MoveByEffect(
    //   Vector2(0, -3),
    //   EffectController(
    //     duration: 2.2,
    //     reverseDuration: 2.2,
    //     infinite: true,
    //     curve: Curves.easeInOut,
    //   ),
    // ));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _title.position = Vector2(size.x / 2, size.y * 0.10);
    // _howToPlay.position = Vector2(size.x / 2, size.y * 0.22);
    // _objective.position = Vector2(size.x / 2, size.y * 0.30);
    _rulesTitle.position = Vector2(size.x / 2, size.y * 0.38);

    // Position rules background
    _rulesBackground.position = Vector2(size.x / 2, size.y * 0.58);
    _rulesBackground.size = Vector2(size.x * 0.85, size.y * 0.32);

    // Add border effect to rules background
    if (_rulesBackground.children.isEmpty) {
      final borderPaint = Paint()
        ..color = const Color(0xFF64B5F6).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      _rulesBackground.add(RectangleComponent(
        paint: borderPaint,
        size: _rulesBackground.size,
      )..anchor = Anchor.center);
    }

    // Position rules list
    double startY = size.y * 0.45;
    for (int i = 0; i < _rulesList.length; i++) {
      _rulesList[i].position = Vector2(size.x * 0.15, startY + (i * 28));
    }

    _tapToPlay.position = Vector2(size.x / 2, size.y * 0.88);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.router.pushNamed('game-page');
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;
}
