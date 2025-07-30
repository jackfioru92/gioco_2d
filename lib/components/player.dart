import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'platform.dart';
import 'ground.dart';

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

  // Salviamo la posizione precedente per gestire meglio le collisioni
  Vector2 previousPosition = Vector2.zero();

  // Flag per controllare le collisioni laterali - "gabbia"
  bool canMoveLeft = true;
  bool canMoveRight = true;
  bool canMoveUp = true;
  bool canMoveDown = true;

  // Hitbox per la "gabbia" di rilevamento collisioni
  late RectangleHitbox leftSensor;
  late RectangleHitbox rightSensor;
  late RectangleHitbox topSensor;
  late RectangleHitbox bottomSensor;
  @override
  Future<void> onLoad() async {
    // Dimensioni del personaggio
    size = Vector2(50, 80);

    // Colore del personaggio (blu)
    paint = Paint()..color = const Color(0xFF2196F3);

    // Aggiungi l'hitbox principale del player
    add(RectangleHitbox());

    // Crea la "gabbia" di sensori per rilevare collisioni direzionali
    _createCollisionCage();
  }

  void _createCollisionCage() {
    // Sensore sinistro - striscia sottile sul lato sinistro
    leftSensor = RectangleHitbox(
      position: Vector2(-2, 5), // Leggermente fuori dal player
      size: Vector2(4, size.y - 10), // Striscia verticale
    );
    add(leftSensor);

    // Sensore destro - striscia sottile sul lato destro
    rightSensor = RectangleHitbox(
      position: Vector2(size.x - 2, 5), // Lato destro del player
      size: Vector2(4, size.y - 10), // Striscia verticale
    );
    add(rightSensor);

    // Sensore superiore - striscia sottile in alto
    topSensor = RectangleHitbox(
      position: Vector2(5, -2), // Leggermente sopra il player
      size: Vector2(size.x - 10, 4), // Striscia orizzontale
    );
    add(topSensor);

    // Sensore inferiore - striscia sottile in basso (per l'atterraggio)
    bottomSensor = RectangleHitbox(
      position: Vector2(5, size.y - 2), // Sotto il player
      size: Vector2(size.x - 10, 4), // Striscia orizzontale
    );
    add(bottomSensor);

    print("🛡️ Gabbia di collisioni creata!");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Salva la posizione precedente
    previousPosition = position.clone();

    // Movimento orizzontale con controllo delle collisioni
    velocityX = 0;
    if (isMovingLeft && canMoveLeft) {
      velocityX = -moveSpeed;
    }
    if (isMovingRight && canMoveRight) {
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
      velocityX = 0;
    }
    if (position.x > game.size.x - size.x) {
      position.x = game.size.x - size.x;
      velocityX = 0;
    }

    // Aggiorna colore in base allo stato
    _updateColor();
  }

  void _updateColor() {
    if (!isOnGround) {
      paint.color = const Color(0xFFFF5722); // Arancione quando salta
    } else if (velocityX != 0) {
      paint.color = const Color(0xFF4CAF50); // Verde quando corre
    } else {
      paint.color = const Color(0xFF2196F3); // Blu quando fermo
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

  // Nuovo metodo per bloccare il movimento laterale
  void blockHorizontalMovement(String direction) {
    if (direction == "left") {
      canMoveLeft = false;
      velocityX = 0;
      position.x = previousPosition.x; // Ripristina posizione precedente
    } else if (direction == "right") {
      canMoveRight = false;
      velocityX = 0;
      position.x = previousPosition.x; // Ripristina posizione precedente
    }
    print("🚫 Movimento $direction bloccato da collisione!");
  }

  // Metodo per resettare i flag di movimento quando non ci sono collisioni
  void resetMovementFlags() {
    canMoveLeft = true;
    canMoveRight = true;
    canMoveUp = true;
    canMoveDown = true;
  }

  @override
  bool onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Calcola la posizione relativa per determinare da che lato avviene la collisione
    final playerCenter = position + size / 2;
    final otherCenter = other.position + other.size / 2;

    final dx = otherCenter.x - playerCenter.x;
    final dy = otherCenter.y - playerCenter.y;

    print(
      "💥 Collisione rilevata con ${other.runtimeType}! dx: ${dx.toStringAsFixed(1)}, dy: ${dy.toStringAsFixed(1)}",
    );

    // Se è il terreno (Ground), gestiamo solo collisioni verticali (atterraggio)
    if (other is Ground) {
      if (velocityY > 0 && dy > 0) {
        // Solo atterraggio sul terreno
        isOnGround = true;
        position.y = other.position.y - size.y;
        velocityY = 0;
        print("🏃 ATTERRAGGIO su terreno!");
      }
      return true;
    }

    // Per le piattaforme (Platform), gestiamo tutte le collisioni
    if (other is Platform) {
      // Determina quale lato del player ha colpito la piattaforma
      final absX = dx.abs();
      final absY = dy.abs();

      if (absX > absY) {
        // Collisione laterale - solo per le piattaforme
        if (dx > 0) {
          // Piattaforma a destra del player - blocca movimento a destra
          canMoveRight = false;
          // Respingi il player verso sinistra se si sta muovendo a destra
          if (velocityX > 0) {
            position.x = other.position.x - size.x - 1;
            velocityX = 0;
          }
          print("🚫 DESTRA bloccata da piattaforma!");
        } else {
          // Piattaforma a sinistra del player - blocca movimento a sinistra  
          canMoveLeft = false;
          // Respingi il player verso destra se si sta muovendo a sinistra
          if (velocityX < 0) {
            position.x = other.position.x + other.size.x + 1;
            velocityX = 0;
          }
          print("🚫 SINISTRA bloccata da piattaforma!");
        }
      } else {
        // Collisione verticale con piattaforma
        if (dy > 0) {
          // Piattaforma sotto il player - atterraggio
          if (velocityY > 0) {
            isOnGround = true;
            position.y = other.position.y - size.y;
            velocityY = 0;
            print("🏃 ATTERRAGGIO su piattaforma!");
          }
        } else {
          // Piattaforma sopra il player - colpo alla testa
          if (velocityY < 0) {
            position.y = other.position.y + other.size.y;
            velocityY = 0;
            print("🚫 TESTA colpita da piattaforma!");
          }
        }
      }
    }

    return true;
  }  @override
  bool onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // Quando una collisione finisce, resettiamo i flag di movimento
    // per permettere nuovamente il movimento in tutte le direzioni
    canMoveLeft = true;
    canMoveRight = true;
    canMoveUp = true;
    canMoveDown = true;

    print("✅ Fine collisione con ${other.runtimeType} - movimento libero!");
    return true;
  }
}
