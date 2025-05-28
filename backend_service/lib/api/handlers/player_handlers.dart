import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';
import '../api_responses.dart';

/// Handles player and map-related API endpoints
class PlayerHandlers {
  final ProviderContainer container;
  
  PlayerHandlers(this.container);
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// List all players
  Response listAllPlayers(Request request) {
    final players = gameInterface.listAllPlayers();
    return ApiResponseHelper.successResponse('All players retrieved', {'players': players});
  }
  
  /// Get current player
  Response getCurrentPlayer(Request request) {
    final currentPlayer = gameInterface.getCurrentPlayer();
    return ApiResponseHelper.successResponse('Current player retrieved', {'currentPlayer': currentPlayer});
  }
  
  /// Get player statistics
  Response getPlayerStatistics(Request request, String playerId) {
    final statistics = gameInterface.getPlayerStatistics(playerId);
    return ApiResponseHelper.successResponse('Player statistics retrieved', {'statistics': statistics});
  }
  
  /// Get scoreboard
  Response getScoreboard(Request request) {
    final scoreboard = gameInterface.getScoreboard();
    return ApiResponseHelper.successResponse('Scoreboard retrieved', {'scoreboard': scoreboard});
  }
  
  /// Add human player
  Response addHumanPlayer(Request request, String name) {
    final result = gameInterface.addHumanPlayer(name);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Add AI player
  Response addAIPlayer(Request request, String name) {
    final result = gameInterface.addAIPlayer(name);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Remove player
  Response removePlayer(Request request, String playerId) {
    final result = gameInterface.removePlayer(playerId);
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Switch to next player
  Response switchPlayer(Request request) {
    final result = gameInterface.switchPlayer();
    return ApiResponseHelper.successResponse(result);
  }
  
  /// Switch to specific player
  Response switchToPlayer(Request request, String playerId) {
    final result = gameInterface.switchToPlayer(playerId);
    return ApiResponseHelper.successResponse(result);
  }
}
