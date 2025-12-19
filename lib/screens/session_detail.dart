import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/poker_model.dart';

class SessionDetailScreen extends StatelessWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final totalPot = session.results.fold(0, (sum, r) => sum + r.buyIn);
    
    // Sort players: Winners on top
    final sortedResults = session.results.toList()
      ..sort((a, b) => b.profit.compareTo(a.profit));

    return Scaffold(
      appBar: AppBar(
        title: Text(session.location),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Date", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('MMM d, yyyy').format(session.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Column(
                  children: [
                    const Text("Total Pot", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      "\$$totalPot",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20, 
                        color: Colors.lightGreenAccent
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Player Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: sortedResults.length,
              separatorBuilder: (ctx, i) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final result = sortedResults[index];
                final isProfit = result.profit >= 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isProfit ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    child: Text(
                      result.playerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(color: isProfit ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(result.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Buy-in: \$${result.buyIn}  •  Cash-out: \$${result.cashOut}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Text(
                    "${isProfit ? '+' : ''}${result.profit}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isProfit ? Colors.green : Colors.redAccent,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}