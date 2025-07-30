import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'components/player.dart';
import 'components/ground.dart';
import 'components/platform.dart';
import 'components/platform_generator.dart';

class PlatformerGame extends FlameGame with HasCollisionDetection {
  late Player player;
  late Ground ground;
  late PlatformGenerator platformGenerator;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};

  @override
  Future<void> onLoad() async {
    // Crea e aggiungi il terreno
    ground = Ground();
    add(ground);

    // Crea il generatore automatico di piattaforme
    platformGenerator = PlatformGenerator();
    add(platformGenerator);

    // Crea e aggiungi il player
    player = Player();
    player.position = Vector2(100, size.y - 200); // Posiziona sopra il terreno
    add(player);

    print("🎮 Gioco caricato con generatore automatico di piattaforme!");
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Gestisce input continuo
    _handleInput();

    // Controlla se il player deve cadere dal bordo di una piattaforma
    _checkPlayerFalling();

    // Tutte le collisioni sono ora gestite automaticamente dal sistema di collisioni di Flame
  }

  void _handleInput() {
    // Movimento a sinistra
    bool movingLeft = _pressedKeys.contains(LogicalKeyboardKey.arrowLeft);
    bool movingRight = _pressedKeys.contains(LogicalKeyboardKey.arrowRight);

    if (movingLeft || movingRight) {
      print("🏃 Movimento: Left=$movingLeft, Right=$movingRight");
    }

    player.setMovingLeft(movingLeft);
    player.setMovingRight(movingRight);
  }

  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    print("🎮 onKeyEvent chiamato!");
    print("📝 Event type: ${event.runtimeType}");
    print("🔑 Keys pressed: $keysPressed");

    // Gestisci i tasti in base al tipo di evento
    if (event is KeyDownEvent) {
      print("⬇️ KeyDownEvent - aggiungendo tasto: ${event.logicalKey}");
      _pressedKeys.add(event.logicalKey);

      // Salto immediato
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.space) {
        print("🚀 Salto richiesto!");
        player.jump();
      }
    } else if (event is KeyUpEvent) {
      print("⬆️ KeyUpEvent - rimuovendo tasto: ${event.logicalKey}");
      _pressedKeys.remove(event.logicalKey);
    }

    print("🔑 Current pressed keys: $_pressedKeys");
    return true;
  }

  void _checkPlayerFalling() {
    // Controlla solo se il player è a terra e si sta muovendo
    if (!player.isOnGround || player.velocityX == 0) return;

    // Controlla se il player è ancora sopra una superficie solida
    final playerBottom = player.position.y + player.size.y;
    final playerLeft = player.position.x + 5; // Margine sinistro
    final playerRight = player.position.x + player.size.x - 5; // Margine destro

    bool stillOnSomething = false;

    // Controlla il terreno
    if (playerBottom >= ground.position.y - 2 &&
        playerLeft < ground.position.x + ground.size.x &&
        playerRight > ground.position.x) {
      stillOnSomething = true;
    }

    // Controlla le piattaforme generate automaticamente
    if (!stillOnSomething) {
      // Cerca tutte le piattaforme nel gioco
      final allPlatforms = children.whereType<Platform>();
      for (final platform in allPlatforms) {
        if (playerBottom >= platform.position.y - 2 &&
            playerBottom <= platform.position.y + 10 &&
            playerLeft < platform.position.x + platform.size.x &&
            playerRight > platform.position.x) {
          stillOnSomething = true;
          break;
        }
      }
    }

    // Se non è più sopra niente, inizia a cadere
    if (!stillOnSomething) {
      player.startFalling();
    }
  }
}
