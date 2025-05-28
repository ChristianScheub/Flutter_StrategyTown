import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles quick building action endpoints
class QuickBuildHandlers {
  final ProviderContainer container;
  
  QuickBuildHandlers(this.container);
  
  /// Build a farm with specific unit
  Response buildFarm(Request request, String unitId) {
    try {
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
      
      // Check if the unit is a Farmer
      if (unit.first.type != UnitType.farmer) {
        return ApiResponseHelper.errorResponse('Only farmers can build farms');
      }
      
      // Select the unit and attempt to build
      gameController.selectUnit(unitId);
      final success = gameController.buildFarm();
      
      if (success) {
        return ApiResponseHelper.successResponse('Farm built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build farm with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building farm: $e');
    }
  }
  
  /// Build a lumber camp with specific unit
  Response buildLumberCamp(Request request, String unitId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      gameController.selectUnit(unitId);
      final success = gameController.buildLumberCamp();
      
      if (success) {
        return ApiResponseHelper.successResponse('Lumber camp built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build lumber camp with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building lumber camp: $e');
    }
  }
  
  /// Build a mine with specific unit
  Response buildMine(Request request, String unitId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      gameController.selectUnit(unitId);
      final success = gameController.buildMine();
      
      if (success) {
        return ApiResponseHelper.successResponse('Mine built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build mine with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building mine: $e');
    }
  }
  
  /// Build barracks with specific unit
  Response buildBarracks(Request request, String unitId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      gameController.selectUnit(unitId);
      final success = gameController.buildBarracks();
      
      if (success) {
        return ApiResponseHelper.successResponse('Barracks built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build barracks with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building barracks: $e');
    }
  }
  
  /// Build defensive tower with specific unit
  Response buildDefensiveTower(Request request, String unitId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      gameController.selectUnit(unitId);
      final success = gameController.buildDefensiveTower();
      
      if (success) {
        return ApiResponseHelper.successResponse('Defensive tower built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build defensive tower with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building defensive tower: $e');
    }
  }
  
  /// Build wall with specific unit
  Response buildWall(Request request, String unitId) {
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final unit = gameState.units.where((u) => u.id == unitId).toList();
      if (unit.isEmpty) {
        return ApiResponseHelper.errorResponse(
          'Unit $unitId does not exist. It may have been consumed in a previous action.',
          404
        );
      }
      
      gameController.selectUnit(unitId);
      final success = gameController.buildWall();
      
      if (success) {
        return ApiResponseHelper.successResponse('Wall built successfully with unit $unitId');
      } else {
        return ApiResponseHelper.errorResponse('Failed to build wall with unit $unitId');
      }
    } catch (e) {
      return ApiResponseHelper.errorResponse('Error building wall: $e');
    }
  }
}
