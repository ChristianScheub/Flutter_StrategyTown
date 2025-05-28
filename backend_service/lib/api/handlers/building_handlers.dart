import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles building-related API endpoints
class BuildingHandlers {
  final ProviderContainer container;
  
  BuildingHandlers(this.container);
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// List all buildings for the current player
  Response listPlayerBuildings(Request request) {
    final buildings = gameInterface.listPlayerBuildings();
    return ApiResponseHelper.successResponse('Player buildings retrieved', {'buildings': buildings});
  }
  
  /// Get buildings for a specific player
  Response getPlayerBuildings(Request request, String playerId) {
    final buildings = gameInterface.getPlayerBuildings(playerId);
    return ApiResponseHelper.successResponse('Player buildings retrieved', {'buildings': buildings});
  }
  
  /// Select a specific building
  Response selectBuilding(Request request, String buildingId) {
    final result = gameInterface.selectBuilding(buildingId);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Upgrade selected building
  Response upgradeBuilding(Request request) {
    final result = gameInterface.upgradeBuilding();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Build a building at specific coordinates
  Response buildBuilding(Request request, String type, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.buildBuilding(type, x, y);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid build parameters: $e');
    }
  }
  
  /// Build a building at position
  Response buildBuildingAtPosition(Request request, String xStr, String yStr) {
    try {
      final x = int.parse(xStr);
      final y = int.parse(yStr);
      final result = gameInterface.buildBuildingAtPosition(x, y);
      return ApiResponseHelper.successResponse(result);
    } catch (e) {
      return ApiResponseHelper.errorResponse('Invalid build parameters: $e');
    }
  }
  
  /// Select building type to build
  Response selectBuildingToBuild(Request request, String buildingType) {
    final result = gameInterface.selectBuildingToBuild(buildingType);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Build with specific unit
  Response buildWithSpecificUnit(Request request, String unitId, String typeStr, String xStr, String yStr) {
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
        return ApiResponseHelper.errorResponse(
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
        return ApiResponseHelper.errorResponse('Unknown building type: $typeStr');
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
        default:
          return ApiResponseHelper.errorResponse('Building type $typeStr not supported for unit building');
      }
      
      if (success) {
        return ApiResponseHelper.successResponse('Building $typeStr successfully built with unit $unitId at ($x, $y)');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build $typeStr with unit $unitId at ($x, $y)');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building with unit: $e');
    }
  }
}
