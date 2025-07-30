import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'platform.dart';

class PlatformGenerator extends Component with HasGameReference {
  final Random _random = Random();
  final double spawnInterval = 300.0; // Distanza tra le piattaforme
  final double minPlatformWidth = 80.0;
  final double maxPlatformWidth = 200.0;
  final double minPlatformHeight = 20.0;
  final double maxPlatformHeight = 100.0;

  // Tipi di piattaforme
  final List<PlatformType> platformTypes = [
    PlatformType.horizontal,
    PlatformType.vertical,
    PlatformType.square,
    PlatformType.wall,
  ];

  late double nextSpawnX;
  int platformCount = 0;
  final int maxPlatforms = 10; // Numero massimo di piattaforme

  @override
  FutureOr<void> onLoad() async {
    nextSpawnX = 400; // Inizia dopo un po' di spazio
    await _generateInitialPlatforms();
    return super.onLoad();
  }

  Future<void> _generateInitialPlatforms() async {
    print("🏗️ Generazione automatica piattaforme iniziata!");

    // Genera piattaforme iniziali
    for (int i = 0; i < maxPlatforms; i++) {
      await _spawnPlatform();
    }

    print("✅ Generate $platformCount piattaforme automaticamente!");
  }

  Future<void> _spawnPlatform() async {
    if (platformCount >= maxPlatforms) return;

    final platformType = platformTypes[_random.nextInt(platformTypes.length)];
    final platform = await _createPlatformByType(platformType);

    if (platform != null) {
      game.add(platform);
      platformCount++;
      nextSpawnX +=
          spawnInterval + _random.nextDouble() * 100; // Distanza variabile

      print(
        "🔧 Creata piattaforma ${platformType.name} in posizione ${platform.position}",
      );
    }
  }

  Future<Platform?> _createPlatformByType(PlatformType type) async {
    final baseY =
        game.size.y - 200 - (_random.nextDouble() * 400); // Altezza variabile

    Vector2 position;
    Vector2 size;

    switch (type) {
      case PlatformType.horizontal:
        // Piattaforma orizzontale classica
        size = Vector2(
          minPlatformWidth +
              _random.nextDouble() * (maxPlatformWidth - minPlatformWidth),
          minPlatformHeight + _random.nextDouble() * 20,
        );
        position = Vector2(nextSpawnX, baseY);
        break;

      case PlatformType.vertical:
        // Colonna verticale
        size = Vector2(
          40 + _random.nextDouble() * 40, // Più stretta
          minPlatformHeight +
              _random.nextDouble() * (maxPlatformHeight - minPlatformHeight),
        );
        position = Vector2(nextSpawnX, baseY - size.y / 2);
        break;

      case PlatformType.square:
        // Piattaforma quadrata
        final squareSize = 60 + _random.nextDouble() * 60;
        size = Vector2(squareSize, squareSize);
        position = Vector2(nextSpawnX, baseY);
        break;

      case PlatformType.wall:
        // Muro alto per bloccare completamente
        size = Vector2(
          30 + _random.nextDouble() * 20,
          150 + _random.nextDouble() * 200,
        );
        position = Vector2(nextSpawnX, game.size.y - 100 - size.y);
        break;
    }

    return Platform(position: position, size: size);
  }
}

enum PlatformType { horizontal, vertical, square, wall }
