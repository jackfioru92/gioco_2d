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
      print("🔍 Collisione rilevata con piattaforma!");

      // Calcola le distanze dal centro per determinare il tipo di collisione
      final playerCenterX = other.position.x + other.size.x / 2;
      final playerCenterY = other.position.y + other.size.y / 2;
      final platformCenterX = position.x + size.x / 2;
      final platformCenterY = position.y + size.y / 2;

      final deltaX = playerCenterX - platformCenterX;
      final deltaY = playerCenterY - platformCenterY;

      // Calcola la sovrapposizione
      final overlapX = (other.size.x + size.x) / 2 - deltaX.abs();
      final overlapY = (other.size.y + size.y) / 2 - deltaY.abs();

      // Determina la direzione della collisione basandosi sulla sovrapposizione minore
      if (overlapX < overlapY) {
        // Collisione laterale
        if (deltaX > 0) {
          // Player a destra della piattaforma - blocca movimento a sinistra
          other.position.x = position.x + size.x;
          other.blockHorizontalMovement("left");
          print("🧱 Bloccato movimento verso SINISTRA!");
        } else {
          // Player a sinistra della piattaforma - blocca movimento a destra
          other.position.x = position.x - other.size.x;
          other.blockHorizontalMovement("right");
          print("🧱 Bloccato movimento verso DESTRA!");
        }
      } else {
        // Collisione verticale
        if (deltaY > 0) {
          // Player sotto la piattaforma - collisione dal basso
          other.position.y = position.y + size.y;
          other.velocityY = 0;
          print("🧱 Player colpisce piattaforma dal basso!");
        } else {
          // Player sopra la piattaforma - atterraggio
          if (other.velocityY >= 0) {
            other.landOnGround(position.y);
            print("🏗️ Player atterrato su piattaforma!");
          }
        }
      }
    }

    return true;
  }
}
