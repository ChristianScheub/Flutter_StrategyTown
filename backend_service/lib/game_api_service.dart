import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';
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
    router.post('/units/move-from-position/<fromX>/<fromY>/<toX>/<toY>', _moveUnitAtPosition);
    router.post('/units/attack/<unitId>/<targetX>/<targetY>', _attack);
    router.post('/units/harvest', _harvestResource);
    
    // === Building Management ===
    router.get('/buildings', _listPlayerBuildings);
    router.get('/buildings/<playerId>', _getPlayerBuildings);
    router.post('/buildings/select/<buildingId>', _selectBuilding);
    router.post('/buildings/upgrade', _upgradeBuilding);
    router.post('/buildings/build/<type>/<x>/<y>', _buildBuilding);
    router.post('/buildings/build-at-position/<x>/<y>', _buildBuildingAtPosition);
    
    // === Building with Specific Units ===
    router.post('/buildings/build-with-unit/<unitId>/<typeStr>/<x>/<y>', _buildWithSpecificUnit);
    
    // === Quick Build Actions ===
    router.post('/quick-build/farm/<unitId>', _buildFarm);
    router.post('/quick-build/lumber-camp/<unitId>', _buildLumberCamp);
    router.post('/quick-build/mine/<unitId>', _buildMine);
    router.post('/quick-build/barracks/<unitId>', _buildBarracks);
    router.post('/quick-build/defensive-tower/<unitId>', _buildDefensiveTower);
    router.post('/quick-build/wall/<unitId>', _buildWall);
    
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
    try {
      // Get the game controller and state to check if unit exists
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Check if the unit exists
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return _errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      // If unit exists, try to select it
      final result = gameInterface.selectUnit(unitId);
      return _successResponse(result);
    } catch (e) {
      return _errorResponse('Error selecting unit: $e');
    }
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
  
  // === Building with Specific Units ===
  Response _buildWithSpecificUnit(Request request, String unitId, String typeStr, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final position = Position(x: x, y: y);
      
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // First check if the unit exists
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return _errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      // Convert the type string to a BuildingType
      BuildingType? buildingType;
      for (final bType in BuildingType.values) {
        if (bType.toString().split('.').last.toLowerCase() == typeStr.toLowerCase()) {
          buildingType = bType;
          break;
        }
      }
      
      if (buildingType == null) {
        return _errorResponse('Unknown building type: $typeStr');
      }
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then select the tile
      gameController.selectTile(position);
      
      // Use specialized building methods based on type
      bool success = false;
      switch (buildingType) {
        case BuildingType.farm:
          success = gameController.buildFarm();
          break;
        case BuildingType.lumberCamp:
          success = gameController.buildLumberCamp();
          break;
        case BuildingType.mine:
          success = gameController.buildMine();
          break;
        case BuildingType.barracks:
          success = gameController.buildBarracks();
          break;
        case BuildingType.defensiveTower:
          success = gameController.buildDefensiveTower();
          break;
        case BuildingType.wall:
          success = gameController.buildWall();
          break;
        default:
          // For other types use the general method
          gameController.selectBuildingToBuild(buildingType);
          success = gameController.buildBuildingAtPosition(position);
      }
      
      if (success) {
        return _successResponse('Building $typeStr successfully built with unit $unitId at ($x, $y)');
      } else {
        return _errorResponse(
          'Failed to build $typeStr with unit $unitId at ($x, $y). ' +
          'Make sure the selected unit can build that structure at that position and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building with unit: $e');
    }
  }
  
  // === Quick Build Actions ===
  Response _buildFarm(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // First check if the unit exists
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return _errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      // Check if the unit is a Farmer
      if (unit.first.type != UnitType.farmer) {
        return _errorResponse(
          'Unit $unitId is not a Farmer. Only Farmers can build farms.',
          400
        );
      }
      
      // Check if player has enough resources
      final currentPlayer = gameState.currentPlayerId;
      final playerResources = gameState.getPlayerResources(currentPlayer);
      final buildingCost = baseBuildingCosts[BuildingType.farm] ?? {};
      
      // Check for sufficient resources
      if (!playerResources.hasEnoughMultiple(buildingCost)) {
        final requiredResources = {};
        buildingCost.forEach((resource, amount) {
          requiredResources[resource] = amount;
        });
        
        return _errorResponse(
          'Insufficient resources to build a farm. Required: ${requiredResources}',
          400
        );
      }
      
      // Count buildings before building
      final buildingCountBefore = gameState.buildings.where((b) => 
          b.ownerID == currentPlayer && b.type == BuildingType.farm).length;
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build a farm
      gameController.buildFarm();
      
      // Verify that a building was actually created
      final updatedGameState = gameController.currentGameState;
      final buildingCountAfter = updatedGameState.buildings.where((b) => 
          b.ownerID == currentPlayer && b.type == BuildingType.farm).length;
      
      if (buildingCountAfter > buildingCountBefore) {
        return _successResponse('Farm built successfully with unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build farm with unit $unitId. ' + 
          'This could be due to insufficient action points or unsuitable terrain.',
          400
        );
      }
    } catch (e) {
      return _errorResponse('Error building farm: $e');
    }
  }
  
  Response _buildLumberCamp(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // First check if the unit exists
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return _errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build a lumber camp
      final success = gameController.buildLumberCamp();
      
      if (success) {
        return _successResponse('Lumber camp built successfully with unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build lumber camp with unit $unitId. ' + 
          'Make sure the unit is a Lumberjack and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building lumber camp: $e');
    }
  }
  
  Response _buildMine(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build a mine
      final success = gameController.buildMine();
      
      if (success) {
        return _successResponse('Mine built successfully with unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build mine with unit $unitId. ' + 
          'Make sure the unit is a Miner and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building mine: $e');
    }
  }
  
  Response _buildBarracks(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build barracks
      final success = gameController.buildBarracks();
      
      if (success) {
        return _successResponse('Barracks built successfullywith unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build barracks with unit $unitId. ' + 
          'Make sure the unit is a Commander and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building barracks: $e');
    }
  }
  
  Response _buildDefensiveTower(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build a defensive tower
      final success = gameController.buildDefensiveTower();
      
      if (success) {
        return _successResponse('Defensive tower built successfully with unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build defensive tower with unit $unitId. ' + 
          'Make sure the unit is an Architect and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building defensive tower: $e');
    }
  }
  
  Response _buildWall(Request request, String unitId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // First select the unit
      gameController.selectUnit(unitId);
      
      // Then try to build a wall
      final success = gameController.buildWall();
      
      if (success) {
        return _successResponse('Wall built successfully with unit $unitId');
      } else {
        return _errorResponse(
          'Failed to build wall with unit $unitId. ' + 
          'Make sure the unit is an Architect and has enough resources.'
        );
      }
    } catch (e) {
      return _errorResponse('Error building wall: $e');
    }
  }
  
  // === Training Units ===
  Response _trainUnit(Request request, String unitType, String buildingId) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // First check if the building exists
      final building = gameState.buildings.where((b) => b.id == buildingId).toList();
      if (building.isEmpty) {
        return _errorResponse(
          'Building $buildingId does not exist.',
          404
        );
      }
      
      // Convert string unitType to UnitType enum
      UnitType? type;
      for (final uType in UnitType.values) {
        if (uType.toString().split('.').last.toLowerCase() == unitType.toLowerCase()) {
          type = uType;
          break;
        }
      }
      
      if (type == null) {
        return _errorResponse('Unknown unit type: $unitType');
      }
      
      // Check if player has enough resources before attempting to train
      final currentPlayer = gameState.currentPlayerId;
      final playerResources = gameState.getPlayerResources(currentPlayer);
      final unitCost = getUnitCosts(type);
      
      // Check for sufficient resources
      if (!playerResources.hasEnoughMultiple(unitCost)) {
        final requiredResources = {};
        unitCost.forEach((resource, amount) {
          requiredResources[resource] = amount;
        });
        
        return _errorResponse(
          'Insufficient resources to train $unitType. Required: ${requiredResources}',
          400
        );
      }
      
      // First select the building
      gameController.selectBuilding(buildingId);
      
      // Check if the selected building can train this unit type
      final canTrain = canBuildingTrainUnitType(building.first, type);
      if (!canTrain) {
        return _errorResponse(
          'Building ${building.first.displayName} cannot train unit of type $unitType',
          400
        );
      }
      
      // Try to train the unit
      final unitCountBefore = gameState.units.where((u) => u.ownerID == currentPlayer).length;
      
      // Then try to train the unit
      gameController.trainUnitGeneric(type);
      
      // Verify that a unit was actually created by checking the unit count after training
      final updatedGameState = gameController.currentGameState;
      final unitCountAfter = updatedGameState.units.where((u) => u.ownerID == currentPlayer).length;
      
      if (unitCountAfter > unitCountBefore) {
        return _successResponse('$unitType trained successfully in building $buildingId');
      } else {
        return _errorResponse(
          'Failed to train $unitType in building $buildingId. ' + 
          'This could be due to insufficient resources, action points, or other limitations.',
          400
        );
      }
    } catch (e) {
      return _errorResponse('Error training unit: $e');
    }
  }
  
  Response _trainUnitGeneric(Request request, String unitType) {
    try {
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Convert string unitType to UnitType enum
      UnitType? type;
      for (final uType in UnitType.values) {
        if (uType.toString().split('.').last.toLowerCase() == unitType.toLowerCase()) {
          type = uType;
          break;
        }
      }
      
      if (type == null) {
        return _errorResponse('Unknown unit type: $unitType');
      }
      
      // Check if player has enough resources before attempting to train
      final currentPlayer = gameState.currentPlayerId;
      final playerResources = gameState.getPlayerResources(currentPlayer);
      final unitCost = getUnitCosts(type);
      
      // Check for sufficient resources
      if (!playerResources.hasEnoughMultiple(unitCost)) {
        final requiredResources = {};
        unitCost.forEach((resource, amount) {
          requiredResources[resource] = amount;
        });
        
        return _errorResponse(
          'Insufficient resources to train $unitType. Required: ${requiredResources}',
          400
        );
      }
      
      // Count units before training
      final unitCountBefore = gameState.units.where((u) => u.ownerID == currentPlayer).length;
      
      // Try to train the unit
      final success = gameController.trainUnitGeneric(type);
      
      // Verify that a unit was actually created
      final updatedGameState = gameController.currentGameState;
      final unitCountAfter = updatedGameState.units.where((u) => u.ownerID == currentPlayer).length;
      
      if (unitCountAfter > unitCountBefore) {
        return _successResponse('$unitType trained successfully');
      } else {
        return _errorResponse(
          'Failed to train $unitType. Make sure you have selected an appropriate building ' + 
          'and have enough resources and action points.',
          400
        );
      }
    } catch (e) {
      return _errorResponse('Error training unit: $e');
    }
  }
  
  // Add training unit selection method
  Response _selectUnitToTrain(Request request, String unitType) {
    try {
      // Convert string unitType to UnitType enum
      UnitType? type;
      for (final uType in UnitType.values) {
        if (uType.toString().split('.').last.toLowerCase() == unitType.toLowerCase()) {
          type = uType;
          break;
        }
      }
      
      if (type == null) {
        return _errorResponse('Unknown unit type: $unitType');
      }
      
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // Select the unit type to train
      gameController.selectUnitToTrain(type);
      
      return _successResponse('Selected unit type $unitType to train');
    } catch (e) {
      return _errorResponse('Error selecting unit to train: $e');
    }
  }
  
  // Add building selection method
  Response _selectBuildingToBuild(Request request, String buildingType) {
    try {
      // Convert string buildingType to BuildingType enum
      BuildingType? type;
      for (final bType in BuildingType.values) {
        if (bType.toString().split('.').last.toLowerCase() == buildingType.toLowerCase()) {
          type = bType;
          break;
        }
      }
      
      if (type == null) {
        return _errorResponse('Unknown building type: $buildingType');
      }
      
      // Get the game controller
      final gameController = container.read(gameControllerProvider);
      
      // Select the building type to build
      gameController.selectBuildingToBuild(type);
      
      return _successResponse('Selected building type $buildingType to build');
    } catch (e) {
      return _errorResponse('Error selecting building to build: $e');
    }
  }
  
  // Get unit costs from the training buildings in game_core
  Map<ResourceType, int> getUnitCosts(UnitType unitType) {
    // Get the game controller to access game state
    final gameController = container.read(gameControllerProvider);
    final gameState = gameController.currentGameState;
    
    // Find a building that can train this unit type
    Building? trainerBuilding;
    
    // First check all buildings that implement UnitTrainer
    for (final building in gameState.buildings) {
      // Skip buildings that don't belong to current player
      if (building.ownerID != gameState.currentPlayerId) continue;
      
      if (building is UnitTrainer && (building as UnitTrainer).canTrainUnit(unitType)) {
        trainerBuilding = building;
        break;
      }
    }
    
    // If we found a trainer building, use its getTrainingCost method
    if (trainerBuilding != null && trainerBuilding is UnitTrainer) {
      return (trainerBuilding as UnitTrainer).getTrainingCost(unitType);
    }
    
    // Fallback to UnitFactory food costs and standard additional resources
    // This is a fallback implementation for when no trainer building is available
    final foodCost = UnitFactory.getUnitFoodCost(unitType);
    Map<ResourceType, int> costs = {ResourceType.food: foodCost};
    
    // Add standard additional costs based on unit type from game_core
    if (unitType == UnitType.settler) {
      costs[ResourceType.wood] = 50;
    } else if (unitType == UnitType.soldierTroop) {
      costs[ResourceType.iron] = 30;
    } else if (unitType == UnitType.archer) {
      costs[ResourceType.wood] = 30;
      costs[ResourceType.iron] = 20;
    } else if (unitType == UnitType.knight) {
      costs[ResourceType.iron] = 50;
    } else if ([UnitType.farmer, UnitType.lumberjack, UnitType.miner].contains(unitType)) {
      costs[ResourceType.wood] = 20;
    } else if (unitType == UnitType.commander) {
      costs[ResourceType.iron] = 30;
    } else if (unitType == UnitType.architect) {
      costs[ResourceType.wood] = 40;
      costs[ResourceType.stone] = 20;
    }
    
    return costs;
  }
  
  // Fix the unit type in the building training method
  bool canBuildingTrainUnitType(Building building, UnitType unitType) {
    // This is a simplified version - in a real implementation,
    // you would have more detailed logic based on building type
    switch (building.type) {
      case BuildingType.barracks:
        return [UnitType.soldierTroop, UnitType.archer, UnitType.knight].contains(unitType);
      case BuildingType.cityCenter:
        return [UnitType.settler, UnitType.farmer, UnitType.lumberjack, UnitType.miner, 
                UnitType.commander, UnitType.architect].contains(unitType);
      default:
        return false;
    }
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
    try {
      // Get game controller and game state
      final gameController = container.read(gameControllerProvider);
      final gameStateBefore = gameController.currentGameState;
      final currentPlayerIdBefore = gameStateBefore.currentPlayerId;
      final currentTurnBefore = gameStateBefore.turn;
      
      // End the turn
      gameController.endTurn();
      
      // Get the updated state
      final gameStateAfter = gameController.currentGameState;
      final currentPlayerIdAfter = gameStateAfter.currentPlayerId;
      final currentTurnAfter = gameStateAfter.turn;
      
      // Prepare detailed response
      final Map<String, dynamic> details = {
        'previousPlayer': currentPlayerIdBefore,
        'currentPlayer': currentPlayerIdAfter,
        'previousTurn': currentTurnBefore,
        'currentTurn': currentTurnAfter,
        'turnIncremented': currentTurnAfter > currentTurnBefore,
        'playerChanged': currentPlayerIdBefore != currentPlayerIdAfter,
      };
      
      return _successResponse('Turn ended successfully', details);
    } catch (e) {
      return _errorResponse('Error ending turn: $e');
    }
  }
  
  Response _clearSelection(Request request) {
    final result = gameInterface.clearSelection();
    return _successResponse(result);
  }
  
  Response _foundCity(Request request) {
    try {
      // Get game controller and game state
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Check if any unit is selected
      if (gameState.selectedUnitId == null) {
        return _errorResponse(
          'No unit is selected. Please select a Settler unit first.',
          400
        );
      }
      
      // Find the selected unit
      final selectedUnit = gameState.units.where((u) => u.id == gameState.selectedUnitId).toList();
      
      // Check if the selected unit exists
      if (selectedUnit.isEmpty) {
        return _errorResponse(
          'Selected unit does not exist or is no longer available.',
          404
        );
      }
      
      // Check if the selected unit is a settler
      if (selectedUnit.first.type != UnitType.settler) {
        return _errorResponse(
          'Selected unit is not a Settler. Only Settlers can found cities.',
          400
        );
      }
      
      // Try to found a city
      final success = gameController.foundCity();
      
      if (success) {
        return _successResponse('City founded successfully with the selected settler');
      } else {
        return _errorResponse(
          'Failed to found a city. Make sure the settler has enough action points and is on a suitable location.',
          400
        );
      }
    } catch (e) {
      return _errorResponse('Error founding city: $e');
    }
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
    // Get the game controller to access game state
    final gameController = container.read(gameControllerProvider);
    final gameState = gameController.currentGameState;
    final players = gameState.getAllPlayerIDs();
    
    if (players.isEmpty) {
      return _errorResponse('No players found', 404);
    }
    
    // Collect detailed statistics for each player
    final List<Map<String, dynamic>> scoreboardData = [];
    
    for (final playerId in players) {
      final stats = gameState.getPlayerStatistics()[playerId];
      final player = gameState.playerManager.getPlayer(playerId);
      
      if (stats != null && player != null) {
        scoreboardData.add({
          'id': playerId,
          'name': player.name,
          'score': player.points,
          'type': gameState.isHumanPlayer(playerId) ? 'Human' : 'AI',
          'isCurrentPlayer': playerId == gameState.currentPlayerId,
          'units': stats['units'] ?? 0,
          'buildings': stats['buildings'] ?? 0,
          'settlements': stats['settlements'] ?? 0,
          'resources': gameState.getPlayerResources(playerId).toJson(),
        });
      }
    }
    
    // Sort the scoreboard by score (descending)
    scoreboardData.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    return _successResponse('Scoreboard retrieved', {'players': scoreboardData});
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
  
  // Move a unit from one position to another
  Response _moveUnitAtPosition(Request request, String fromXStr, String fromYStr, String toXStr, String toYStr) {
    try {
      final fromX = int.parse(fromXStr);
      final fromY = int.parse(fromYStr);
      final toX = int.parse(toXStr);
      final toY = int.parse(toYStr);
      
      // Get game controller and game state
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Find units at the starting position
      final unitsAtPosition = gameState.getUnitsAt(Position(x: fromX, y: fromY));
      
      // Check if there are any units at this position
      if (unitsAtPosition.isEmpty) {
        return _errorResponse('No units found at position ($fromX, $fromY)', 404);
      }
      
      // Filter to only get current player's units
      final playerUnits = unitsAtPosition.where(
        (unit) => unit.ownerID == gameState.currentPlayerId
      ).toList();
      
      if (playerUnits.isEmpty) {
        return _errorResponse('No units belonging to the current player found at position ($fromX, $fromY)', 404);
      }
      
      // Select the first unit (we could add more logic to choose the most appropriate unit)
      final unit = playerUnits.first;
      
      // First select the unit
      gameController.selectUnit(unit.id);
      
      // Then move it
      final success = gameController.moveUnit(unit.id, Position(x: toX, y: toY));
      
      if (success) {
        return _successResponse('Unit ${unit.id} moved from ($fromX, $fromY) to ($toX, $toY)', {
          'unitId': unit.id,
          'unitType': unit.type.toString(),
          'fromPosition': {'x': fromX, 'y': fromY},
          'toPosition': {'x': toX, 'y': toY}
        });
      } else {
        return _errorResponse('Failed to move unit ${unit.id} to ($toX, $toY)', 400);
      }
    } catch (e) {
      return _errorResponse('Invalid parameters: $e', 400);
    }
  }
}
