import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';

/// Base class for all game services providing common functionality
abstract class BaseGameService {
  final GameStateNotifier _notifier;

  BaseGameService(this._notifier);

  /// Get current game state
  GameState get state => _notifier.state;

  /// Update game state
  void updateState(GameState newState) {
    _notifier.updateState(newState);
  }

  /// Get selected unit safely
  Unit? get selectedUnit => state.selectedUnit;

  /// Get selected building safely  
  Building? get selectedBuilding => state.selectedBuilding;

  /// Check if player has enough resources
  bool hasEnoughResources(Map<ResourceType, int> cost) {
    return state.resources.hasEnoughMultiple(cost);
  }

  /// Update resources after spending
  GameState subtractResources(GameState currentState, Map<ResourceType, int> cost) {
    return currentState.copyWith(
      resources: currentState.resources.subtractMultiple(cost)
    );
  }
}
