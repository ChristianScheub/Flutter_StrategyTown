import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles game status and flow-related API endpoints
class GameHandlers {
  final ProviderContainer container;
  
  GameHandlers(this.container);
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// Server status endpoint
  Response getStatus(Request request) {
    return ApiResponseHelper.successResponse('Game Backend API is running');
  }
  
  /// Game status endpoint
  Response getGameStatus(Request request) {
    final status = gameInterface.getGameStatus();
    return ApiResponseHelper.successResponse('Game status retrieved', {'gameStatus': status});
  }
  
  /// Detailed game status endpoint
  Response getDetailedGameStatus(Request request) {
    final status = gameInterface.getDetailedGameStatus();
    return ApiResponseHelper.successResponse('Detailed game status retrieved', {'gameStatus': status});
  }
  
  /// Available actions endpoint
  Response getAvailableActions(Request request) {
    final actions = gameInterface.getAvailableActions();
    return ApiResponseHelper.successResponse('Available actions retrieved', {'availableActions': actions});
  }
  
  /// End turn endpoint
  Response endTurn(Request request) {
    final result = gameInterface.endTurn();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Clear selection endpoint
  Response clearSelection(Request request) {
    final result = gameInterface.clearSelection();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Start new game endpoint
  Response startNewGame(Request request) {
    final result = gameInterface.startNewGame();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Found city endpoint
  Response foundCity(Request request) {
    final result = gameInterface.foundCity();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Jump to first city endpoint
  Response jumpToFirstCity(Request request) {
    final result = gameInterface.jumpToFirstCity();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Jump to enemy headquarters endpoint
  Response jumpToEnemyHeadquarters(Request request) {
    final result = gameInterface.jumpToEnemyHeadquarters();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Give starting units to all players
  Response giveStartingUnits(Request request) {
    try {
      final initService = container.read(initGameForGuiServiceProvider);
      initService.giveStartingUnitsToAllPlayers();
      return ApiResponseHelper.successResponse('Starting units given to all players');
    } catch (e) {
      return ApiResponseHelper.errorResponse('Failed to give starting units: $e');
    }
  }
}
