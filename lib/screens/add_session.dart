import 'package:flutter/material.dart';
import '../models/poker_model.dart';
import '../services/data_service.dart';
import 'active_game.dart';

class SettleSessionScreen extends StatefulWidget {
  final List<LivePlayer> playersData;
  final int buyInPrice;
  final int chipsPerBuyIn;

  const SettleSessionScreen({
    super.key,
    required this.playersData,
    required this.buyInPrice,
    required this.chipsPerBuyIn,
  });

  @override
  State<SettleSessionScreen> createState() => _SettleSessionScreenState();
}

class _SettleSessionScreenState extends State<SettleSessionScreen> {
  final DataService _dataService = DataService();
  final _locationController = TextEditingController(text: "Home Game");

  late List<TextEditingController> _outControllers;
  int _difference = 0;
  bool _isInputInChips = true;
  int? _lastChangedIndex;

  @override
  void initState() {
    super.initState();
    _outControllers = List.generate(
      widget.playersData.length,
      (_) => TextEditingController(text: "0"),
    );

    for (int i = 0; i < _outControllers.length; i++) {
      _outControllers[i].addListener(() {
        _lastChangedIndex = i;
        _calculateDifference();
      });
    }
    _calculateDifference();
  }

  double get _moneyPerChip => widget.buyInPrice / widget.chipsPerBuyIn;

  int _calculateCashValue(String inputValue) {
    int value = int.tryParse(inputValue) ?? 0;
    if (_isInputInChips) {
      return (value * _moneyPerChip).round();
    }
    return value;
  }

  int get _totalBuyIn =>
      widget.playersData.fold(0, (sum, p) => sum + p.totalInvested(widget.buyInPrice));

  void _calculateDifference() {
    int totalCashOut = 0;
    for (var controller in _outControllers) {
      totalCashOut += _calculateCashValue(controller.text);
    }

    if (totalCashOut > _totalBuyIn && _lastChangedIndex != null) {
      int excess = totalCashOut - _totalBuyIn;
      final controller = _outControllers[_lastChangedIndex!];
      int currentValue = int.tryParse(controller.text) ?? 0;

      if (_isInputInChips) {
        int excessInChips = (excess / _moneyPerChip).ceil();
        controller.text =
            (currentValue - excessInChips).clamp(0, currentValue).toString();
      } else {
        controller.text =
            (currentValue - excess).clamp(0, currentValue).toString();
      }

      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
      return;
    }

    setState(() {
      _difference = totalCashOut - _totalBuyIn;
    });
  }

  void _splitDifference() {
    if (_difference == 0 || widget.playersData.isEmpty) return;

    int playerCount = widget.playersData.length;
    double shareInMoney = _difference / playerCount;

    for (var controller in _outControllers) {
      int currentValue = int.tryParse(controller.text) ?? 0;

      if (_isInputInChips) {
        int shareInChips = (shareInMoney / _moneyPerChip).round();
        controller.text = (currentValue - shareInChips).toString();
      } else {
        controller.text = (currentValue - shareInMoney.round()).toString();
      }
    }
    _calculateDifference();
  }

  void _saveSession() async {
    if (_difference != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pot must be balanced (0) to save.")),
      );
      return;
    }

    final newSession = Session()
      ..date = DateTime.now()
      ..location = _locationController.text;

    List<PlayerResult> results = [];
    for (int i = 0; i < widget.playersData.length; i++) {
      final playerLive = widget.playersData[i];
      final cashOut = _calculateCashValue(_outControllers[i].text);

      results.add(PlayerResult()
        ..playerName = playerLive.name
        ..buyIn = playerLive.totalInvested(widget.buyInPrice)
        ..cashOut = cashOut);
    }

    await _dataService.saveSession(newSession, results);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    for (var controller in _outControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settle Session")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _difference == 0
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _difference == 0 ? Colors.green : Colors.red),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pot Status:", style: TextStyle(color: Colors.white)),
                        Text(
                          _difference == 0 ? "Balanced ✅" : "Diff: \$$_difference",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _difference == 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                    if (_difference != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _splitDifference,
                            icon: const Icon(Icons.call_split),
                            label: const Text("Split Difference Evenly"),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: Text(_isInputInChips ? "Input: Chips" : "Input: Cash"),
                value: _isInputInChips,
                onChanged: (val) {
                  setState(() {
                    _isInputInChips = val;
                    _calculateDifference();
                  });
                },
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: "Location/Session Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.playersData.length,
                itemBuilder: (context, index) {
                  final player = widget.playersData[index];
                  final invested = player.totalInvested(widget.buyInPrice);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(player.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Text("Buy-in: \$$invested"),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _outControllers[index],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText:
                                    _isInputInChips ? "Chips" : "Cash",
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveSession,
                icon: const Icon(Icons.save),
                label: const Text("Save History & Finish"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
