import 'package:game_core/src/models/buildings/barracks.dart';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/buildings/building_abilities.dart';
import 'package:game_core/src/models/buildings/defensive_tower.dart';
import 'package:game_core/src/models/buildings/farm.dart';
import 'package:game_core/src/models/buildings/lumber_camp.dart';
import 'package:game_core/src/models/buildings/mine.dart';
import 'package:game_core/src/models/buildings/wall.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/map/tile.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/units/civilian/architect.dart';
import 'package:game_core/src/models/units/civilian/farmer.dart';
import 'package:game_core/src/models/units/civilian/lumberjack.dart';
import 'package:game_core/src/models/units/civilian/miner.dart';
import 'package:game_core/src/models/units/military/soldier.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/models/units/unit_abilities.dart';
import 'package:game_core/src/services/game/base_game_service.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';
import 'package:game_core/src/services/score_service.dart';

class BuildingService extends BaseGameService {
  BuildingService(GameStateNotifier notifier) : super(notifier);

  void buildBuilding(Position position) {
    final buildingType = state.buildingToBuild;
    if (buildingType == null) return;

    final tile = state.map.getTile(position);
    if (!tile.canBuildOn) return;

    // Check safe distance from enemies
    final enemyBuildings = state.enemyFaction?.buildings ?? [];
    final dummyBuilding = Building.create(buildingType, position, ownerID: state.currentPlayerId);
    if (!dummyBuilding.isWithinSafeDistance(position, enemyBuildings)) {
      return;
    }

    // Check current player's resources instead of global resources
    final buildingCost = baseBuildingCosts[buildingType] ?? {};
    final currentPlayerResources = state.getPlayerResources(state.currentPlayerId);
    if (!currentPlayerResources.hasEnoughMultiple(buildingCost)) return;

    // Create and place building with current player's ownerID
    final newBuilding = state.createBuilding(buildingType, position, ownerID: state.currentPlayerId);
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Update current player's resources
    final newPlayerResources = currentPlayerResources.subtractMultiple(buildingCost);
    final updatedState = state.updatePlayerResources(state.currentPlayerId, newPlayerResources);
    
    updateState(ScoreService.addBuildingUpgradePoints(
      updatedState.copyWith(
        buildings: [...state.buildings, newBuilding],
        buildingToBuild: null,
      ),
      newBuilding,
      state.currentPlayerId
    ));
  }

  void upgradeBuilding() {
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

  // Add specialized building methods that were missing
  void buildFarm() {
    _buildWithSpecializedUnit<Farmer>(
      BuildingType.farm,
      (position) => Farm.create(position, ownerID: state.currentPlayerId),
      consumeUnit: true
    );
  }

  void buildLumberCamp() {
    _buildWithSpecializedUnit<Lumberjack>(
      BuildingType.lumberCamp,
      (position) => LumberCamp.create(position, ownerID: state.currentPlayerId),
      consumeUnit: true
    );
  }

  void buildMine() {
    final unit = selectedUnit;
    if (unit == null || !(unit is Miner)) return;
    
    final tile = state.map.getTile(unit.position);
    final isIronMine = tile.resourceType == ResourceType.iron;
    
    _buildWithSpecializedUnit<Miner>(
      BuildingType.mine,
      (position) => Mine.create(position, isIronMine: isIronMine, ownerID: state.currentPlayerId),
      consumeUnit: true
    );
  }

  void buildBarracks() {
    _buildWithSpecializedUnit<Commander>(
      BuildingType.barracks,
      (position) => Barracks.create(position, ownerID: state.currentPlayerId),
      actionCost: 2
    );
  }

  void buildDefensiveTower() {
    _buildWithSpecializedUnit<Architect>(
      BuildingType.defensiveTower,
      (position) => DefensiveTower.create(position, ownerID: state.currentPlayerId),
      getActionCost: (unit) => (unit as Architect).getBuildActionCost(BuildingType.defensiveTower)
    );
  }

  void buildWall() {
    _buildWithSpecializedUnit<Architect>(
      BuildingType.wall,
      (position) => Wall.create(position, ownerID: state.currentPlayerId),
      getActionCost: (unit) => (unit as Architect).getBuildActionCost(BuildingType.wall)
    );
  }

  // Resource management methods
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
    
    // Update current player's resources instead of global resources
    final currentPlayerResources = state.getPlayerResources(unit.ownerID);
    final newPlayerResources = currentPlayerResources.add(resourceType, actualHarvest);
    final updatedState = state.updatePlayerResources(unit.ownerID, newPlayerResources);
    
    print('Ernte: $actualHarvest ${resourceType.toString().split('.').last} für Spieler ${unit.ownerID}');
    
    updateState(updatedState.copyWith(
      units: newUnits,
    ));
  }

  void repairWall() {
    final building = selectedBuilding;
    if (building == null || building.type != BuildingType.wall) return;
    
    final wall = building as Wall;
    if (wall.currentHealth >= wall.maxHealth) return;
    
    final repairCost = wall.getRepairCost();
    if (!hasEnoughResources(repairCost)) return;
    
    final updatedBuildings = state.buildings.map((b) {
      return b.id == wall.id ? wall.repair() : b;
    }).toList();
    
    final newState = subtractResources(state, repairCost);
    
    print("Wall repaired to full health!");
    
    updateState(newState.copyWith(buildings: updatedBuildings));
  }

  void _buildWithSpecializedUnit<T>(
    BuildingType buildingType,
    Building Function(Position) createBuilding, {
    bool consumeUnit = false,
    int? actionCost,
    int Function(Unit)? getActionCost,
  }) {
    final unit = selectedUnit;
    if (unit == null || unit is! T || !unit.canAct) return;
    
    final builderUnit = unit as BuilderUnit;
    final tile = state.map.getTile(unit.position);
    
    if (!builderUnit.canBuild(buildingType, tile as Tile)) return;
    
    final buildingCost = baseBuildingCosts[buildingType] ?? {};
    final currentPlayerResources = state.getPlayerResources(state.currentPlayerId);
    if (!currentPlayerResources.hasEnoughMultiple(buildingCost)) return;
    
    final newBuilding = createBuilding(unit.position);
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    List<Unit> updatedUnits;
    if (consumeUnit) {
      updatedUnits = state.units.where((u) => u.id != unit.id).toList();
    } else {
      final cost = actionCost ?? getActionCost?.call(unit) ?? 1;
      updatedUnits = state.units.map((u) {
        return u.id == unit.id ? u.copyWith(actionsLeft: u.actionsLeft - cost) : u;
      }).toList();
    }
    
    final newPlayerResources = currentPlayerResources.subtractMultiple(buildingCost);
    final updatedState = state.updatePlayerResources(state.currentPlayerId, newPlayerResources);
    
    updateState(ScoreService.addBuildingUpgradePoints(
      updatedState.copyWith(
        buildings: [...state.buildings, newBuilding],
        units: updatedUnits,
        selectedUnitId: consumeUnit ? null : state.selectedUnitId,
      ),
      newBuilding,
      unit.ownerID
    ));
  }
}
