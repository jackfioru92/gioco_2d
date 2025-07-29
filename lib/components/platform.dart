import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'player.dart';

class Platform extends RectangleComponent
    with HasGameReference, CollisionCallbacks {
  Platform({required Vector2 position, required Vector2 size}) {
    this.position = position;
    this.size = size;
  }

  @override
  Future<void> onLoad() async {
    // Colore della piattaforma (marrone)
    paint = Paint()..color = const Color(0xFF8D6E63);

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
      // Calcola le posizioni relative
      final playerCenterX = other.position.x + other.size.x / 2;
      final playerCenterY = other.position.y + other.size.y / 2;
      final platformCenterX = position.x + size.x / 2;
      final platformCenterY = position.y + size.y / 2;

      // Calcola le differenze
      final dx = playerCenterX - platformCenterX;
      final dy = playerCenterY - platformCenterY;

      // Calcola le distanze minime per la separazione
      final minDistanceX = (other.size.x + size.x) / 2;
      final minDistanceY = (other.size.y + size.y) / 2;

      // Determina da che lato avviene la collisione
      if (dx.abs() / minDistanceX > dy.abs() / minDistanceY) {
        // Collisione orizzontale (sinistra o destra)
        if (dx > 0) {
          // Player a destra della piattaforma
          other.position.x = position.x + size.x;
          print("🧱 Collisione lato destro piattaforma!");
        } else {
          // Player a sinistra della piattaforma
          other.position.x = position.x - other.size.x;
          print("🧱 Collisione lato sinistro piattaforma!");
        }
        other.velocityX = 0;
      } else {
        // Collisione verticale (sopra o sotto)
        if (dy > 0) {
          // Player sotto la piattaforma
          other.position.y = position.y + size.y;
          other.velocityY = 0;
          print("🧱 Collisione dal basso piattaforma!");
        } else {
          // Player sopra la piattaforma
          if (other.velocityY > 0) {
            other.landOnGround(position.y);
            print("🏗️ Player atterrato su piattaforma!");
          }
        }
      }
      return true;
    }
    return false;
  }
}
