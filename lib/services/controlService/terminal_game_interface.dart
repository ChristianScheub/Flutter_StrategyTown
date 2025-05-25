import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
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
  
  // === Helper Methoden zum Parsen von Typen ===
  BuildingType? _parseBuildingType(String buildingTypeStr) {
    try {
      return BuildingType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == buildingTypeStr.toLowerCase()
      );
    } catch (e) {
      return null; // Ungültiger Gebäudetyp
    }
  }

  UnitType? _parseUnitType(String unitTypeStr) {
    try {
      return UnitType.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == unitTypeStr.toLowerCase()
      );
    } catch (e) {
      return null; // Ungültiger Einheitentyp
    }
  }
  
  // === Spiel-Informationen ===
  
  /// Gibt den aktuellen Spielzustand als String zurück
  String getGameStatus() {
    final state = _gameController.currentGameState;
    final resources = _gameController.currentPlayerResources;
    final playerUnits = _gameController.currentPlayerUnits.length;
    final playerBuildings = _gameController.currentPlayerBuildings.length;
    final enemyUnits = _gameController.enemyUnits.length;
    final enemyBuildings = _gameController.enemyBuildings.length;
    
    return """
GAME STATUS - Turn ${state.turn} | Current Player: ${_gameController.currentPlayerId}
Player Type: ${_gameController.isCurrentPlayerHuman ? 'Human' : 'AI'}
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

MULTIPLAYER COMMANDS:
30. switch_player - Switch to next player
31. switch_to_player <playerId> - Switch to specific player
32. get_current_player - Get current player info
33. list_all_players - List all players in game
34. get_player_resources <playerId> - Get specific player's resources
35. get_player_units <playerId> - Get specific player's units
36. get_player_buildings <playerId> - Get specific player's buildings
    """.trim();
  }
  
  /// Listet alle Einheiten des Spielers auf
  String listPlayerUnits() {
    final units = _gameController.currentPlayerUnits;
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
    final buildings = _gameController.currentPlayerBuildings;
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
    final resources = _gameController.currentPlayerResources;
    final playerUnits = _gameController.currentPlayerUnits;
    final playerBuildings = _gameController.currentPlayerBuildings;
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
  
  // === ADDED: Mehrspielerbefehle ===
  
  /// Wechselt zum nächsten Spieler
  String switchPlayer() {
    final currentPlayer = _gameController.currentPlayerId;
    _gameController.switchToNextPlayer();
    final newPlayer = _gameController.currentPlayerId;
    return "Switched from '$currentPlayer' to '$newPlayer'";
  }
  
  /// Wechselt zu einem bestimmten Spieler
  String switchToPlayer(String playerId) {
    if (!_gameController.currentGameState.hasPlayer(playerId)) {
      return "Player '$playerId' not found";
    }
    final currentPlayer = _gameController.currentPlayerId;
    _gameController.switchToPlayer(playerId);
    return "Switched from '$currentPlayer' to '$playerId'";
  }
  
  /// Holt Informationen über den aktuellen Spieler
  String getCurrentPlayer() {
    final playerId = _gameController.currentPlayerId;
    final isHuman = _gameController.isCurrentPlayerHuman;
    final resources = _gameController.currentPlayerResources;
    final unitCount = _gameController.currentPlayerUnits.length;
    final buildingCount = _gameController.currentPlayerBuildings.length;
    
    return """
CURRENT PLAYER: $playerId
Type: ${isHuman ? 'Human' : 'AI'}
Resources: Food=${resources['food']}, Wood=${resources['wood']}, Stone=${resources['stone']}, Gold=${resources['gold']}
Units: $unitCount, Buildings: $buildingCount
    """.trim();
  }
  
  /// Listet alle Spieler auf
  String listAllPlayers() {
    final playerIds = _gameController.getAllPlayerIds();
    if (playerIds.isEmpty) {
      return "No players found";
    }
    
    final buffer = StringBuffer("ALL PLAYERS:\n");
    for (final playerId in playerIds) {
      final isHuman = _gameController.currentGameState.isHumanPlayer(playerId);
      final isCurrent = playerId == _gameController.currentPlayerId;
      final marker = isCurrent ? " [CURRENT]" : "";
      buffer.writeln("  $playerId (${isHuman ? 'Human' : 'AI'})$marker");
    }
    
    return buffer.toString().trim();
  }
  
  /// Holt Ressourcen eines bestimmten Spielers
  String getPlayerResources(String playerId) {
    if (!_gameController.currentGameState.hasPlayer(playerId)) {
      return "Player '$playerId' not found";
    }
    
    final resources = _gameController.currentGameState.getPlayerResources(playerId);
    return "PLAYER '$playerId' RESOURCES: Food=${resources.getAmount(ResourceType.food)}, Wood=${resources.getAmount(ResourceType.wood)}, Stone=${resources.getAmount(ResourceType.stone)}, Gold=${resources.getAmount(ResourceType.iron)}";
  }
  
  /// Holt Einheiten eines bestimmten Spielers
  String getPlayerUnits(String playerId) {
    if (!_gameController.currentGameState.hasPlayer(playerId)) {
      return "Player '$playerId' not found";
    }
    
    final units = _gameController.currentGameState.getUnitsByOwner(playerId);
    if (units.isEmpty) {
      return "Player '$playerId' has no units";
    }
    
    final buffer = StringBuffer("PLAYER '$playerId' UNITS:\n");
    for (final unit in units) {
      buffer.writeln("  ${unit.id}: ${unit.displayName} at (${unit.position.x}, ${unit.position.y})");
    }
    
    return buffer.toString().trim();
  }
  
  /// Holt Gebäude eines bestimmten Spielers
  String getPlayerBuildings(String playerId) {
    if (!_gameController.currentGameState.hasPlayer(playerId)) {
      return "Player '$playerId' not found";
    }
    
    final buildings = _gameController.currentGameState.getBuildingsByOwner(playerId);
    if (buildings.isEmpty) {
      return "Player '$playerId' has no buildings";
    }
    
    final buffer = StringBuffer("PLAYER '$playerId' BUILDINGS:\n");
    for (final building in buildings) {
      buffer.writeln("  ${building.id}: ${building.displayName} at (${building.position.x}, ${building.position.y})");
    }
    
    return buffer.toString().trim();
  }
  
  /// Gibt detaillierte Statistiken für einen Spieler zurück
  String getPlayerStatistics(String playerId) {
    final gameState = _gameController.currentGameState;
    
    if (!gameState.hasPlayer(playerId)) {
      return "Player '$playerId' not found";
    }
    
    final stats = gameState.getPlayerStatistics()[playerId];
    if (stats == null) {
      return "No statistics available for player '$playerId'";
    }
    
    final buffer = StringBuffer("STATISTICS FOR PLAYER '$playerId':\n");
    
    stats.forEach((key, value) {
      buffer.writeln("  $key: $value");
    });
    
    return buffer.toString().trim();
  }
  
  /// Gibt die Punktzahl für alle Spieler zurück
  String getScoreboard() {
    final gameState = _gameController.currentGameState;
    final players = gameState.getAllPlayerIDs();
    
    if (players.isEmpty) {
      return "No players found";
    }
    
    final buffer = StringBuffer("SCOREBOARD:\n");
    
    // Sammle Statistiken für jeden Spieler
    final scoreData = <String, Map<String, dynamic>>{};
    for (final playerId in players) {
      final stats = gameState.getPlayerStatistics()[playerId];
      if (stats != null) {
        scoreData[playerId] = stats;
      }
    }
    
    // Sortiere Spieler nach Punkten (falls verfügbar) oder Einheiten+Gebäude
    final sortedPlayers = players.toList()
      ..sort((a, b) {
        final statsA = scoreData[a];
        final statsB = scoreData[b];
        
        if (statsA == null || statsB == null) return 0;
        
        // Wenn es explizite Punkte gibt, verwende diese
        if (statsA.containsKey('score') && statsB.containsKey('score')) {
          return (statsB['score'] as num).compareTo(statsA['score'] as num);
        }
        
        // Ansonsten verwende Einheiten + Gebäude als Proxy für Punkte
        final unitsA = statsA['units'] as int? ?? 0;
        final buildingsA = statsA['buildings'] as int? ?? 0;
        final unitsB = statsB['units'] as int? ?? 0;
        final buildingsB = statsB['buildings'] as int? ?? 0;
        
        return (unitsB + buildingsB).compareTo(unitsA + buildingsA);
      });
    
    // Ausgabe der sortierten Punktetabelle
    for (int i = 0; i < sortedPlayers.length; i++) {
      final playerId = sortedPlayers[i];
      final stats = scoreData[playerId];
      final isHuman = gameState.isHumanPlayer(playerId);
      final isCurrent = playerId == gameState.currentPlayerId;
      
      buffer.write("  ${i + 1}. $playerId (${isHuman ? 'Human' : 'AI'})");
      if (isCurrent) buffer.write(" [CURRENT]");
      buffer.write(": ");
      
      if (stats != null) {
        if (stats.containsKey('score')) {
          buffer.write("Score: ${stats['score']}, ");
        }
        
        final units = stats['units'] as int? ?? 0;
        final buildings = stats['buildings'] as int? ?? 0;
        final settlements = stats['settlements'] as int? ?? 0;
        
        buffer.write("Units: $units, Buildings: $buildings, Settlements: $settlements");
      } else {
        buffer.write("No statistics available");
      }
      
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }
  
  /// Gibt die verfügbaren Ressourcen auf einer Kachel zurück
  String getTileResources(int x, int y) {
    final position = Position(x: x, y: y);
    final gameState = _gameController.currentGameState;
    
    if (!gameState.map.isValidPosition(position)) {
      return "Invalid position ($x, $y)";
    }
    
    final tile = gameState.map.getTile(position);
    
    if (tile.resourceType == null) {
      return "No resources at position ($x, $y)";
    }
    
    return "RESOURCES AT ($x, $y): ${tile.resourceType} (amount: ${tile.resourceAmount})";
  }
  
  /// Gibt Informationen über eine bestimmte Kachel zurück
  String getTileInfo(int x, int y) {
    final position = Position(x: x, y: y);
    final gameState = _gameController.currentGameState;
    
    if (!gameState.map.isValidPosition(position)) {
      return "Invalid position ($x, $y)";
    }
    
    final tile = gameState.map.getTile(position);
    final units = gameState.getUnitsAt(position);
    final building = gameState.getBuildingAt(position);
    
    final buffer = StringBuffer("TILE INFO ($x, $y):\n");
    buffer.writeln("  Type: ${tile.type}");
    buffer.writeln("  Walkable: ${tile.isWalkable}");
    buffer.writeln("  Can build on: ${tile.canBuildOn}");
    
    if (tile.resourceType != null) {
      buffer.writeln("  Resource: ${tile.resourceType} (amount: ${tile.resourceAmount})");
    } else {
      buffer.writeln("  Resource: none");
    }
    
    if (units.isNotEmpty) {
      buffer.writeln("  Units:");
      for (final unit in units) {
        buffer.writeln("    - ${unit.displayName} (owner: ${unit.ownerID})");
      }
    }
    
    if (building != null) {
      buffer.writeln("  Building: ${building.displayName} (owner: ${building.ownerID}, level: ${building.level})");
    }
    
    return buffer.toString().trim();
  }
  
  /// Gibt eine Karte der Umgebung um eine Position herum zurück
  String getAreaMap(int centerX, int centerY, {int radius = 5}) {
    final position = Position(x: centerX, y: centerY);
    final gameState = _gameController.currentGameState;
    
    if (!gameState.map.isValidPosition(position)) {
      return "Invalid position ($centerX, $centerY)";
    }
    
    final buffer = StringBuffer("MAP AREA around ($centerX, $centerY) with radius $radius:\n");
    
    // Koordinatenlegende oben
    buffer.write("   ");
    for (int x = centerX - radius; x <= centerX + radius; x++) {
      buffer.write("${x % 10}");
    }
    buffer.writeln();
    
    for (int y = centerY - radius; y <= centerY + radius; y++) {
      // Y-Koordinate links
      buffer.write("${y % 10} |");
      
      for (int x = centerX - radius; x <= centerX + radius; x++) {
        final pos = Position(x: x, y: y);
        
        if (!gameState.map.isValidPosition(pos)) {
          buffer.write("?"); // Außerhalb der Karte
          continue;
        }
        
        final tile = gameState.map.getTile(pos);
        final units = gameState.getUnitsAt(pos);
        final building = gameState.getBuildingAt(pos);
        
        // Symbole für Karte:
        // Einheit hat höchste Priorität, dann Gebäude, dann Gelände
        if (units.isNotEmpty) {
          final unit = units.first;
          if (unit.ownerID == gameState.currentPlayerId) {
            if (unit.isCombatUnit) buffer.write("S"); // Eigener Soldat
            else buffer.write("U"); // Eigene zivile Einheit
          } else {
            if (unit.isCombatUnit) buffer.write("E"); // Feindlicher Soldat
            else buffer.write("e"); // Feindliche zivile Einheit
          }
        } else if (building != null) {
          if (building.ownerID == gameState.currentPlayerId) {
            buffer.write("B"); // Eigenes Gebäude
          } else {
            buffer.write("b"); // Feindliches Gebäude
          }
        } else if (tile.resourceType != null) {
          // Ressource
          if (tile.resourceType == ResourceType.food) {
            buffer.write("F");
          } else if (tile.resourceType == ResourceType.wood) {
            buffer.write("W");
          } else if (tile.resourceType == ResourceType.stone) {
            buffer.write("S");
          } else if (tile.resourceType == ResourceType.iron) {
            buffer.write("I");
          } else {
            buffer.write("R");
          }
        } else {
          // Gelände
          if (tile.type == TileType.grass) {
            buffer.write(".");
          } else if (tile.type == TileType.water) {
            buffer.write("~");
          } else if (tile.type == TileType.mountain) {
            buffer.write("^");
          } else if (tile.type == TileType.forest) {
            buffer.write("f");
          } else {
            buffer.write("?");
          }
        }
      }
      
      buffer.writeln("|");
    }
    
    // Legende
    buffer.writeln("\nLEGEND:");
    buffer.writeln("  Terrain: . = Grass, ~ = Water, ^ = Mountain, f = Forest");
    buffer.writeln("  Resources: F = Food, W = Wood, S = Stone, I = Iron");
    buffer.writeln("  Buildings: B = Your building, b = Enemy building");
    buffer.writeln("  Units: U = Your civilian, S = Your soldier, e = Enemy civilian, E = Enemy soldier");
    
    return buffer.toString();
  }
}

/// Provider für das TerminalGameInterface
final terminalGameInterfaceProvider = Provider<TerminalGameInterface>((ref) {
  return TerminalGameInterface(ref);
});
