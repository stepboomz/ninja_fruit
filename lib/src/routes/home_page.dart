import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fruit_ninja/src/game.dart';

class HomePage extends Component
    with TapCallbacks, HasGameReference<MainRouterGame> {
  late final TextComponent _title;
  late final TextComponent _tapToPlay;

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
          Shadow(offset: Offset(-1, -1), blurRadius: 0, color: Color(0xFF0D47A1)),
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

    _title = TextComponent(text: 'Makro Game', textRenderer: titlePaint)
      ..anchor = Anchor.topCenter;

    _tapToPlay = TextComponent(text: 'TAP TO PLAY', textRenderer: tapPaint)
      ..anchor = Anchor.center;

    addAll([_title, _tapToPlay]);

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
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _title.position = Vector2(size.x / 2, size.y * 0.18);
    _tapToPlay.position = Vector2(size.x / 2, size.y * 0.75);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.router.pushNamed('game-page');
  }

  @override
  bool containsLocalPoint(Vector2 point) => true;
}
