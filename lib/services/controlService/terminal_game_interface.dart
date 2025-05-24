import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';

/// Terminal Interface für das Spiel
/// Diese Klasse bietet eine vereinfachte Textbasierte API für ein Tensorflow Modell
/// Alle Methoden geben String-Ergebnisse zurück und arbeiten mit einfachen Parametern
class TerminalGameInterface {
  final Ref _ref;
  
  TerminalGameInterface(this._ref);
  
  GameController get _gameController => _ref.read(gameControllerProvider);
  
  // === Spiel-Informationen ===
  
  /// Gibt den aktuellen Spielzustand als String zurück
  String getGameStatus() {
    final state = _gameController.currentGameState;
    final resources = _gameController.playerResources;
    final playerUnits = _gameController.playerUnits.length;
    final playerBuildings = _gameController.playerBuildings.length;
    final enemyUnits = _gameController.enemyUnits.length;
    final enemyBuildings = _gameController.enemyBuildings.length;
    
    return """
GAME STATUS - Turn ${state.turn}
Resources: Food=${resources['food']}, Wood=${resources['wood']}, Stone=${resources['stone']}, Gold=${resources['gold']}
Player Units: $playerUnits, Player Buildings: $playerBuildings
Enemy Units: $enemyUnits, Enemy Buildings: $enemyBuildings
    """.trim();
  }
  
  /// Gibt eine Liste aller verfügbaren Aktionen zurück
  String getAvailableActions() {
    return """
AVAILABLE ACTIONS:
1. move_unit <unitId> <x> <y> - Move unit to position
2. attack <attackerUnitId> <targetX> <targetY> - Attack target
3. build <buildingType> <x> <y> - Build building at position
4. train_unit <unitType> <buildingId> - Train unit at building
5. found_city - Found city with selected settler
6. harvest - Harvest resources with selected unit
7. end_turn - End current turn
8. select_unit <unitId> - Select unit
9. select_building <buildingId> - Select building
10. select_tile <x> <y> - Select tile at position
11. clear_selection - Clear current selection
12. upgrade_building - Upgrade selected building
13. jump_to_first_city - Jump camera to first city
14. jump_to_enemy_hq - Jump camera to enemy headquarters
15. build_farm - Build farm (quick action)
16. build_lumber_camp - Build lumber camp (quick action)
17. build_mine - Build mine (quick action)
18. build_barracks - Build barracks (quick action)
19. build_defensive_tower - Build defensive tower (quick action)
20. build_wall - Build wall (quick action)
21. select_building_to_build <buildingType> - Select building type for placement
22. select_unit_to_train <unitType> - Select unit type for training
23. get_units - List all player units
24. get_buildings - List all player buildings
25. get_enemy_units - List all enemy units
26. get_enemy_buildings - List all enemy buildings
27. save_game [saveName] - Save current game
28. load_game <saveKey> - Load saved game
29. start_new_game - Start a new game
    """.trim();
  }
  
  /// Listet alle Einheiten des Spielers auf
  String listPlayerUnits() {
    final units = _gameController.playerUnits;
    if (units.isEmpty) {
      return "No player units found.";
    }
    
    final buffer = StringBuffer("PLAYER UNITS:\n");
    for (final unit in units) {
      buffer.writeln("ID: ${unit.id}, Type: ${unit.type}, Position: (${unit.position.x}, ${unit.position.y}), Actions: ${unit.actionsLeft}");
    }
    
    return buffer.toString().trim();
  }
  
  /// Listet alle Gebäude des Spielers auf
  String listPlayerBuildings() {
    final buildings = _gameController.playerBuildings;
    if (buildings.isEmpty) {
      return "No player buildings found.";
    }
    
    final buffer = StringBuffer("PLAYER BUILDINGS:\n");
    for (final building in buildings) {
      buffer.writeln("ID: ${building.id}, Type: ${building.type}, Position: (${building.position.x}, ${building.position.y}), Level: ${building.level}");
    }
    
    return buffer.toString().trim();
  }
  
