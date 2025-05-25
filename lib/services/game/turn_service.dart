import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/defensive_tower.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/services/ai/ai_service.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';

class TurnService extends BaseGameService {
  TurnService(GameStateNotifier notifier) : super(notifier);

  void nextTurn() {
    // Capture initial state for notifications
    final initialPlayerUnits = state.currentPlayerUnits.length;
    final initialPlayerBuildings = state.currentPlayerBuildings.length;
    final initialEnemyFaction = state.enemyFaction;
    final initialEnemyUnits = initialEnemyFaction?.units.length ?? 0;
    final initialEnemyBuildings = initialEnemyFaction?.buildings.length ?? 0;
    
    // Process defensive tower attacks
    var updatedState = _processDefensiveTowerAttacks(state);
    
    // Process turn - with multiplayer mode always on, we don't automatically switch players
    // Players will be switched manually via UI controls
    updatedState = updatedState.nextTurn();
    
    // Calculate AI difficulty scaling
    double difficultyScale = _calculateDifficultyScale(updatedState.turn);
    
    // Apply difficulty scaling with extra resources
    if (updatedState.enemyFaction != null && difficultyScale > 1.0) {
      updatedState = _enhanceEnemyResources(updatedState, difficultyScale);
    }
    
    // Process enemy AI turn
    final aiService = AIService();
    updatedState = aiService.processEnemyTurn(updatedState);
    
    // Show battle notifications
    _showBattleNotifications(
      initialPlayerUnits, initialPlayerBuildings,
      initialEnemyUnits, initialEnemyBuildings,
      updatedState, initialEnemyFaction
    );
    
    updateState(updatedState);
  }

  double _calculateDifficultyScale(int turn) {
    if (turn <= 3) return 1.0;
    
    double scale = 1.0 + ((turn - 3) * 0.05);
    return scale > 2.0 ? 2.0 : scale;
  }

  GameState _enhanceEnemyResources(GameState state, double difficultyScale) {
    final extraFood = (10 * difficultyScale).round();
    final extraWood = (5 * difficultyScale).round();
    final extraStone = (3 * difficultyScale).round();
    
    final enhancedResources = state.enemyFaction!.resources
        .add(ResourceType.food, extraFood)
        .add(ResourceType.wood, extraWood)
        .add(ResourceType.stone, extraStone);
    
    return state.copyWith(
      enemyFaction: state.enemyFaction!.copyWith(resources: enhancedResources)
    );
  }

  GameState _processDefensiveTowerAttacks(GameState currentState) {
    var updatedState = currentState;
    
    // Player towers
    for (final building in updatedState.buildings) {
      if (building.type == BuildingType.defensiveTower) {
        final defensiveTower = building as DefensiveTower;
        updatedState = defensiveTower.performAutoAttack(updatedState, false);
      }
    }
    
    // Enemy towers
    if (updatedState.enemyFaction != null) {
      for (final building in updatedState.enemyFaction!.buildings) {
        if (building.type == BuildingType.defensiveTower) {
          final defensiveTower = building as DefensiveTower;
          updatedState = defensiveTower.performAutoAttack(updatedState, true);
        }
      }
    }
    
    return updatedState;
  }

  void _showBattleNotifications(
    int initialPlayerUnits, int initialPlayerBuildings,
    int initialEnemyUnits, int initialEnemyBuildings,
    GameState finalState, dynamic initialEnemyFaction
  ) {
    final finalPlayerUnits = finalState.units.length;
    final finalPlayerBuildings = finalState.buildings.length;
    final finalEnemyUnits = finalState.enemyFaction?.units.length ?? 0;
    final finalEnemyBuildings = finalState.enemyFaction?.buildings.length ?? 0;
    
    if (finalPlayerUnits < initialPlayerUnits) {
      print('⚠️ ALERT: Enemy destroyed ${initialPlayerUnits - finalPlayerUnits} of your units!');
    }
    if (finalPlayerBuildings < initialPlayerBuildings) {
      print('⚠️ ALERT: Enemy captured ${initialPlayerBuildings - finalPlayerBuildings} of your buildings!');
    }
    if (finalEnemyUnits < initialEnemyUnits) {
      print('✓ SUCCESS: Your forces destroyed ${initialEnemyUnits - finalEnemyUnits} enemy units!');
    }
    if (finalEnemyBuildings < initialEnemyBuildings) {
      print('✓ SUCCESS: Your forces captured ${initialEnemyBuildings - finalEnemyBuildings} enemy buildings!');
    }
    if (finalState.enemyFaction != null && initialEnemyFaction == null) {
      print('⚠️ ALERT: A new enemy civilization has appeared!');
    }
  }
}
