import 'package:isar/isar.dart';

part 'poker_model.g.dart';

@collection
class Session {
  Id id = Isar.autoIncrement;

  late DateTime date;
  late String location;
  
  final results = IsarLinks<PlayerResult>();

  int get totalProfit {
    return results.fold(0, (sum, result) => sum + result.profit);
  }
}

@collection
class PlayerResult {
  Id id = Isar.autoIncrement;

  late String playerName;
  late int buyIn;
  late int cashOut;

  int get profit {
    return cashOut - buyIn;
  }
}