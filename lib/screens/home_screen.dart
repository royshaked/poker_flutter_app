import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../models/poker_model.dart';
import '../services/data_service.dart';
import 'start_session.dart';
import 'session_detail.dart';

class PokerColors {
  static const Color feltGreen = Color(0xFF0F3B2E);
  static const Color richRed = Color(0xFF8A1C1C);
  static const Color gold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color cardWhite = Color(0xFFE0E0E0);
}

class PlayerStat {
  final String name;
  final int totalProfit;
  final List<FlSpot> graphSpots;

  PlayerStat({
    required this.name,
    required this.totalProfit,
    required this.graphSpots,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Session>> _sessionsFuture;
  final DataService _dataService = DataService();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessionsFuture = _dataService.getAllSessions();
    });
  }

  void _navigateToGameSetup(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const GameSetupScreen()),
    );
    _loadSessions();
  }

  void _confirmDelete(Session session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PokerColors.charcoal,
        shape: RoundedRectangleBorder(
            side: const BorderSide(color: PokerColors.gold, width: 1),
            borderRadius: BorderRadius.circular(15)),
        title: const Text("Fold Session?", style: TextStyle(color: PokerColors.gold)),
        content: Text(
            "Are you sure you want to delete the session at ${session.location}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _dataService.deleteSession(session.id);
              _loadSessions();
            },
            style: TextButton.styleFrom(foregroundColor: PokerColors.richRed),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  List<PlayerStat> _calculatePlayerStats(List<Session> sessions) {
    if (sessions.isEmpty) return [];

    final sortedSessions = List<Session>.from(sessions);
    sortedSessions.sort((a, b) => a.date.compareTo(b.date));

    Map<String, int> currentBalances = {};
    Map<String, List<FlSpot>> playerSpots = {};
    Set<String> allPlayerNames = {};

    for (var session in sortedSessions) {
      for (var result in session.results) {
        allPlayerNames.add(result.playerName);
      }
    }

    for (var name in allPlayerNames) {
      currentBalances[name] = 0;
      playerSpots[name] = [];
    }

    for (int i = 0; i < sortedSessions.length; i++) {
      final session = sortedSessions[i];

      for (var name in allPlayerNames) {
        final result = session.results.where((r) => r.playerName == name).firstOrNull;

        int sessionProfit = 0;
        if (result != null) {
           sessionProfit = result.cashOut - result.buyIn;
        }

        currentBalances[name] = currentBalances[name]! + sessionProfit;
        playerSpots[name]!.add(FlSpot(i.toDouble(), currentBalances[name]!.toDouble()));
      }
    }

    List<PlayerStat> stats = [];
    for (var name in allPlayerNames) {
      stats.add(PlayerStat(
        name: name,
        totalProfit: currentBalances[name]!,
        graphSpots: playerSpots[name]!,
      ));
    }

    stats.sort((a, b) => b.totalProfit.compareTo(a.totalProfit));
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.style, color: PokerColors.gold),
            SizedBox(width: 10),
            Text('Poker Tracker', style: TextStyle(color: PokerColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF1a5c42),
              PokerColors.feltGreen,
              Colors.black,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: FutureBuilder<List<Session>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: PokerColors.gold));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            final sessions = snapshot.data ?? [];
            final playerStats = _calculatePlayerStats(sessions);

            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Text(
                      "Bankroll",
                      style: TextStyle(
                        color: Colors.white70, 
                        fontSize: 14, 
                        letterSpacing: 2.0, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 240,
                    child: playerStats.isEmpty
                      ? _buildEmptyCard()
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: playerStats.length,
                          itemBuilder: (context, index) {
                            return _buildPokerCard(playerStats[index], sessions.length);
                          },
                        ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Session Log",
                          style: TextStyle(color: PokerColors.gold, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.history, color: Colors.white30, size: 20),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sessions.isEmpty
                        ? const Center(child: Text('No hands played yet', style: TextStyle(color: Colors.white30)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 10, bottom: 80),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              return _buildPokerSessionTile(sessions[index]);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToGameSetup(context),
        backgroundColor: PokerColors.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_circle),
        label: const Text("New Game", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black45,
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text("Start a session to track stats", style: TextStyle(color: Colors.white54))),
    );
  }

  Widget _buildPokerCard(PlayerStat stat, int totalSessions) {
    bool isProfit = stat.totalProfit >= 0;
    
    double minY = stat.graphSpots.isEmpty ? 0 : stat.graphSpots.map((s) => s.y).reduce(math.min) - 50;
    double maxY = stat.graphSpots.isEmpty ? 0 : stat.graphSpots.map((s) => s.y).reduce(math.max) + 50;
    
    if (minY > 0) minY = 0;
    if (maxY < 0) maxY = 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isProfit 
                    ? [const Color(0xFF1E2B24), Colors.black] 
                    : [const Color(0xFF2B1E1E), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isProfit ? PokerColors.gold.withValues(alpha: 0.3) : PokerColors.richRed.withValues(alpha: 0.3),
                width: 1
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.05,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  isProfit ? Icons.eco : Icons.local_fire_department,
                  size: 180, 
                  color: Colors.white
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stat.name, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isProfit ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        isProfit ? "WINNING" : "DOWN",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isProfit ? Colors.greenAccent : Colors.redAccent
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "\$${stat.totalProfit}",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    color: isProfit ? PokerColors.gold : PokerColors.richRed,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: (isProfit ? PokerColors.gold : Colors.red).withValues(alpha: 0.4),
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (totalSessions > 0 ? totalSessions - 1 : 0).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: stat.graphSpots,
                          isCurved: true,
                          color: isProfit ? PokerColors.gold : Colors.redAccent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                (isProfit ? PokerColors.gold : Colors.red).withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPokerSessionTile(Session session) {
    final pot = session.results.fold(0, (sum, r) => sum + r.buyIn);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
        ],
        border: Border(left: BorderSide(
          color: pot > 500 ? PokerColors.gold : Colors.grey,
          width: 4
        ))
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _confirmDelete(session),
          onTap: () {
             Navigator.of(context).push(
               MaterialPageRoute(
                 builder: (ctx) => SessionDetailScreen(session: session),
               ),
             );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    gradient: const LinearGradient(colors: [Colors.grey, Colors.black]),
                  ),
                  child: const Center(
                    child: Text("\$", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.location,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(session.date),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("POT", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
                    Text(
                      "\$$pot",
                      style: const TextStyle(color: PokerColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}