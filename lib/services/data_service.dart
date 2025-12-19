import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import '../models/poker_model.dart';

class DataService {
  static late Isar isar;

  static Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    if (Isar.instanceNames.isEmpty) {
      isar = await Isar.open(
        [SessionSchema, PlayerResultSchema],
        directory: dir.path,
      );
    } else {
      isar = Isar.getInstance()!;
    }
  }

  Future<void> saveSession(Session newSession, List<PlayerResult> playerResults) async {
    await isar.writeTxn(() async {
      await isar.playerResults.putAll(playerResults);
      newSession.results.addAll(playerResults);
      await isar.sessions.put(newSession);
      await newSession.results.save();
    });
  }

  Future<List<Session>> getAllSessions() async {
    final sessions = await isar.sessions.where().sortByDateDesc().findAll();
    for (var session in sessions) {
      await session.results.load();
    }
    return sessions;
  }

  // --- NEW: Delete Session ---
  Future<void> deleteSession(int sessionId) async {
    await isar.writeTxn(() async {
      // Isar automatically handles link deletion, but we delete the session object
      await isar.sessions.delete(sessionId);
    });
  }

  Future<List<String>> getPlayerNames() async {
    final results = await isar.playerResults.where().findAll();
    return results.map((r) => r.playerName).toSet().toList();
  }
}