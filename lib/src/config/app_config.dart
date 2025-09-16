import 'package:flame/components.dart';

class AppConfig{
  AppConfig._();
  static const gravity = -9.81;
  static const double objSize = 50;
  static const double acceleration = -400;
  static final Vector2 shapeSize = Vector2.all(50);
  static bool iceTheme = false;
  // Fall speed multiplier for fruits dropping from top (1.0 = normal)
  static double fallSpeedMultiplier = 1.0;
}