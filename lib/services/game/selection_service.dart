import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/combat/combat_helper.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';

class SelectionService extends BaseGameService {
  SelectionService(GameStateNotifier notifier) : super(notifier);

  void selectUnit(String unitId) {
    updateState(state.copyWith(
      selectedUnitId: unitId,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    ));
  }

  void selectBuilding(String buildingId) {
    updateState(state.copyWith(
      selectedUnitId: null,
      selectedBuildingId: buildingId,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    ));
  }

  void selectTile(Position position) {
    // Check if we should attack or move
    if (state.selectedUnitId != null && selectedUnit != null) {
      final selectedUnit = this.selectedUnit!;
      
      // Check for enemy attack
      if (state.enemyFaction != null && 
          CombatHelper.canAttackEnemyAt(state, selectedUnit, position)) {
        _handleAttack(position);
        return;
      }
      
      // Check for movement
      if (state.isValidMovePosition(position)) {
        _handleMovement(position);
        return;
      }
      
      // Keep unit selected if clicking on its own position
      if (selectedUnit.position == position) {
        return;
      }
    }

    // Default tile selection
    updateState(state.copyWith(
      selectedTilePosition: position,
      selectedUnitId: null,
      selectedBuildingId: null,
      buildingToBuild: null,
      unitToTrain: null,
    ));
  }

  void clearSelection() {
    updateState(state.copyWith(
      selectedUnitId: null,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    ));
  }

  void selectBuildingToBuild(BuildingType type) {
    updateState(state.copyWith(buildingToBuild: type));
  }

  void selectUnitToTrain(UnitType type) {
    updateState(state.copyWith(unitToTrain: type));
  }

  void _handleAttack(Position targetPosition) {
    final unit = selectedUnit;
    if (unit == null || !CombatHelper.canAttackEnemyAt(state, unit, targetPosition)) {
      return;
    }
    
    final updatedState = CombatHelper.attackEnemyAt(state, unit, targetPosition);
    updateState(updatedState);
  }

  void _handleMovement(Position newPosition) {
    final unit = selectedUnit;
    if (unit == null || !unit.canAct) return;

    final tile = state.map.getTile(newPosition);
    if (!tile.isWalkable) return;

    final distance = unit.position.manhattanDistance(newPosition);
    if (distance > unit.actionsLeft) return;

    final newUnits = state.units.map((u) {
      if (u.id == unit.id) {
        return u.copyWith(
          position: newPosition,
          actionsLeft: u.actionsLeft - distance
        );
      }
      return u;
    }).toList();

    updateState(state.copyWith(units: newUnits));
  }
}