  /// Listet alle feindlichen Einheiten auf
  String listEnemyUnits() {
    final units = _gameController.enemyUnits;
    if (units.isEmpty) {
      return "No enemy units found.";
    }
    
    final buffer = StringBuffer("ENEMY UNITS:\n");
    for (final unit in units) {
      buffer.writeln("ID: ${unit.id}, Type: ${unit.type}, Position: (${unit.position.x}, ${unit.position.y})");
    }
    
    return buffer.toString().trim();
  }
  
  /// Listet alle feindlichen Gebäude auf
  String listEnemyBuildings() {
    final buildings = _gameController.enemyBuildings;
    if (buildings.isEmpty) {
      return "No enemy buildings found.";
    }
    
    final buffer = StringBuffer("ENEMY BUILDINGS:\n");
    for (final building in buildings) {
      buffer.writeln("ID: ${building.id}, Type: ${building.type}, Position: (${building.position.x}, ${building.position.y}), Level: ${building.level}");
    }
    
    return buffer.toString().trim();
  }
  
  // === Aktionen ===
  
  /// Bewegt eine Einheit
  String moveUnit(String unitId, int x, int y) {
    final position = Position(x: x, y: y);
    final success = _gameController.moveUnit(unitId, position);
    return success ? "Unit $unitId moved to ($x, $y)" : "Failed to move unit $unitId to ($x, $y)";
  }
  
  /// Greift ein Ziel an
  String attackTarget(String attackerUnitId, int targetX, int targetY) {
    final position = Position(x: targetX, y: targetY);
    final success = _gameController.attackTarget(attackerUnitId, position);
    return success ? "Unit $attackerUnitId attacked target at ($targetX, $targetY)" : "Failed to attack target at ($targetX, $targetY)";
  }
  
  /// Baut ein Gebäude
  String buildBuilding(String buildingTypeStr, int x, int y) {
    final buildingType = _parseBuildingType(buildingTypeStr);
    if (buildingType == null) {
      return "Invalid building type: $buildingTypeStr";
    }
    
    final position = Position(x: x, y: y);
    final success = _gameController.buildBuilding(buildingType, position);
    return success ? "Built $buildingTypeStr at ($x, $y)" : "Failed to build $buildingTypeStr at ($x, $y)";
  }
  
  /// Trainiert eine Einheit
  String trainUnit(String unitTypeStr, String buildingId) {
    final unitType = _parseUnitType(unitTypeStr);
    if (unitType == null) {
      return "Invalid unit type: $unitTypeStr";
    }
    
    final success = _gameController.trainUnit(unitType, buildingId);
    return success ? "Trained $unitTypeStr at building $buildingId" : "Failed to train $unitTypeStr at building $buildingId";
  }
  
  /// Beendet den Zug
  String endTurn() {
    _gameController.endTurn();
    return "Turn ended. New turn: ${_gameController.currentTurn}";
  }
  
  /// Wählt eine Einheit aus
  String selectUnit(String unitId) {
    _gameController.selectUnit(unitId);
    return "Selected unit: $unitId";
  }
  
  /// Wählt ein Gebäude aus
  String selectBuilding(String buildingId) {
    _gameController.selectBuilding(buildingId);
    return "Selected building: $buildingId";
  }
  
  /// Wählt eine Kachel aus
  String selectTile(int x, int y) {
    final position = Position(x: x, y: y);
    _gameController.selectTile(position);
    return "Selected tile at ($x, $y)";
  }
  
  /// Hebt die Auswahl auf
  String clearSelection() {
    _gameController.clearSelection();
    return "Selection cleared";
  }
  
  /// Gründet eine Stadt
  String foundCity() {
    final success = _gameController.foundCity();
    return success ? "City founded successfully" : "Failed to found city";
  }
  
  /// Erntet Ressourcen
  String harvestResource() {
    final success = _gameController.harvestResource();
    return success ? "Resources harvested" : "Failed to harvest resources";
  }
  
  /// Verbessert ein Gebäude
  String upgradeBuilding() {
    final success = _gameController.upgradeBuilding();
    return success ? "Building upgraded" : "Failed to upgrade building";
  }
  
  /// Springt zur ersten Stadt
  String jumpToFirstCity() {
    _gameController.jumpToFirstCity();
    return "Jumped to first city";
  }
  
  /// Springt zum feindlichen Hauptquartier
  String jumpToEnemyHeadquarters() {
    _gameController.jumpToEnemyHeadquarters();
    return "Jumped to enemy headquarters";
  }
  
