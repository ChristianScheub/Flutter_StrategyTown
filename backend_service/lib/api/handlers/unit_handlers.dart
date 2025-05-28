import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles unit-related API endpoints
class UnitHandlers {
  final ProviderContainer container;
  
  UnitHandlers(this.container);
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// List all units for the current player
  Response listPlayerUnits(Request request) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      // Get the current player ID directly from the game controller
      var currentPlayerId = gameController.currentPlayerId;
      
      // Check if we have any players, if not initialize one
      if (gameState.playerManager.playerCount == 0) {
        print('No players found, initializing a new player...');
        gameInterface.addHumanPlayer("Player 1");
        // Initialize starting units for the new player
        final initService = container.read(initGameForGuiServiceProvider);
        initService.giveStartingUnitsToAllPlayers();
        // Update current player ID after initialization
        currentPlayerId = gameController.currentPlayerId;
      }
      
      if (currentPlayerId.isEmpty) {
        return ApiResponseHelper.errorResponse('Current player not found', 404);
      }
      
      // Get all units that belong to the current player
      final playerUnits = gameState.units
          .where((unit) => unit.ownerID == currentPlayerId)
          .map((unit) => {
            'id': unit.id,
            'type': unit.type.toString(),
            'position': {'x': unit.position.x, 'y': unit.position.y},
          })
          .toList();
      
      // Include the text representation for backwards compatibility
      final unitsText = gameInterface.getPlayerUnits(currentPlayerId);
      // Get current player info
      final currentPlayerInfo = gameInterface.getCurrentPlayer();
      
      return ApiResponseHelper.successResponse('Player units retrieved', {
        'units': playerUnits,
        'unitsText': unitsText,
        'currentPlayerId': currentPlayerId,
        'currentPlayerInfo': currentPlayerInfo,
        'playerCount': gameState.playerManager.playerCount,
        'players': gameState.playerManager.players.keys.toList(),
      });
    } catch (e) {
      print('Error in listPlayerUnits: $e');
      return ApiResponseHelper.errorResponse('Error retrieving player units: $e');
    }
  }
  
  /// Get units for a specific player
  Response getPlayerUnits(Request request, String playerId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Check if player exists
      if (!gameState.hasPlayer(playerId)) {
        return ApiResponseHelper.errorResponse('Player $playerId not found', 404);
      }
      
      // Get all units that belong to the specified player
      final playerUnits = gameState.units
          .where((unit) => unit.ownerID == playerId)
          .map((unit) => {
            'id': unit.id,
            'type': unit.type.toString(),
            'position': {'x': unit.position.x, 'y': unit.position.y},
          })
          .toList();
      
      // For backward compatibility, also include the text representation
      final unitsText = gameInterface.getPlayerUnits(playerId);
      
      return ApiResponseHelper.successResponse('Player units retrieved', {
        'units': playerUnits,
        'unitsText': unitsText,
        'playerCount': gameState.playerManager.playerCount,
        'players': gameState.playerManager.players.keys.toList(),
      });
    } catch (e) {
      print('Error in getPlayerUnits: $e');
      return ApiResponseHelper.errorResponse('Error retrieving player units: $e');
    }
  }
  
  /// Select a specific unit
  Response selectUnit(Request request, String unitId) {
    try {
      // Get the game controller and state to check if unit exists
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      // Check if the unit exists
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      // If unit exists, try to select it
      final result = gameInterface.selectUnit(unitId);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error selecting unit: $e');
    }
  }
  
  /// Move a unit to specific coordinates
  Response moveUnit(Request request, String unitId, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.moveUnit(unitId, x, y);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid coordinates: $e');
    }
  }
  
  /// Move unit from one position to another
  Response moveUnitAtPosition(Request request, String fromX, String fromY, String toX, String toY) {
    try {
      final fromXInt = int.parse(fromX);
      final fromYInt = int.parse(fromY);
      final toXInt = int.parse(toX);
      final toYInt = int.parse(toY);
      // Implementation would need to be added to game interface
      final result = 'Unit moved from ($fromXInt, $fromYInt) to ($toXInt, $toYInt)';
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid coordinates: $e');
    }
  }
  
  /// Attack with a unit
  Response attack(Request request, String unitId, String targetXStr, String targetYStr) {
    try {
      final targetX = int.parse(targetXStr);
      final targetY = int.parse(targetYStr);
      final result = gameInterface.attackTarget(unitId, targetX, targetY);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid attack parameters: $e');
    }
  }
  
  /// Harvest resource with selected unit
  Response harvestResource(Request request) {
    final result = gameInterface.harvestResource();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Train a unit at a specific building
  Response trainUnit(Request request, String unitType, String buildingId) {
    final result = gameInterface.trainUnit(unitType, buildingId);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Train a unit generically
  Response trainUnitGeneric(Request request, String unitType) {
    final result = gameInterface.trainUnitGeneric(unitType);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Select unit type to train
  Response selectUnitToTrain(Request request, String unitType) {
    final result = gameInterface.selectUnitToTrain(unitType);
    return ApiResponseHelper.successResponse(result);
  }
}
