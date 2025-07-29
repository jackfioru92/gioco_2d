import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'player.dart';

class Ground extends RectangleComponent
    with HasGameReference, CollisionCallbacks {
  @override
  Future<void> onLoad() async {
    // Posiziona il terreno nella parte inferiore dello schermo
    size = Vector2(game.size.x, 100);
    position = Vector2(0, game.size.y - size.y);

    // Colore del terreno (verde)
    paint = Paint()..color = const Color(0xFF4CAF50);

    // Aggiunge il collision box
    add(RectangleHitbox());
  }

  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      // Per il terreno, gestiamo solo collisioni dall'alto
      if (other.velocityY > 0 && other.position.y < position.y) {
        other.landOnGround(position.y);
        print("🌱 Player atterrato sul terreno!");
        return true;
      }
    }
    return false;
  }
}
