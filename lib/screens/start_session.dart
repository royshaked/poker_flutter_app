import 'package:flutter/material.dart';
import 'active_game.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final _buyInController = TextEditingController(text: "50");
  final _chipsController = TextEditingController(text: "500");

  void _startGame() {
    final buyIn = int.tryParse(_buyInController.text) ?? 0;
    final chips = int.tryParse(_chipsController.text) ?? 0;

    if (buyIn <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveGameScreen(
          defaultBuyIn: buyIn,
          chipsPerBuyIn: chips,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Game Setup")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Buy-in Settings", style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: _buyInController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Buy-in Price (\$)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _chipsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Chips per Buy-in",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.casino, color: Colors.orange),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Game", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}