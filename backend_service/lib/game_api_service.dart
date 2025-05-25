import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class GameApiService {
  // Singleton instance of ProviderContainer for accessing providers
  final ProviderContainer container = ProviderContainer();
  
  // Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  // Initialize a new game
  void initializeGame() {
    try {
      // Initialize game service
      final initService = container.read(initGameForGuiServiceProvider);
      
      // Start a single player game with defaults
      // Initialize with the correct named parameter
      final success = initService.initSinglePlayerGame(humanPlayerName: 'Player1');
      
      if (!success) {
        print('Warning: Failed to initialize single player game');
      }
    } catch (e) {
      print('Error in game initialization: $e');
      rethrow;
    }
  }

  Router get router {
    final router = Router();

    // === Server Status ===
    router.get('/status', _getStatus);

    // === Game Information ===
    router.get('/game-status', _getGameStatus);
    router.get('/detailed-game-status', _getDetailedGameStatus);
    router.get('/available-actions', _getAvailableActions);
    
    // === Unit Management ===
    router.get('/units', _listPlayerUnits);
    router.get('/units/<playerId>', _getPlayerUnits);
    router.post('/units/select/<unitId>', _selectUnit);
    router.post('/units/move/<unitId>/<x>/<y>', _moveUnit);
    router.post('/units/attack/<unitId>/<targetX>/<targetY>', _attack);
    router.post('/units/harvest', _harvestResource);
    
    // === Building Management ===
    router.get('/buildings', _listPlayerBuildings);
    router.get('/buildings/<playerId>', _getPlayerBuildings);
    router.post('/buildings/select/<buildingId>', _selectBuilding);
    router.post('/buildings/upgrade', _upgradeBuilding);
    router.post('/buildings/build/<type>/<x>/<y>', _buildBuilding);
    router.post('/buildings/build-at-position/<x>/<y>', _buildBuildingAtPosition);
    
    // === Quick Build Actions ===
    router.post('/quick-build/farm', _buildFarm);
    router.post('/quick-build/lumber-camp', _buildLumberCamp);
    router.post('/quick-build/mine', _buildMine);
    router.post('/quick-build/barracks', _buildBarracks);
    router.post('/quick-build/defensive-tower', _buildDefensiveTower);
    router.post('/quick-build/wall', _buildWall);
    
    // === Training Units ===
    router.post('/train-unit/<unitType>/<buildingId>', _trainUnit);
    router.post('/train-unit-generic/<unitType>', _trainUnitGeneric);
    router.post('/select-unit-to-train/<unitType>', _selectUnitToTrain);
    router.post('/select-building-to-build/<buildingType>', _selectBuildingToBuild);
    
    // === Map and Tile Information ===
    router.get('/tile-info/<x>/<y>', _getTileInfo);
    router.get('/tile-resources/<x>/<y>', _getTileResources);
    router.get('/area-map/<centerX>/<centerY>/<radius>', _getAreaMap);
    router.post('/select-tile/<x>/<y>', _selectTile);
    
    // === Game Flow ===
    router.post('/end-turn', _endTurn);
    router.post('/clear-selection', _clearSelection);
    router.post('/found-city', _foundCity);
    
    // === Camera Controls ===
    router.post('/jump-to-first-city', _jumpToFirstCity);
    router.post('/jump-to-enemy-hq', _jumpToEnemyHeadquarters);
    
    // === Game Management ===
    router.post('/start-new-game', _startNewGame);
    
    // === Player Management ===
    router.get('/players/all', _listAllPlayers);
    router.get('/players/current', _getCurrentPlayer);
    router.get('/player-statistics/<playerId>', _getPlayerStatistics);
    router.get('/scoreboard', _getScoreboard);
    router.post('/players/add-human/<name>', _addHumanPlayer);
    router.post('/players/add-ai/<name>', _addAIPlayer);
    router.delete('/players/remove/<playerId>', _removePlayer);
    
    // === Multiplayer Controls ===
    router.post('/switch-player', _switchPlayer);
    router.post('/switch-to-player/<playerId>', _switchToPlayer);

    return router;
  }

  // === Helper Methods ===
  Response _jsonResponse(String data) {
    return Response.ok(
      data,
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
  
  Response _successResponse(String message, [Map<String, dynamic>? additionalData]) {
    final response = {
      'success': true,
      'message': message,
      if (additionalData != null) ...additionalData,
    };
    return _jsonResponse(json.encode(response));
  }
  
  Response _errorResponse(String message, [int statusCode = 400]) {
    return Response(
      statusCode,
      body: json.encode({
        'success': false,
        'error': message,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
  
  // === Server Status ===
  Response _getStatus(Request request) {
    return _successResponse('Game Backend API is running');
  }
  
  // === Game Information ===
  Response _getGameStatus(Request request) {
    final status = gameInterface.getGameStatus();
    return _successResponse('Game status retrieved', {'gameStatus': status});
  }
  
  Response _getDetailedGameStatus(Request request) {
    final status = gameInterface.getDetailedGameStatus();
    return _successResponse('Detailed game status retrieved', {'gameStatus': status});
  }
  
  Response _getAvailableActions(Request request) {
    final actions = gameInterface.getAvailableActions();
    return _successResponse('Available actions retrieved', {'availableActions': actions});
  }
  
  // === Unit Management ===
  Response _listPlayerUnits(Request request) {
    final units = gameInterface.listPlayerUnits();
    return _successResponse('Player units retrieved', {'units': units});
  }
  
  Response _getPlayerUnits(Request request, String playerId) {
    final units = gameInterface.getPlayerUnits(playerId);
    return _successResponse('Player units retrieved', {'units': units});
  }
  
  Response _selectUnit(Request request, String unitId) {
    final result = gameInterface.selectUnit(unitId);
    return _successResponse(result);
  }
  
  Response _moveUnit(Request request, String unitId, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.moveUnit(unitId, x, y);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Invalid coordinates: $e');
    }
  }
  
  Response _attack(Request request, String unitId, String targetXStr, String targetYStr) {
    try {
      final targetX = int.parse(targetXStr);
      final targetY = int.parse(targetYStr);
      final result = gameInterface.attackTarget(unitId, targetX, targetY);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Invalid attack parameters: $e');
    }
  }
  
  Response _harvestResource(Request request) {
    final result = gameInterface.harvestResource();
    return _successResponse(result);
  }
  
  // === Building Management ===
  Response _listPlayerBuildings(Request request) {
    final buildings = gameInterface.listPlayerBuildings();
    return _successResponse('Player buildings retrieved', {'buildings': buildings});
  }
  
  Response _getPlayerBuildings(Request request, String playerId) {
    final buildings = gameInterface.getPlayerBuildings(playerId);
    return _successResponse('Player buildings retrieved', {'buildings': buildings});
  }
  
  Response _selectBuilding(Request request, String buildingId) {
    final result = gameInterface.selectBuilding(buildingId);
    return _successResponse(result);
  }
  
  Response _upgradeBuilding(Request request) {
    final result = gameInterface.upgradeBuilding();
    return _successResponse(result);
  }
  
  Response _buildBuilding(Request request, String type, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.buildBuilding(type, x, y);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Invalid build parameters: $e');
    }
  }
  
  Response _buildBuildingAtPosition(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.buildBuildingAtPosition(x, y);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Invalid build parameters: $e');
    }
  }
  
  // === Quick Build Actions ===
  Response _buildFarm(Request request) {
    final result = gameInterface.buildFarm();
    return _successResponse(result);
  }
  
  Response _buildLumberCamp(Request request) {
    final result = gameInterface.buildLumberCamp();
    return _successResponse(result);
  }
  
  Response _buildMine(Request request) {
    final result = gameInterface.buildMine();
    return _successResponse(result);
  }
  
  Response _buildBarracks(Request request) {
    final result = gameInterface.buildBarracks();
    return _successResponse(result);
  }
  
  Response _buildDefensiveTower(Request request) {
    final result = gameInterface.buildDefensiveTower();
    return _successResponse(result);
  }
  
  Response _buildWall(Request request) {
    final result = gameInterface.buildWall();
    return _successResponse(result);
  }
  
  // === Training Units ===
  Response _trainUnit(Request request, String unitType, String buildingId) {
    final result = gameInterface.trainUnit(unitType, buildingId);
    return _successResponse(result);
  }
  
  Response _trainUnitGeneric(Request request, String unitType) {
    final result = gameInterface.trainUnitGeneric(unitType);
    return _successResponse(result);
  }
  
  Response _selectUnitToTrain(Request request, String unitType) {
    final result = gameInterface.selectUnitToTrain(unitType);
    return _successResponse(result);
  }
  
  Response _selectBuildingToBuild(Request request, String buildingType) {
    final result = gameInterface.selectBuildingToBuild(buildingType);
    return _successResponse(result);
  }
  
  // === Map and Tile Information ===
  Response _getTileInfo(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.getTileInfo(x, y);
      return _successResponse('Tile info retrieved', {'tileInfo': result});
    } catch (e) {
      return _errorResponse('Invalid coordinates: $e');
    }
  }
  
  Response _getTileResources(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.getTileResources(x, y);
      return _successResponse('Tile resources retrieved', {'resources': result});
    } catch (e) {
      return _errorResponse('Invalid coordinates: $e');
    }
  }
  
  Response _getAreaMap(Request request, String centerXStr, String centerYStr, String radiusStr) {
    try {
      final centerX = int.parse(centerXStr);
      final centerY = int.parse(centerYStr);
      final radius = int.parse(radiusStr);
      final result = gameInterface.getAreaMap(centerX, centerY, radius: radius);
      return _successResponse('Area map retrieved', {'map': result});
    } catch (e) {
      return _errorResponse('Invalid map parameters: $e');
    }
  }
  
  Response _selectTile(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.selectTile(x, y);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Invalid coordinates: $e');
    }
  }
  
  // === Game Flow ===
  Response _endTurn(Request request) {
    final result = gameInterface.endTurn();
    return _successResponse(result);
  }
  
  Response _clearSelection(Request request) {
    final result = gameInterface.clearSelection();
    return _successResponse(result);
  }
  
  Response _foundCity(Request request) {
    final result = gameInterface.foundCity();
    return _successResponse(result);
  }
  
  // === Camera Controls ===
  Response _jumpToFirstCity(Request request) {
    final result = gameInterface.jumpToFirstCity();
    return _successResponse(result);
  }
  
  Response _jumpToEnemyHeadquarters(Request request) {
    final result = gameInterface.jumpToEnemyHeadquarters();
    return _successResponse(result);
  }
  
  // === Game Management ===
  Response _startNewGame(Request request) {
    final result = gameInterface.startNewGame();
    return _successResponse(result);
  }
  
  // === Player Management ===
  Response _listAllPlayers(Request request) {
    final players = gameInterface.listAllPlayers();
    return _successResponse('All players retrieved', {'players': players});
  }
  
  Response _getCurrentPlayer(Request request) {
    final player = gameInterface.getCurrentPlayer();
    return _successResponse('Current player retrieved', {'player': player});
  }
  
  Response _getPlayerStatistics(Request request, String playerId) {
    final stats = gameInterface.getPlayerStatistics(playerId);
    return _successResponse('Player statistics retrieved', {'statistics': stats});
  }
  
  Response _getScoreboard(Request request) {
    final scoreboard = gameInterface.getScoreboard();
    return _successResponse('Scoreboard retrieved', {'scoreboard': scoreboard});
  }
  
  Response _addHumanPlayer(Request request, String name) {
    final result = gameInterface.addHumanPlayer(name);
    return _successResponse(result);
  }
  
  Response _addAIPlayer(Request request, String name) {
    final result = gameInterface.addAIPlayer(name);
    return _successResponse(result);
  }
  
  Response _removePlayer(Request request, String playerId) {
    final result = gameInterface.removePlayer(playerId);
    return _successResponse(result);
  }
  
  // === Multiplayer Controls ===
  Response _switchPlayer(Request request) {
    final result = gameInterface.switchPlayer();
    return _successResponse(result);
  }
  
  Response _switchToPlayer(Request request, String playerId) {
    final result = gameInterface.switchToPlayer(playerId);
    return _successResponse(result);
  }
}
