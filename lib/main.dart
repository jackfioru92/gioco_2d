import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gioco 2D Platformer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PlatformerGame game;

  @override
  void initState() {
    super.initState();
    game = PlatformerGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          print("⌨️ RawKeyboardListener onKey chiamato!");
          print("📝 Event: ${event.runtimeType}");
          print("🔑 LogicalKey: ${event.logicalKey}");
          print("🔑 PhysicalKey: ${event.physicalKey}");

          final keysPressed = <LogicalKeyboardKey>{};
          keysPressed.add(event.logicalKey);

          // Converte RawKeyEvent in KeyEvent per compatibilità
          KeyEvent keyEvent;
          if (event is RawKeyDownEvent) {
            keyEvent = KeyDownEvent(
              physicalKey: event.physicalKey,
              logicalKey: event.logicalKey,
              timeStamp: Duration.zero,
            );
          } else if (event is RawKeyUpEvent) {
            keyEvent = KeyUpEvent(
              physicalKey: event.physicalKey,
              logicalKey: event.logicalKey,
              timeStamp: Duration.zero,
            );
          } else {
            keyEvent = KeyRepeatEvent(
              physicalKey: event.physicalKey,
              logicalKey: event.logicalKey,
              timeStamp: Duration.zero,
            );
          }

          print("🔑 Keys to send to game: $keysPressed");
          game.onKeyEvent(keyEvent, keysPressed);
        },
        child: GameWidget<PlatformerGame>.controlled(gameFactory: () => game),
      ),
    );
  }
}
