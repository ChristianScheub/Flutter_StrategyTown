import 'package:flutter_sim_city/models/buildings/building_abilities.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';
import 'package:flutter_sim_city/services/score_service.dart';

class UnitTrainingService extends BaseGameService {
  UnitTrainingService(GameStateNotifier notifier) : super(notifier);

  void trainUnit(UnitType unitType) {
    final building = selectedBuilding;
    if (building == null || !(building is UnitTrainer)) return;
    
    final trainer = building as UnitTrainer;
    if (!trainer.canTrainUnit(unitType)) return;
    
    final trainingCost = trainer.getTrainingCost(unitType);
    
    // Check if the player has enough resources for all required types
    final currentPlayerResources = state.getPlayerResources(state.currentPlayerId);
    
    // Check for each resource type if the player has enough
    bool hasEnoughResources = true;
    for (final entry in trainingCost.entries) {
      final resourceType = entry.key;
      final cost = entry.value;
      if (cost > 0 && !currentPlayerResources.hasEnough(resourceType, cost)) {
        hasEnoughResources = false;
        break;
      }
    }
    
    if (!hasEnoughResources) {
      return;
    }
    
    // Create unit with current player's ownerID
    final newUnit = UnitFactory.createUnit(unitType, building.position, ownerID: state.currentPlayerId);
    
    // Update current player's resources by subtracting all costs
    var newPlayerResources = currentPlayerResources;
    for (final entry in trainingCost.entries) {
      final resourceType = entry.key;
      final cost = entry.value;
      if (cost > 0) {
        newPlayerResources = newPlayerResources.subtract(resourceType, cost);
      }
    }
    
    final updatedState = state.updatePlayerResources(state.currentPlayerId, newPlayerResources);
    
    updateState(ScoreService.addUnitTrainingPoints(
      updatedState.copyWith(
        units: [...state.units, newUnit],
        unitToTrain: null,
      ),
      state.currentPlayerId
    ));
  }
}
