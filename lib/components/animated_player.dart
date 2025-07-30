import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'platform.dart';
import 'ground.dart';

class AnimatedPlayer extends SpriteAnimationComponent
    with HasGameReference, CollisionCallbacks {
  static const double moveSpeed = 200.0;
  static const double jumpSpeed = 550.0;
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

  // Animazioni
  late SpriteAnimation idleAnimation;
  late SpriteAnimation runAnimation;
  late SpriteAnimation jumpAnimation;

  // Stati di animazione
  String currentState = 'idle';
  bool facingRight = true;

  @override
  Future<void> onLoad() async {
    // Dimensioni del personaggio (64x64 per gli sprite)
    size = Vector2(64, 64);

    try {
      // Carica le animazioni
      await _loadAnimations();

      // Imposta l'animazione iniziale
      animation = idleAnimation;
      print("✅ Animazioni caricate con successo!");
    } catch (e) {
      print("❌ Errore nel caricamento animazioni: $e");
      // Fallback: crea un rettangolo colorato
      await _createFallbackSprite();
    }

    // Aggiungi l'hitbox principale del player
    add(RectangleHitbox());

    // Crea la "gabbia" di sensori per rilevare collisioni direzionali
    _createCollisionCage();
  }

  Future<void> _loadAnimations() async {
    // Carica spritesheet idle (2 frame, 64x64)
    final idleSprite = await game.loadSprite('idle_spritesheet.png');
    idleAnimation = SpriteAnimation.fromFrameData(
      idleSprite.image,
      SpriteAnimationData.sequenced(
        amount: 2,
        textureSize: Vector2(64, 64),
        stepTime: 0.8, // Animazione lenta per idle
      ),
    );

    // Carica spritesheet run (3 frame, 64x64)
    final runSprite = await game.loadSprite('run_spritesheet.png');
    runAnimation = SpriteAnimation.fromFrameData(
      runSprite.image,
      SpriteAnimationData.sequenced(
        amount: 3,
        textureSize: Vector2(64, 64),
        stepTime: 0.15, // Animazione veloce per corsa
      ),
    );

    // Carica spritesheet jump (5 frame, 64x64)
    final jumpSprite = await game.loadSprite('jump_spritesheet.png');
    jumpAnimation = SpriteAnimation.fromFrameData(
      jumpSprite.image,
      SpriteAnimationData.sequenced(
        amount: 5,
        textureSize: Vector2(64, 64),
        stepTime: 0.1, // Animazione veloce per salto
      ),
    );
  }

  Future<void> _createFallbackSprite() async {
    // Crea un'immagine semplice come fallback
    final paint = Paint()..color = const Color(0xFF2196F3);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(Rect.fromLTWH(0, 0, 64, 64), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);

    final sprite = Sprite(image);
    animation = SpriteAnimation.spriteList([sprite], stepTime: 1.0);
    print("🔄 Usando fallback rettangolo colorato");
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
      facingRight = false;
    }
    if (isMovingRight && canMoveRight) {
      velocityX = moveSpeed;
      facingRight = true;
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

    // Aggiorna animazione e direzione
    _updateAnimation();
  }

  void _updateAnimation() {
    String newState = 'idle';

    // Determina lo stato corrente
    if (!isOnGround) {
      newState = 'jump';
    } else if (velocityX != 0) {
      newState = 'run';
    } else {
      newState = 'idle';
    }

    // Cambia animazione solo se necessario
    if (newState != currentState) {
      currentState = newState;

      switch (currentState) {
        case 'idle':
          animation = idleAnimation;
          break;
        case 'run':
          animation = runAnimation;
          break;
        case 'jump':
          animation = jumpAnimation;
          break;
      }
    }

    // Gestisci la direzione (flip orizzontale)
    if (!facingRight) {
      scale.x = -1; // Flip orizzontale
    } else {
      scale.x = 1; // Normale
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

  void startFalling() {
    if (isOnGround) {
      isOnGround = false;
      print("💨 Player inizia a cadere dal bordo!");
    }
  }

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
  }

  @override
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