  /// Schnell-Bau-Aktionen
  String buildFarm() {
    final success = _gameController.buildFarm();
    return success ? "Farm build action initiated" : "Failed to initiate farm building";
  }
  
  String buildLumberCamp() {
    final success = _gameController.buildLumberCamp();
    return success ? "Lumber camp build action initiated" : "Failed to initiate lumber camp building";
  }
  
  String buildMine() {
    final success = _gameController.buildMine();
    return success ? "Mine build action initiated" : "Failed to initiate mine building";
  }
  
  String buildBarracks() {
    final success = _gameController.buildBarracks();
    return success ? "Barracks build action initiated" : "Failed to initiate barracks building";
  }
  
  String buildDefensiveTower() {
    final success = _gameController.buildDefensiveTower();
    return success ? "Defensive tower build action initiated" : "Failed to initiate defensive tower building";
  }
  
  String buildWall() {
    final success = _gameController.buildWall();
    return success ? "Wall build action initiated" : "Failed to initiate wall building";
  }
  
  /// Wählt einen Gebäudetyp zum Bauen aus
  String selectBuildingToBuild(String buildingTypeStr) {
    final buildingType = _parseBuildingType(buildingTypeStr);
    if (buildingType == null) {
      return "Invalid building type: $buildingTypeStr";
    }
    _gameController.selectBuildingToBuild(buildingType);
    return "Selected building type for construction: $buildingTypeStr";
  }
  
  /// Wählt einen Einheitentyp zum Trainieren aus
  String selectUnitToTrain(String unitTypeStr) {
    final unitType = _parseUnitType(unitTypeStr);
    if (unitType == null) {
      return "Invalid unit type: $unitTypeStr";
    }
    _gameController.selectUnitToTrain(unitType);
    return "Selected unit type for training: $unitTypeStr";
  }
  
  /// Baut ein Gebäude an der aktuell ausgewählten Position
  String buildBuildingAtPosition(int x, int y) {
    final position = Position(x: x, y: y);
    final success = _gameController.buildBuildingAtPosition(position);
    return success ? "Built building at ($x, $y)" : "Failed to build building at ($x, $y)";
  }
  
  /// Trainiert eine Einheit (allgemein)
  String trainUnitGeneric(String unitTypeStr) {
    final unitType = _parseUnitType(unitTypeStr);
    if (unitType == null) {
      return "Invalid unit type: $unitTypeStr";
    }
    final success = _gameController.trainUnitGeneric(unitType);
    return success ? "Training $unitTypeStr" : "Failed to train $unitTypeStr";
  }
  
  /// Spiel-Management
  String startNewGame() {
    _gameController.startNewGame();
    return "New game started";
  }
  
  Future<String> saveGame([String? saveName]) async {
    final success = await _gameController.saveGame(saveName: saveName);
    final name = saveName ?? "auto-save";
    return success ? "Game saved as '$name'" : "Failed to save game";
  }
  
  Future<String> loadGame(String saveKey) async {
    final success = await _gameController.loadGame(saveKey);
    return success ? "Game loaded from '$saveKey'" : "Failed to load game";
  }
  
