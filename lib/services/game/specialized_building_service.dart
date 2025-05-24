import 'package:flutter_sim_city/models/buildings/barracks.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/building_abilities.dart';
import 'package:flutter_sim_city/models/buildings/defensive_tower.dart';
import 'package:flutter_sim_city/models/buildings/farm.dart';
import 'package:flutter_sim_city/models/buildings/lumber_camp.dart';
import 'package:flutter_sim_city/models/buildings/mine.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/civilian/architect.dart';
import 'package:flutter_sim_city/models/units/civilian/farmer.dart';
import 'package:flutter_sim_city/models/units/civilian/lumberjack.dart';
import 'package:flutter_sim_city/models/units/civilian/miner.dart';
import 'package:flutter_sim_city/models/units/military/soldier.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';
import 'package:flutter_sim_city/services/score_service.dart';

class SpecializedBuildingService extends BaseGameService {
  SpecializedBuildingService(GameStateNotifier notifier) : super(notifier);

  void foundCity() {
    final unit = selectedUnit;
    if (unit == null || !(unit is SettlerCapable) || !unit.canAct) return;
    
    final settlerCapable = unit as SettlerCapable;
    if (!settlerCapable.canFoundCity()) return;
    
    final tile = state.map.getTile(unit.position);
    if (!tile.canBuildOn) return;
    
    final cityCenter = state.createBuilding(BuildingType.cityCenter, unit.position);
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    final newUnits = state.units.where((u) => u.id != unit.id).toList();
    
    updateState(ScoreService.addCityFoundationPoints(
      state.copyWith(
        units: newUnits,
        buildings: [...state.buildings, cityCenter],
        selectedUnitId: null,
      ),
      "player"
    ));
  }

  void buildFarm() {
    _buildWithSpecializedUnit<Farmer>(
      BuildingType.farm,
      (position) => Farm.create(position, ownerID: "player"),
      consumeUnit: true
    );
  }

  void buildLumberCamp() {
    _buildWithSpecializedUnit<Lumberjack>(
      BuildingType.lumberCamp,
      (position) => LumberCamp.create(position, ownerID: "player"),
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
      (position) => Mine.create(position, isIronMine: isIronMine, ownerID: "player"),
      consumeUnit: true
    );
  }

  void buildBarracks() {
    _buildWithSpecializedUnit<Commander>(
      BuildingType.barracks,
      (position) => Barracks.create(position, ownerID: "player"),
      actionCost: 2
    );
  }

  void buildDefensiveTower() {
    _buildWithSpecializedUnit<Architect>(
      BuildingType.defensiveTower,
      (position) => DefensiveTower.create(position, ownerID: "player"),
      getActionCost: (unit) => (unit as Architect).getBuildActionCost(BuildingType.defensiveTower)
    );
  }

  void buildWall() {
    _buildWithSpecializedUnit<Architect>(
      BuildingType.wall,
      (position) => Wall.create(position, ownerID: "player"),
      getActionCost: (unit) => (unit as Architect).getBuildActionCost(BuildingType.wall)
    );
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
    if (!hasEnoughResources(buildingCost)) return;
    
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
    
    final newState = subtractResources(state, buildingCost);
    
    updateState(ScoreService.addBuildingUpgradePoints(
      newState.copyWith(
        buildings: [...state.buildings, newBuilding],
        units: updatedUnits,
        selectedUnitId: consumeUnit ? null : state.selectedUnitId,
      ),
      newBuilding,
      "player"
    ));
  }
}
