import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/farm.dart';
import 'package:flutter_sim_city/models/buildings/lumber_camp.dart';
import 'package:flutter_sim_city/models/buildings/mine.dart';
import 'package:flutter_sim_city/models/buildings/barracks.dart';
import 'package:flutter_sim_city/models/buildings/defensive_tower.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/models/buildings/building_abilities.dart';
import 'package:flutter_sim_city/models/combat/combat_helper.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/services/ai/ai_service.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:flutter_sim_city/models/units/civilian/farmer.dart';
import 'package:flutter_sim_city/models/units/civilian/lumberjack.dart';
import 'package:flutter_sim_city/models/units/civilian/miner.dart';
import 'package:flutter_sim_city/models/units/military/soldier.dart';
import 'package:flutter_sim_city/models/units/civilian/architect.dart';
import 'package:flutter_sim_city/widgets/game_map.dart';
import 'package:flutter_sim_city/services/save_game_service.dart';
import 'package:flutter_sim_city/services/score_service.dart';

// Provider for the GameMapController
final gameMapControllerProvider = StateProvider<GameMapController?>((ref) {
  return null;
});

final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>(
  (ref) => GameStateNotifier(ref),
);

class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier(this.ref) : super(GameState.initial());

  final Ref ref;
  
    // Load a game state
  void loadGameState(GameState gameState) {
    state = gameState;
  }
  
  // Save the current game with optional custom name
  Future<bool> saveGame({String? name}) async {
    try {
      return await SaveGameService.saveGame(state, name: name);
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  // Camera movement
  void moveCamera(Position newPosition) {
    state = state.copyWith(cameraPosition: newPosition);
  }
  
  // Find the position of the first city center
  Position? getFirstCityPosition() {
    // Find all city centers
    final cityCenters = state.buildings.where(
      (building) => building.type == BuildingType.cityCenter
    ).toList();
    
    // Debug-Ausgabe
    print('Gefundene Städte: ${cityCenters.length}');
    if (cityCenters.isNotEmpty) {
      final firstCityPos = cityCenters.first.position;
      print('Erste Stadt Position: (${firstCityPos.x}, ${firstCityPos.y})');
      return firstCityPos;
    }
    
    print('Keine Städte gefunden!');
    return null;
  }
  
  // Jump to the first city
  void jumpToFirstCity() {
    final firstCityPosition = getFirstCityPosition();
    if (firstCityPosition != null) {
      // Direkt die Kameraposition aktualisieren
      moveCamera(firstCityPosition);
      
      // Zusätzlich: Setze die selectedBuildingId auf das erste Stadtzentrum,
      // um es hervorzuheben und dem Benutzer zu helfen, es zu finden
      final cityCenters = state.buildings.where(
        (building) => building.type == BuildingType.cityCenter
      ).toList();
      
      if (cityCenters.isNotEmpty) {
        // Wähle das erste Stadtzentrum aus
        selectBuilding(cityCenters.first.id);
        
        // Use the GameMapController to jump the camera
        final controller = ref.read(gameMapControllerProvider);
        if (controller != null && controller.jumpToPosition != null) {
          controller.jumpToPosition!(firstCityPosition);
          print('GameMap controller used to jump to first city position: (${firstCityPosition.x}, ${firstCityPosition.y})');
        } else {
          print('GameMap controller not initialized or jumpToPosition is null');
        }
        
        // Debug-Ausgabe
        print('Stadt ausgewählt! ID: ${cityCenters.first.id}, Position: (${firstCityPosition.x}, ${firstCityPosition.y})');
      }
    }
  }

  // Jump to the enemy faction's headquarters
  void jumpToEnemyHeadquarters() {
    if (state.enemyFaction != null && state.enemyFaction!.headquarters != null) {
      final headquartersPosition = state.enemyFaction!.headquarters!;
      
      // Update camera position
      moveCamera(headquartersPosition);
      
      // Use the GameMapController to jump the camera
      final controller = ref.read(gameMapControllerProvider);
      if (controller != null && controller.jumpToPosition != null) {
        controller.jumpToPosition!(headquartersPosition);
        print('GameMap controller used to jump to enemy headquarters position: (${headquartersPosition.x}, ${headquartersPosition.y})');
      } else {
        print('GameMap controller not initialized or jumpToPosition is null');
      }
    }
  }

  // Selection
  void selectUnit(String unitId) {
    // Deselect any other selections
    state = state.copyWith(
      selectedUnitId: unitId,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    );
  }

  void selectBuilding(String buildingId) {
    // Deselect any other selections
    state = state.copyWith(
      selectedUnitId: null,
      selectedBuildingId: buildingId,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    );
  }

  void selectTile(Position position) {
    // Wenn eine Einheit ausgewählt ist und wir klicken auf eine feindliche Einheit/Gebäude
    if (state.selectedUnitId != null && state.selectedUnit != null) {
      final selectedUnit = state.selectedUnit!;
      
      // Prüfe, ob an der Position ein feindliches Ziel ist
      if (state.enemyFaction != null && CombatHelper.canAttackEnemyAt(state, selectedUnit, position)) {
        // Führe einen Angriff aus
        attackEnemyTarget(position);
        return;
      }
    }
    
    // If a unit is selected and we click on a valid move position, move the unit
    if (state.selectedUnitId != null && state.isValidMovePosition(position)) {
      _moveSelectedUnit(position);
      return;
    }
    
    // If a unit is selected and we click on its own position, keep it selected
    if (state.selectedUnitId != null) {
      final selectedUnit = state.selectedUnit;
      if (selectedUnit != null && selectedUnit.position == position) {
        // Die Einheit ist bereits ausgewählt und wir klicken auf ihre Position
        // Wir halten die Einheit weiterhin ausgewählt
        return;
      }
    }

    // Otherwise, select the tile
    state = state.copyWith(
      selectedTilePosition: position,
      selectedUnitId: null,
      selectedBuildingId: null,
      buildingToBuild: null,
      unitToTrain: null,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedUnitId: null,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    );
  }

  // Unit movement
  void _moveSelectedUnit(Position newPosition) {
    final selectedUnit = state.selectedUnit;
    if (selectedUnit == null || !selectedUnit.canAct) return;

    final tile = state.map.getTile(newPosition);
    if (!tile.isWalkable) return;

    // Berechne die Distanz für die Bewegung (Manhattan-Distanz)
    final distance = selectedUnit.position.manhattanDistance(newPosition);
    
    // Prüfe, ob die Einheit genügend Aktionspunkte hat
    if (distance > selectedUnit.actionsLeft) return;

    final newUnits = state.units.map((unit) {
      if (unit.id == selectedUnit.id) {
        // Bewege die Einheit und verbrauche entsprechend viele Aktionspunkte
        return unit.copyWith(
          position: newPosition,
          actionsLeft: unit.actionsLeft - distance
        );
      }
      return unit;
    }).toList();

    state = state.copyWith(units: newUnits);
  }

  // Building and training
  void selectBuildingToBuild(BuildingType type) {
    state = state.copyWith(buildingToBuild: type);
  }

  void selectUnitToTrain(UnitType type) {
    state = state.copyWith(unitToTrain: type);
  }

  void buildBuilding(Position position) {
    final buildingType = state.buildingToBuild;
    if (buildingType == null) return;

    final tile = state.map.getTile(position);
    if (!tile.canBuildOn) return;

    // Check if the position is within safe distance from enemy cities
    final enemyBuildings = state.enemyFaction?.buildings ?? [];
    final dummyBuilding = Building.create(buildingType, position);
    if (!dummyBuilding.isWithinSafeDistance(position, enemyBuildings)) {
      // Too close to enemy city
      return;
    }

    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[buildingType] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;

    // Create the building
    final newBuilding = state.createBuilding(buildingType, position);
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Add building to state
    state = state.copyWith(
      buildings: [...state.buildings, newBuilding],
      resources: newResources,
      buildingToBuild: null,
    );
  }

  void trainUnit(UnitType unitType) {
    final selectedBuilding = state.selectedBuilding;
    if (selectedBuilding == null) return;
    
    // Check if building implements UnitTrainer interface
    if (!(selectedBuilding is UnitTrainer)) return;
    
    final trainer = selectedBuilding as UnitTrainer;
    
    // Check if the unit type can be trained in this building
    if (!trainer.canTrainUnit(unitType)) return;
    
    // Get food cost for the unit
    final trainingCost = trainer.getTrainingCost(unitType);
    final foodCost = trainingCost[ResourceType.food] ?? 0;
    
    // Check if we have enough food
    if (foodCost <= 0 || !state.resources.hasEnough(ResourceType.food, foodCost)) {
      return;
    }
    
    // Create the unit at the building position using the UnitFactory
    final newUnit = UnitFactory.createUnit(unitType, selectedBuilding.position);
    
    // Update resources
    final newResources = state.resources.subtract(ResourceType.food, foodCost);
    
    // Add unit to state and update points
    state = ScoreService.addUnitTrainingPoints(
      state.copyWith(
        units: [...state.units, newUnit],
        resources: newResources,
        unitToTrain: null,
      ),
      true
    );
  }

  // End turn
  void nextTurn() {
    // Capture initial state to detect changes
    final initialPlayerUnits = state.units.length;
    final initialPlayerBuildings = state.buildings.length;
    final initialEnemyFaction = state.enemyFaction;
    final initialEnemyUnits = initialEnemyFaction?.units.length ?? 0;
    final initialEnemyBuildings = initialEnemyFaction?.buildings.length ?? 0;
    
    // Process defensive tower attacks
    var updatedState = _processDefensiveTowerAttacks(state);
    
    // Spielerzug beenden
    updatedState = updatedState.nextTurn();
    
    // Calculate enemy AI difficulty scaling based on turn number
    // This makes the enemy stronger as the game progresses
    double difficultyScale = 1.0;
    if (updatedState.turn > 3) {
      // After turn 3, start scaling difficulty
      difficultyScale = 1.0 + ((updatedState.turn - 3) * 0.05);
      // Cap difficulty at 2.0 (twice as powerful)
      if (difficultyScale > 2.0) {
        difficultyScale = 2.0;
      }
    }
    
    // For debugging
    if (updatedState.enemyFaction != null) {
      print('Current enemy difficulty: ${difficultyScale.toStringAsFixed(2)}x');
    }
    
    // Apply difficulty scaling by giving the enemy extra resources each turn
    if (updatedState.enemyFaction != null && difficultyScale > 1.0) {
      // Give the enemy extra resources based on the difficulty
      final extraFood = (10 * difficultyScale).round();
      final extraWood = (5 * difficultyScale).round();
      final extraStone = (3 * difficultyScale).round();
      
      final enhancedResources = updatedState.enemyFaction!.resources
          .add(ResourceType.food, extraFood)
          .add(ResourceType.wood, extraWood)
          .add(ResourceType.stone, extraStone);
      
      // Update enemy faction with enhanced resources
      updatedState = updatedState.copyWith(
        enemyFaction: updatedState.enemyFaction!.copyWith(
          resources: enhancedResources
        )
      );
    }
    
    // Feind-KI-Zug durchführen mit der neuen AI Service Implementierung
    final aiService = AIService();
    updatedState = aiService.processEnemyTurn(updatedState);
    
    // Check for changes to detect combat/captures
    final finalPlayerUnits = updatedState.units.length;
    final finalPlayerBuildings = updatedState.buildings.length;
    final finalEnemyUnits = updatedState.enemyFaction?.units.length ?? 0;
    final finalEnemyBuildings = updatedState.enemyFaction?.buildings.length ?? 0;
    
    // Show notifications using debug print (in a real app, you'd use a proper notification system)
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
    if (updatedState.enemyFaction != null && initialEnemyFaction == null) {
      print('⚠️ ALERT: A new enemy civilization has appeared!');
    }
    
    state = updatedState;
  }
  
  // Angriff auf feindliche Einheit oder Gebäude
  void attackEnemyTarget(Position targetPosition) {
    final selectedUnit = state.selectedUnit;
    
    // Prüfe, ob eine Einheit ausgewählt ist und ob diese eine Kampfeinheit ist
    if (selectedUnit == null || !(selectedUnit is CombatCapable) || !selectedUnit.canAct) {
      return;
    }
    
    // Prüfe, ob die Zielposition angreifbar ist
    if (!CombatHelper.canAttackEnemyAt(state, selectedUnit, targetPosition)) {
      return;
    }
    
    // Führe den Angriff durch
    final updatedState = CombatHelper.attackEnemyAt(state, selectedUnit, targetPosition);
    
    // Aktualisiere den Spielstatus
    state = updatedState;
  }
  
  // Process defensive tower auto attacks
  GameState _processDefensiveTowerAttacks(GameState currentState) {
    GameState updatedState = currentState;
    
    // Process player defensive towers
    for (final building in updatedState.buildings) {
      if (building.type == BuildingType.defensiveTower) {
        final defensiveTower = building as DefensiveTower;
        updatedState = defensiveTower.performAutoAttack(updatedState, false);
      }
    }
    
    // Process enemy defensive towers if there's an enemy faction
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

  // Settler founds city
  void foundCity() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfe, ob die ausgewählte Einheit ein SettlerCapable ist
    if (selectedUnit == null || 
        !(selectedUnit is SettlerCapable) || 
        !selectedUnit.canAct) return;
    
    final settlerCapable = selectedUnit as SettlerCapable;
    
    // Prüfe, ob die Einheit eine Stadt gründen kann
    if (!settlerCapable.canFoundCity()) return;
    
    // Check if tile is buildable
    final tile = state.map.getTile(selectedUnit.position);
    if (!tile.canBuildOn) return;
    
    // Create city center
    final cityCenter = state.createBuilding(
      BuildingType.cityCenter, 
      selectedUnit.position
    );
    
    // Mark tile as having a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Remove the settler and add the city center
    final newUnits = state.units
        .where((unit) => unit.id != selectedUnit.id)
        .toList();
    
    // Add building to state and update points
    state = ScoreService.addCityFoundationPoints(
      state.copyWith(
        units: newUnits,
        buildings: [...state.buildings, cityCenter],
        selectedUnitId: null,
      ),
      true
    );
  }

  // Build farm with farmer
  void buildFarm() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfen, ob die ausgewählte Einheit ein Farmer ist (Farmer implementiert BuilderUnit)
    if (selectedUnit == null || !(selectedUnit is Farmer)) {
      return;
    }
    
    final builderUnit = selectedUnit as BuilderUnit;
    final tile = state.map.getTile(selectedUnit.position);
    
    // Verwende die canBuild-Methode aus dem BuilderUnit-Interface
    if (!builderUnit.canBuild(BuildingType.farm, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.farm] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Create the farm
    final newBuilding = Farm.create(selectedUnit.position);
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Remove the farmer as they become part of the farm they build
    final updatedUnits = state.units.where((unit) => unit.id != selectedUnit.id).toList();
    
    // Add building to state and update points
    state = ScoreService.handleBuildingCapture(
      state.copyWith(
        buildings: [...state.buildings, newBuilding],
        resources: newResources,
        units: updatedUnits,
        selectedUnitId: null, // Deselect the unit since it's gone
      ),
      newBuilding,
      true
    );
  }
  
  // Build lumber camp with lumberjack
  void buildLumberCamp() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfen, ob die ausgewählte Einheit ein Lumberjack ist (Lumberjack implementiert BuilderUnit)
    if (selectedUnit == null || !(selectedUnit is Lumberjack)) {
      return;
    }
    
    final builderUnit = selectedUnit as BuilderUnit;
    final tile = state.map.getTile(selectedUnit.position);
    
    // Verwende die canBuild-Methode aus dem BuilderUnit-Interface
    if (!builderUnit.canBuild(BuildingType.lumberCamp, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.lumberCamp] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Create the lumber camp
    final newBuilding = LumberCamp.create(selectedUnit.position, ownerID: "player");
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Remove the lumberjack as they become part of the lumber camp they build
    final updatedUnits = state.units.where((unit) => unit.id != selectedUnit.id).toList();
    
    // Add building to state and update points
    state = ScoreService.handleBuildingCapture(
      state.copyWith(
        buildings: [...state.buildings, newBuilding],
        resources: newResources,
        units: updatedUnits,
        selectedUnitId: null, // Deselect the unit since it's gone
      ),
      newBuilding,
      true
    );
  }
  
  // Build mine with miner
  void buildMine() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfen, ob die ausgewählte Einheit ein Miner ist (Miner implementiert BuilderUnit)
    if (selectedUnit == null || !(selectedUnit is Miner)) {
      return;
    }
    
    final builderUnit = selectedUnit as BuilderUnit;
    final tile = state.map.getTile(selectedUnit.position);
    
    // Verwende die canBuild-Methode aus dem BuilderUnit-Interface
    if (!builderUnit.canBuild(BuildingType.mine, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.mine] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Prüfen, ob es sich um eine Eisenmine handelt
    final isIronMine = tile.resourceType == ResourceType.iron;
    
    // Create the mine according to resource type
    final newBuilding = Mine.create(selectedUnit.position, isIronMine: isIronMine, ownerID: "player");
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Remove the miner as they become part of the mine they build
    final updatedUnits = state.units.where((unit) => unit.id != selectedUnit.id).toList();
    
    // Add building to state and update points
    state = ScoreService.handleBuildingCapture(
      state.copyWith(
        buildings: [...state.buildings, newBuilding],
        resources: newResources,
        units: updatedUnits,
        selectedUnitId: null, // Deselect the unit since it's gone
      ),
      newBuilding,
      true
    );
  }
  
  // Build barracks with commander
  void buildBarracks() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfen, ob die ausgewählte Einheit ein Commander ist (Commander implementiert BuilderUnit)
    if (selectedUnit == null || !(selectedUnit is Commander) || !selectedUnit.canAct) {
      return;
    }
    
    final builderUnit = selectedUnit as BuilderUnit;
    final tile = state.map.getTile(selectedUnit.position);
    
    // Verwende die canBuild-Methode aus dem BuilderUnit-Interface
    if (!builderUnit.canBuild(BuildingType.barracks, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.barracks] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Create the barracks
    final newBuilding = Barracks.create(selectedUnit.position, ownerID: "player");
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Update commander's remaining actions
    final updatedUnits = state.units.map((unit) {
      if (unit.id == selectedUnit.id) {
        return unit.copyWith(actionsLeft: unit.actionsLeft - 2); // Building barracks costs 2 actions
      }
      return unit;
    }).toList();
    
    // Add building to state and update points
    state = ScoreService.handleBuildingCapture(
      state.copyWith(
        buildings: [...state.buildings, newBuilding],
        resources: newResources,
        units: updatedUnits,
      ),
      newBuilding,
      true
    );
  }

  // Build defensive tower with architect
  void buildDefensiveTower() {
    final selectedUnit = state.selectedUnit;
    
    // Check if the selected unit is an Architect and can act
    if (selectedUnit == null || !(selectedUnit is Architect)) {
      return;
    }
    
    final architect = selectedUnit;
    if (!architect.canAct) return;
    
    final tile = state.map.getTile(architect.position);
    
    // Use the canBuild method from the BuilderUnit interface
    if (!architect.canBuild(BuildingType.defensiveTower, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.defensiveTower] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Create the defensive tower
    final newBuilding = DefensiveTower.create(architect.position,ownerID: "player");
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Update architect's remaining actions
    final updatedUnits = state.units.map((unit) {
      if (unit.id == architect.id) {
        return unit.copyWith(actionsLeft: unit.actionsLeft - architect.getBuildActionCost(BuildingType.defensiveTower));
      }
      return unit;
    }).toList();
    
    // Add building to state
    state = state.copyWith(
      buildings: [...state.buildings, newBuilding],
      resources: newResources,
      units: updatedUnits,
    );
  }

  // Build wall with architect
  void buildWall() {
    final selectedUnit = state.selectedUnit;
    
    // Check if the selected unit is an Architect and can act
    if (selectedUnit == null || !(selectedUnit is Architect)) {
      return;
    }
    
    final architect = selectedUnit;
    if (!architect.canAct) return;
    
    final tile = state.map.getTile(architect.position);
    
    // Use the canBuild method from the BuilderUnit interface
    if (!architect.canBuild(BuildingType.wall, tile as Tile)) {
      return;
    }
    
    // Check if we have enough resources
    final buildingCost = baseBuildingCosts[BuildingType.wall] ?? {};
    if (!state.resources.hasEnoughMultiple(buildingCost)) return;
    
    // Create the wall
    final newBuilding = Wall.create(architect.position, ownerID: "player");
    
    // Update resources
    final newResources = state.resources.subtractMultiple(buildingCost);
    
    // Update tile to mark it has a building
    final newTile = tile.copyWith(hasBuilding: true);
    state.map.setTile(newTile);
    
    // Update architect's remaining actions
    final updatedUnits = state.units.map((unit) {
      if (unit.id == architect.id) {
        return unit.copyWith(actionsLeft: unit.actionsLeft - architect.getBuildActionCost(BuildingType.wall));
      }
      return unit;
    }).toList();
    
    // Add building to state
    state = state.copyWith(
      buildings: [...state.buildings, newBuilding],
      resources: newResources,
      units: updatedUnits,
    );
  }

  // Harvest resource from a tile
  void harvestResource() {
    final selectedUnit = state.selectedUnit;
    
    // Prüfe, ob die ausgewählte Einheit ein HarvesterUnit ist
    if (selectedUnit == null || !selectedUnit.canAct || !(selectedUnit is HarvesterUnit)) return;
    
    final harvesterUnit = selectedUnit as HarvesterUnit;
    
    // Sammle Ressourcen vom Feld, auf dem die Einheit steht
    final tile = state.map.getTile(selectedUnit.position);
    
    // Prüfe, ob auf diesem Feld eine Ressource ist
    if (tile.resourceType == null || tile.resourceAmount <= 0) return;
    
    final resourceType = tile.resourceType!;
    
    // Prüfe, ob die Einheit diesen Ressourcentyp sammeln kann
    if (!harvesterUnit.canHarvest(resourceType, tile as Tile)) return;
    
    // Ermittle die Erntemenge basierend auf der Einheit
    final harvestAmount = harvesterUnit.getHarvestAmount(resourceType);
    
    final actualHarvest = tile.resourceAmount < harvestAmount 
        ? tile.resourceAmount 
        : harvestAmount;
    
    // Update tile with reduced resources
    final newResourceAmount = tile.resourceAmount - actualHarvest;
    final newTile = tile.copyWith(
      resourceAmount: newResourceAmount,
      resourceType: newResourceAmount <= 0 ? null : resourceType,
    );
    state.map.setTile(newTile);
    
    // Update unit action points - Verwende die definierten Aktionskosten
    final actionCost = harvesterUnit.getHarvestActionCost(resourceType);
    final newUnits = state.units.map((unit) {
      if (unit.id == selectedUnit.id) {
        return unit.copyWith(actionsLeft: unit.actionsLeft - actionCost);
      }
      return unit;
    }).toList();
    
    // Update resources
    final newResources = state.resources.add(resourceType, actualHarvest);
    
    // Debug output
    print('Ernte: $actualHarvest ${resourceType.toString().split('.').last}');
    
    state = state.copyWith(
      units: newUnits,
      resources: newResources,
    );
  }

  // Upgrade building
  void upgradeBuilding() {
    final selectedBuilding = state.selectedBuilding;
    if (selectedBuilding == null) return;
    
    // Upgrade cost
    final upgradeCost = selectedBuilding.getUpgradeCost();
    
    // Check if we have enough resources
    if (!state.resources.hasEnoughMultiple(upgradeCost)) return;
    
    // Perform upgrade
    final updatedBuildings = state.buildings.map((building) {
      if (building.id == selectedBuilding.id) {
        return building.upgrade();
      }
      return building;
    }).toList();
    
    // Subtract resources
    final newResources = state.resources.subtractMultiple(upgradeCost);
    
    // Update state
    state = state.copyWith(
      buildings: updatedBuildings,
      resources: newResources,
      playerPoints: state.playerPoints + (selectedBuilding.type != BuildingType.defensiveTower && selectedBuilding.type != BuildingType.wall ? 1 : 0),
    );
  }
  
  // Note: The loadGameState, saveGame, and autosave methods are already defined at the beginning of the class

  // Repair a wall
  void repairWall() {
    final selectedBuilding = state.selectedBuilding;
    
    // Check if the selected building is a wall
    if (selectedBuilding == null || selectedBuilding.type != BuildingType.wall) {
      return;
    }
    
    final wall = selectedBuilding as Wall;
    
    // Check if the wall needs repair
    if (wall.currentHealth >= wall.maxHealth) {
      return; // Wall is already at full health
    }
    
    // Calculate repair cost
    final repairCost = wall.getRepairCost();
    
    // Check if we have enough resources
    if (!state.resources.hasEnoughMultiple(repairCost)) {
      return;
    }
    
    // Repair the wall
    final updatedBuildings = state.buildings.map((building) {
      if (building.id == wall.id) {
        return wall.repair();
      }
      return building;
    }).toList();
    
    // Subtract resources
    final newResources = state.resources.subtractMultiple(repairCost);
    
    print("Wall repaired to full health!");
    
    // Update state
    state = state.copyWith(
      buildings: updatedBuildings,
      resources: newResources,
    );
  }
}