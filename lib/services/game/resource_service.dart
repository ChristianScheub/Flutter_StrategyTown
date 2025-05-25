import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';
import 'package:flutter_sim_city/services/score_service.dart';

class ResourceService extends BaseGameService {
  ResourceService(GameStateNotifier notifier) : super(notifier);

  void harvestResource() {
    final unit = selectedUnit;
    if (unit == null || !unit.canAct || !(unit is HarvesterUnit)) return;
    
    final harvesterUnit = unit as HarvesterUnit;
    final tile = state.map.getTile(unit.position);
    
    if (tile.resourceType == null || tile.resourceAmount <= 0) return;
    
    final resourceType = tile.resourceType!;
    if (!harvesterUnit.canHarvest(resourceType, tile as Tile)) return;
    
    final harvestAmount = harvesterUnit.getHarvestAmount(resourceType);
    final actualHarvest = tile.resourceAmount < harvestAmount 
        ? tile.resourceAmount 
        : harvestAmount;
    
    // Update tile
    final newResourceAmount = tile.resourceAmount - actualHarvest;
    final newTile = tile.copyWith(
      resourceAmount: newResourceAmount,
      resourceType: newResourceAmount <= 0 ? null : resourceType,
    );
    state.map.setTile(newTile);
    
    // Update unit
    final actionCost = harvesterUnit.getHarvestActionCost(resourceType);
    final newUnits = state.units.map((u) {
      return u.id == unit.id ? u.copyWith(actionsLeft: u.actionsLeft - actionCost) : u;
    }).toList();
    
    // Update the owning player's resources instead of global resources
    final currentPlayerResources = state.getPlayerResources(unit.ownerID);
    final newPlayerResources = currentPlayerResources.add(resourceType, actualHarvest);
    final updatedState = state.updatePlayerResources(unit.ownerID, newPlayerResources);
    
    print('Ernte: $actualHarvest ${resourceType.toString().split('.').last} für Spieler ${unit.ownerID}');
    
    updateState(updatedState.copyWith(
      units: newUnits,
    ));
  }  void upgradeBuilding() {
    final building = selectedBuilding;
    if (building == null) return;

    final upgradeCost = building.getUpgradeCost();
    final currentPlayerResources = state.getPlayerResources(state.currentPlayerId);
    if (!currentPlayerResources.hasEnoughMultiple(upgradeCost)) return;

    final updatedBuildings = state.buildings.map((b) {
      return b.id == building.id ? b.upgrade() : b;
    }).toList();

    final newPlayerResources = currentPlayerResources.subtractMultiple(upgradeCost);
    final updatedState = state.updatePlayerResources(state.currentPlayerId, newPlayerResources);

    updateState(ScoreService.addBuildingUpgradePoints(
      updatedState.copyWith(buildings: updatedBuildings),
      building,
      state.currentPlayerId
    ));
  }

  void repairWall() {
    final building = selectedBuilding;
    if (building == null || building.type != BuildingType.wall) return;
    
    final wall = building as Wall;
    if (wall.currentHealth >= wall.maxHealth) return;
    
    final repairCost = wall.getRepairCost();
    final currentPlayerResources = state.getPlayerResources(state.currentPlayerId);
    if (!currentPlayerResources.hasEnoughMultiple(repairCost)) return;
    
    final updatedBuildings = state.buildings.map((b) {
      return b.id == wall.id ? wall.repair() : b;
    }).toList();
    
    final newPlayerResources = currentPlayerResources.subtractMultiple(repairCost);
    final updatedState = state.updatePlayerResources(state.currentPlayerId, newPlayerResources);
    
    print("Wall repaired to full health!");
    
    updateState(updatedState.copyWith(buildings: updatedBuildings));
  }
}