  /// Erweiterte Spiel-Informationen
  String getDetailedGameStatus() {
    final state = _gameController.currentGameState;
    final resources = _gameController.playerResources;
    final playerUnits = _gameController.playerUnits;
    final playerBuildings = _gameController.playerBuildings;
    final enemyUnits = _gameController.enemyUnits;
    final enemyBuildings = _gameController.enemyBuildings;
    
    final buffer = StringBuffer();
    buffer.writeln("=== DETAILED GAME STATUS ===");
    buffer.writeln("Turn: ${state.turn}");
    buffer.writeln("Game Active: ${_gameController.isGameActive}");
    buffer.writeln();
    
    buffer.writeln("RESOURCES:");
    resources.forEach((key, value) {
      buffer.writeln("  $key: $value");
    });
    buffer.writeln();
    
    buffer.writeln("PLAYER FORCES:");
    buffer.writeln("  Units: ${playerUnits.length}");
    buffer.writeln("  Buildings: ${playerBuildings.length}");
    buffer.writeln();
    
    buffer.writeln("ENEMY FORCES:");
    buffer.writeln("  Units: ${enemyUnits.length}");
    buffer.writeln("  Buildings: ${enemyBuildings.length}");
    buffer.writeln();
    
    if (state.selectedUnitId != null) {
      final unit = state.selectedUnit;
      buffer.writeln("SELECTED UNIT: ${unit?.displayName} at (${unit?.position.x}, ${unit?.position.y})");
      buffer.writeln("  Actions left: ${unit?.actionsLeft}/${unit?.maxActions}");
    }
    
    if (state.selectedBuildingId != null) {
      final building = state.selectedBuilding;
      buffer.writeln("SELECTED BUILDING: ${building?.displayName} at (${building?.position.x}, ${building?.position.y})");
      buffer.writeln("  Level: ${building?.level}");
    }
    
    if (state.selectedTilePosition != null) {
      final pos = state.selectedTilePosition!;
      buffer.writeln("SELECTED TILE: (${pos.x}, ${pos.y})");
    }
    
    if (state.buildingToBuild != null) {
      buffer.writeln("BUILDING TO BUILD: ${state.buildingToBuild}");
    }
    
    if (state.unitToTrain != null) {
      buffer.writeln("UNIT TO TRAIN: ${state.unitToTrain}");
    }
    
    return buffer.toString().trim();
  }
  
  /// Gibt verfügbare Spieler zurück
  String listPlayers() {
    final playerIds = _gameController.getAllPlayerIds();
    if (playerIds.isEmpty) {
      return "No players found";
    }
    
    final buffer = StringBuffer("PLAYERS:\n");
    for (final playerId in playerIds) {
      buffer.writeln("  $playerId");
    }
    
    return buffer.toString().trim();
  }
  
  /// Spieler-Management
  String addHumanPlayer(String playerName, [String? playerId]) {
    final success = _gameController.addHumanPlayer(playerName, playerId: playerId);
    return success ? "Human player '$playerName' added" : "Failed to add human player '$playerName'";
  }
  
  String addAIPlayer(String playerName, [String? playerId]) {
    final success = _gameController.addAIPlayer(playerName, playerId: playerId);
    return success ? "AI player '$playerName' added" : "Failed to add AI player '$playerName'";
  }
  
  String removePlayer(String playerId) {
    final success = _gameController.removePlayer(playerId);
    return success ? "Player '$playerId' removed" : "Failed to remove player '$playerId'";
  }
  
