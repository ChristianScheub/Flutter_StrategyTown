import 'package:flutter/material.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/services/score_service.dart';

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

  Widget _buildPlayerScores(BuildContext context) {
    final allPlayerPoints = ScoreService.getAllPlayerPoints(gameState);
    final playerRanking = ScoreService.getPlayerRanking(gameState);
    
    if (allPlayerPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Show top 3 players or all if less than 4 players
        ...playerRanking.take(3).map((entry) {
          final playerId = entry.key;
          final points = entry.value;
          final player = gameState.playerManager.getPlayer(playerId);
          
          if (player == null) return const SizedBox.shrink();
          
          final isLeader = playerId == ScoreService.getLeadingPlayer(gameState);
          final isHuman = player.isHuman;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHuman ? Icons.person : Icons.computer,
                  color: isHuman ? Colors.blue : Colors.red.shade700,
                  size: 16,
                ),
                const SizedBox(width: 4),
                if (isLeader)
                  Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '${player.name}: $points',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                      color: isLeader ? Colors.amber.shade700 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        // Show "..." if there are more than 3 players
        if (playerRanking.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '... and ${playerRanking.length - 3} more',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
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
          const SizedBox(height: 4),
          
          // Current Player Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: gameState.isCurrentPlayerHuman 
                  ? Colors.blue.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: gameState.isCurrentPlayerHuman 
                    ? Colors.blue 
                    : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  gameState.isCurrentPlayerHuman ? Icons.person : Icons.computer,
                  color: gameState.isCurrentPlayerHuman ? Colors.blue : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Current: ${gameState.currentPlayerId}',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: gameState.isCurrentPlayerHuman ? Colors.blue.shade700 : Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Player scores section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  'Player Scores',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _buildPlayerScores(context),
              ],
            ),
          ),
          
          if (gameState.enemyFaction != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onJumpToEnemyHQ,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
          ],
          
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