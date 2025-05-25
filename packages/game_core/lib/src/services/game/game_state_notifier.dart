import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/models/units/unit_abilities.dart';
import 'package:game_core/src/services/game/selection_service.dart';
import 'package:game_core/src/services/game/building_service.dart';
import 'package:game_core/src/services/game/unit_training_service.dart';
import 'package:game_core/src/services/game/turn_service.dart';
import 'package:game_core/src/services/game/camera_service.dart';
import 'package:game_core/src/services/game/combat_service.dart';
import 'package:game_core/src/services/score_service.dart';


final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(ref),
);

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(this.ref) : super(GameState.empty()) {
    _initializeServices();
  }

  final Ref ref;
  
  // Service instances
  late final SelectionService _selectionService;
  late final BuildingService _buildingService;
  late final UnitTrainingService _unitTrainingService;
  late final TurnService _turnService;
  late final CameraService _cameraService;
  late final CombatService _combatService;

  void _initializeServices() {
    _selectionService = SelectionService(this);
    _buildingService = BuildingService(this);
    _unitTrainingService = UnitTrainingService(this);
    _turnService = TurnService(this);
    _cameraService = CameraService(this, ref);
    _combatService = CombatService(this);
  }

  // State management
  void updateState(GameState newState) {
    state = newState;
  }

  // Load and save operations
  void loadGameState(GameState gameState) {
    state = gameState;
  }

  // Delegate to services
  void moveCamera(Position newPosition) => _cameraService.moveCamera(newPosition);
  void jumpToFirstCity() => _cameraService.jumpToFirstCity();
  void jumpToEnemyHeadquarters() => _cameraService.jumpToEnemyHeadquarters();
  void jumpToFirstSettler() => _cameraService.jumpToFirstSettler();
  
  void selectUnit(String unitId) => _selectionService.selectUnit(unitId);
  void selectBuilding(String buildingId) => _selectionService.selectBuilding(buildingId);
  void selectTile(Position position) => _selectionService.selectTile(position);
  void clearSelection() => _selectionService.clearSelection();
  
  void selectBuildingToBuild(BuildingType type) => _selectionService.selectBuildingToBuild(type);
  void selectUnitToTrain(UnitType type) => _selectionService.selectUnitToTrain(type);
  
  void buildBuilding(Position position) => _buildingService.buildBuilding(position);
  void trainUnit(UnitType unitType) => _unitTrainingService.trainUnit(unitType);
  
  void nextTurn() => _turnService.nextTurn();
  void attackEnemyTarget(Position targetPosition) => _combatService.attackEnemyTarget(targetPosition);

  // Add missing specialized methods - delegate to services
  void foundCity() {
    final unit = state.selectedUnit;
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

  void harvestResource() => _buildingService.harvestResource();
  void upgradeBuilding() => _buildingService.upgradeBuilding();
  void repairWall() => _buildingService.repairWall();
  
  void buildFarm() => _buildingService.buildFarm();
  void buildLumberCamp() => _buildingService.buildLumberCamp();
  void buildMine() => _buildingService.buildMine();
  void buildBarracks() => _buildingService.buildBarracks();
  void buildDefensiveTower() => _buildingService.buildDefensiveTower();
  void buildWall() => _buildingService.buildWall();

  void selectUnitForDetails(String unitId) => _selectionService.selectUnitForDetails(unitId);
}
