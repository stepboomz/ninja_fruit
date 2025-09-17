import 'package:flame/components.dart';

class AppConfig{
  AppConfig._();
  static const gravity = -9.81;
  static const double objSize = 50;
  static const double acceleration = -400;
  static final Vector2 shapeSize = Vector2.all(85);
  static bool iceTheme = true;
  static double fallSpeedMultiplier = 1.0;
}