class ActiveGameModel {
  double currentPot;
  List<String> players;
  int currentTurnIndex;

  ActiveGameModel({
    required this.currentPot,
    required this.players,
    required this.currentTurnIndex,
  });

  Map<String, dynamic> toJson() => {
        'currentPot': currentPot,
        'players': players,
        'currentTurnIndex': currentTurnIndex,
      };

  factory ActiveGameModel.fromJson(Map<String, dynamic> json) {
    return ActiveGameModel(
      currentPot: (json['currentPot'] as num).toDouble(),
      players: List<String>.from(json['players']),
      currentTurnIndex: json['currentTurnIndex'],
    );
  }
}