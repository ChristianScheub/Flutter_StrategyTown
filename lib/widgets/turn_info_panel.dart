import 'package:flutter/material.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';

class TurnInfoPanel extends StatelessWidget {
  final GameState gameState;
  final int turn;
  final VoidCallback onNextTurn;
  final VoidCallback onJumpToFirstCity;
  final VoidCallback? onJumpToEnemyHQ;

  const TurnInfoPanel({
    super.key,
    required this.gameState,
    required this.turn,
    required this.onNextTurn,
    required this.onJumpToFirstCity,
    this.onJumpToEnemyHQ,
  });

  // Prüfen, ob es Stadtzentren gibt
  bool _hasCities() {
    return gameState.buildings.any((building) => building.type == BuildingType.cityCenter);
  }
  
  // Konvertiert die interne Strategie-Bezeichnung in einen benutzerfreundlichen Text
  String _getStrategyDescription(String strategy) {
    switch (strategy) {
      case 'recruit':
        return 'Training Units';
      case 'attack':
        return 'Attacking';
      case 'expand':
        return 'Expanding Territory';
      case 'build':
        return 'Building';
      default:
        return 'Planning';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Turn $turn',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('Player: ${gameState.playerPoints}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Icon(Icons.computer, color: Colors.red.shade700, size: 18),
              const SizedBox(width: 4),
              Text('KI: ${gameState.aiPoints}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (gameState.enemyFaction != null)
            GestureDetector(
              onTap: onJumpToEnemyHQ,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  border: Border.all(color: Colors.red.shade800, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Enemy Civilization: ${gameState.enemyFaction!.name}',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (onJumpToEnemyHQ != null)
                          Icon(
                            Icons.my_location,
                            size: 12,
                            color: Colors.red.shade800,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Forces: ${gameState.enemyFaction!.units.length} units, ${gameState.enemyFaction!.buildings.length} buildings',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 11,
                      ),
                    ),
                    if (gameState.enemyFaction!.currentStrategy != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 12,
                            color: Colors.red.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStrategyDescription(gameState.enemyFaction!.currentStrategy!),
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 12,
                          color: Colors.red.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Threat: ${gameState.enemyFaction!.aggressiveness}/10',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: _hasCities() ? onJumpToFirstCity : null,
                    icon: const Text('🏛️'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasCities() ? Colors.green : Colors.grey,
                      minimumSize: const Size(0, 36),
                    ),
                    label: Text(
                      'First City',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: onNextTurn,
                    icon: const Text('⏭️'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(0, 36),
                    ),
                    label: Text(
                      'End Turn',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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