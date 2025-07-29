import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Player extends RectangleComponent
    with HasGameReference, CollisionCallbacks {
  static const double moveSpeed = 200.0;
  static const double jumpSpeed =
      550.0; // Salto ancora più alto per raggiungere le piattaforme
  static const double gravity = 980.0;

  double velocityX = 0.0;
  double velocityY = 0.0;
  bool isOnGround = false;
  bool isMovingLeft = false;
  bool isMovingRight = false;
  bool jumpPressed = false;
  @override
  Future<void> onLoad() async {
    // Dimensioni del personaggio
    size = Vector2(50, 80);

    // Colore del personaggio (blu)
    paint = Paint()..color = const Color(0xFF2196F3);

    // Aggiunge il collision box
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Movimento orizzontale
    velocityX = 0;
    if (isMovingLeft) {
      velocityX = -moveSpeed;
    }
    if (isMovingRight) {
      velocityX = moveSpeed;
    }

    // Salto semplice
    if (jumpPressed && isOnGround) {
      velocityY = -jumpSpeed;
      isOnGround = false;
      jumpPressed = false;
      print("🚀 Salto!");
    }

    // Applica gravità
    if (!isOnGround) {
      velocityY += gravity * dt;
    }

    // Aggiorna posizione
    position.x += velocityX * dt;
    position.y += velocityY * dt;

    // Limiti dello schermo (orizzontali)
    if (position.x < 0) {
      position.x = 0;
    }
    if (position.x > game.size.x - size.x) {
      position.x = game.size.x - size.x;
    }
  }

  void setMovingLeft(bool moving) {
    isMovingLeft = moving;
  }

  void setMovingRight(bool moving) {
    isMovingRight = moving;
  }

  void jump() {
    jumpPressed = true;
  }

  void landOnGround(double groundY) {
    if (velocityY > 0) {
      position.y = groundY - size.y;
      velocityY = 0;
      isOnGround = true;
      print("🏃 Player atterrato!");
    }
  }

  // Aggiunge un metodo per far cadere il player quando esce da una piattaforma
  void startFalling() {
    if (isOnGround) {
      isOnGround = false;
      print("💨 Player inizia a cadere dal bordo!");
    }
  }
}
