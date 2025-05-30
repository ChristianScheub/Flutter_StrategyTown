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

class SpecializedBuildingService extends BaseGameService {
  SpecializedBuildingService(GameStateNotifier notifier) : super(notifier);

  void foundCity() {
    final unit = selectedUnit;
    if (unit == null || !(unit is SettlerCapable) || !unit.canAct) return;
    
    final settlerCapable = unit as SettlerCapable;
    if (!settlerCapable.canFoundCity()) return;
    
    final tile = state.map.getTile(unit.position);
    if (!tile.canBuildOn) return;
    
    final cityCenter = state.createBuilding(BuildingType.cityCenter, unit.position, ownerID: unit.ownerID);
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    final newUnits = state.units.where((u) => u.id != unit.id).toList();
    
    updateState(ScoreService.addCityFoundationPoints(
      state.copyWith(
        units: newUnits,
        buildings: [...state.buildings, cityCenter],
        selectedUnitId: null,
      ),
      unit.ownerID
    ));
  }

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
    _buildWithSpecializedUnit<Miner>(
      BuildingType.mine,
      (position) => Mine.create(position, ownerID: state.currentPlayerId),
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
