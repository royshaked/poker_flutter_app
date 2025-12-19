import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_session.dart';
import '../services/data_service.dart';
import '../models/auto_save.dart';

class LivePlayer {
  String name;
  int rebuys;

  LivePlayer({required this.name, this.rebuys = 1});

  int totalInvested(int buyInPrice) => rebuys * buyInPrice;
  int totalChips(int chipsPerBuy) => rebuys * chipsPerBuy;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rebuys': rebuys,
    };
  }

  factory LivePlayer.fromMap(Map<String, dynamic> map) {
    return LivePlayer(
      name: map['name'],
      rebuys: map['rebuys'],
    );
  }
}

class ActiveGameScreen extends StatefulWidget {
  final int defaultBuyIn;
  final int chipsPerBuyIn;

  const ActiveGameScreen({
    super.key,
    required this.defaultBuyIn,
    required this.chipsPerBuyIn,
  });

  @override
  State<ActiveGameScreen> createState() => _ActiveGameScreenState();
}

class _ActiveGameScreenState extends State<ActiveGameScreen> with WidgetsBindingObserver {
  final List<LivePlayer> _players = [];
  final DataService _dataService = DataService();
  List<String> _existingPlayers = [];
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPlayerNames();
    _checkForSavedGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveGameLocally();
    }
  }

  Future<void> _saveGameLocally() async {
    if (_players.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    double currentPot = _players.fold(0, (sum, p) => sum + p.totalInvested(widget.defaultBuyIn)).toDouble();
    List<String> encodedPlayers = _players.map((p) => jsonEncode(p.toMap())).toList();

    ActiveGameModel gameModel = ActiveGameModel(
      currentPot: currentPot,
      players: encodedPlayers,
      currentTurnIndex: 0,
    );

    String jsonString = jsonEncode(gameModel.toJson());
    await prefs.setString('saved_active_game', jsonString);
  }

  Future<void> _checkForSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('saved_active_game')) {
      String? jsonString = prefs.getString('saved_active_game');
      if (jsonString != null) {
        ActiveGameModel loadedModel = ActiveGameModel.fromJson(jsonDecode(jsonString));
        
        setState(() {
          _players.clear();
          for (String playerJson in loadedModel.players) {
            _players.add(LivePlayer.fromMap(jsonDecode(playerJson)));
          }
        });
      }
    }
    setState(() {
      _isRestoring = false;
    });
  }

  void _loadPlayerNames() async {
    final names = await _dataService.getPlayerNames();
    setState(() {
      _existingPlayers = names;
    });
  }

  void _addPlayer(String name) {
    if (name.isNotEmpty) {
      if (_players.any((p) => p.name == name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name is already in the game!")),
        );
        return;
      }

      setState(() {
        _players.add(LivePlayer(name: name));
      });
      _saveGameLocally(); 
      Navigator.pop(context);
    }
  }

  void _showAddPlayerDialog() {
    String selectedName = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Player"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _existingPlayers.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                selectedName = selection;
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onChanged: (val) => selectedName = val,
                  decoration: const InputDecoration(
                    hintText: "Type name or select...",
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => _addPlayer(selectedName),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _finishGame() async {
    if (_players.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_active_game');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettleSessionScreen(
          playersData: _players,
          buyInPrice: widget.defaultBuyIn,
          chipsPerBuyIn: widget.chipsPerBuyIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalMoneyOnTable = _players.fold(0, (sum, p) => sum + p.totalInvested(widget.defaultBuyIn));

    if (_isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Game 🟢"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Pot: \$$totalMoneyOnTable",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.lightGreenAccent),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _players.isEmpty
                ? const Center(child: Text("Add players to start"))
                : ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      final player = _players[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(player.name[0].toUpperCase())),
                          title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "Invested: \$${player.totalInvested(widget.defaultBuyIn)} (${player.rebuys} buy-ins)"),
                          trailing: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                player.rebuys++;
                              });
                              _saveGameLocally();
                            },
                            icon: const Icon(Icons.add_circle, size: 16),
                            label: const Text("Rebuy"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAddPlayerDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Add Player"),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finishGame,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("Finish Game"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.all(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}