  /// Kommando-Prozessor für String-basierte Eingaben
  String processCommand(String command) {
    final parts = command.trim().split(' ');
    if (parts.isEmpty) return "Empty command";
    
    final cmd = parts[0].toLowerCase();
    
    try {
      switch (cmd) {
        case 'move_unit':
          if (parts.length < 4) return "Usage: move_unit <unitId> <x> <y>";
          return moveUnit(parts[1], int.parse(parts[2]), int.parse(parts[3]));
          
        case 'attack':
          if (parts.length < 4) return "Usage: attack <attackerUnitId> <targetX> <targetY>";
          return attackTarget(parts[1], int.parse(parts[2]), int.parse(parts[3]));
          
        case 'build':
          if (parts.length < 4) return "Usage: build <buildingType> <x> <y>";
          return buildBuilding(parts[1], int.parse(parts[2]), int.parse(parts[3]));
          
        case 'train_unit':
          if (parts.length < 3) return "Usage: train_unit <unitType> <buildingId>";
          return trainUnit(parts[1], parts[2]);
          
        case 'select_unit':
          if (parts.length < 2) return "Usage: select_unit <unitId>";
          return selectUnit(parts[1]);
          
        case 'select_building':
          if (parts.length < 2) return "Usage: select_building <buildingId>";
          return selectBuilding(parts[1]);
          
        case 'select_tile':
          if (parts.length < 3) return "Usage: select_tile <x> <y>";
          return selectTile(int.parse(parts[1]), int.parse(parts[2]));
          
        case 'select_building_to_build':
          if (parts.length < 2) return "Usage: select_building_to_build <buildingType>";
          return selectBuildingToBuild(parts[1]);
          
        case 'select_unit_to_train':
          if (parts.length < 2) return "Usage: select_unit_to_train <unitType>";
          return selectUnitToTrain(parts[1]);
          
        case 'build_at_position':
          if (parts.length < 3) return "Usage: build_at_position <x> <y>";
          return buildBuildingAtPosition(int.parse(parts[1]), int.parse(parts[2]));
          
        case 'train_generic':
          if (parts.length < 2) return "Usage: train_generic <unitType>";
          return trainUnitGeneric(parts[1]);
          
        case 'add_human_player':
          if (parts.length < 2) return "Usage: add_human_player <playerName> [playerId]";
          final playerId = parts.length > 2 ? parts[2] : null;
          return addHumanPlayer(parts[1], playerId);
          
        case 'add_ai_player':
          if (parts.length < 2) return "Usage: add_ai_player <playerName> [playerId]";
          final playerId = parts.length > 2 ? parts[2] : null;
          return addAIPlayer(parts[1], playerId);
          
        case 'remove_player':
          if (parts.length < 2) return "Usage: remove_player <playerId>";
          return removePlayer(parts[1]);
          
        case 'save_game':
          final saveName = parts.length > 1 ? parts.sublist(1).join(' ') : null;
          return saveGame(saveName).toString(); // This will be handled as Future
          
        case 'load_game':
          if (parts.length < 2) return "Usage: load_game <saveKey>";
          return loadGame(parts[1]).toString(); // This will be handled as Future
          
        // Einfache Aktionen ohne Parameter
        case 'found_city': return foundCity();
        case 'harvest': return harvestResource();
        case 'end_turn': return endTurn();
        case 'clear_selection': return clearSelection();
        case 'upgrade_building': return upgradeBuilding();
        case 'jump_to_first_city': return jumpToFirstCity();
        case 'jump_to_enemy_hq': return jumpToEnemyHeadquarters();
        case 'build_farm': return buildFarm();
        case 'build_lumber_camp': return buildLumberCamp();
        case 'build_mine': return buildMine();
        case 'build_barracks': return buildBarracks();
        case 'build_defensive_tower': return buildDefensiveTower();
        case 'build_wall': return buildWall();
        case 'start_new_game': return startNewGame();
        
        // Informations-Abfragen
        case 'get_status': return getGameStatus();
        case 'get_detailed_status': return getDetailedGameStatus();
        case 'get_actions': return getAvailableActions();
        case 'get_units': return listPlayerUnits();
        case 'get_buildings': return listPlayerBuildings();
        case 'get_enemy_units': return listEnemyUnits();
        case 'get_enemy_buildings': return listEnemyBuildings();
        case 'get_players': return listPlayers();
        
        case 'help':
          return getAvailableActions();
          
        default:
          return "Unknown command: $cmd. Type 'help' for available commands.";
      }
    } catch (e) {
      return "Error processing command '$command': $e";
    }
  }
  
  // === Helper Methoden ===
  
  BuildingType? _parseBuildingType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'citycenter':
      case 'city':
        return BuildingType.cityCenter;
      case 'farm':
        return BuildingType.farm;
      case 'lumbercamp':
      case 'lumber':
        return BuildingType.lumberCamp;
      case 'mine':
        return BuildingType.mine;
      case 'barracks':
        return BuildingType.barracks;
      case 'defensivetower':
      case 'tower':
        return BuildingType.defensiveTower;
      case 'wall':
        return BuildingType.wall;
      default:
        return null;
    }
  }
  
  UnitType? _parseUnitType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'settler':
        return UnitType.settler;
      case 'farmer':
        return UnitType.farmer;
      case 'lumberjack':
      case 'worker':
        return UnitType.lumberjack;
      case 'miner':
        return UnitType.miner;
      case 'commander':
        return UnitType.commander;
      case 'knight':
        return UnitType.knight;
      case 'soldier':
      case 'warrior':
        return UnitType.soldierTroop;
      case 'archer':
        return UnitType.archer;
      case 'architect':
        return UnitType.architect;
      default:
        return null;
    }
  }
}

/// Provider für das TerminalGameInterface
final terminalGameInterfaceProvider = Provider<TerminalGameInterface>((ref) {
  return TerminalGameInterface(ref);
});
