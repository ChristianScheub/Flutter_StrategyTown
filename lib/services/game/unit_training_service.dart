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
    final foodCost = trainingCost[ResourceType.food] ?? 0;
    
    if (foodCost <= 0 || !state.resources.hasEnough(ResourceType.food, foodCost)) {
      return;
    }
    
    final newUnit = UnitFactory.createUnit(unitType, building.position);
    final newResources = state.resources.subtract(ResourceType.food, foodCost);
    
    updateState(ScoreService.addUnitTrainingPoints(
      state.copyWith(
        units: [...state.units, newUnit],
        resources: newResources,
        unitToTrain: null,
      ),
      "player"
    ));
  }
}
