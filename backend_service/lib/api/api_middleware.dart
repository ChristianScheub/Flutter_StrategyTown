import 'dart:convert';
import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf/shelf.dart';

/// Middleware for API request logging and monitoring
class ApiMiddleware {
  final ProviderContainer container;
  
  ApiMiddleware(this.container);
  
  /// Logs API calls with detailed information
  void logApiCall(String method, String path, Map<String, String> pathParams, [Map<String, dynamic>? bodyParams]) {
    // Skip logging for certain endpoints that generate too much noise
    final skipLogging = [
      '/scoreboard',
      '/detailed-game-status'
    ];
    
    if (skipLogging.any((endpoint) => path.contains(endpoint))) {
      return;
    }
    
    try {
      final gameController = container.read(gameControllerProvider);
      final gameState = gameController.currentGameState;
      
      final currentPlayer = gameState.playerManager.getPlayer(gameState.currentPlayerId);
      final playerInfo = currentPlayer != null 
          ? '${currentPlayer.name} (${gameState.currentPlayerId})'
          : 'Unknown';
      
      final timestamp = DateTime.now().toIso8601String();
      
      print('=== API CALL LOG ===');
      print('Timestamp: $timestamp');
      print('Method: $method');
      print('Path: $path');
      print('Triggered by Player: $playerInfo');
      print('Turn: ${gameState.turn}');
      
      if (pathParams.isNotEmpty) {
        print('Path Params: $pathParams');
      }
      
      if (bodyParams != null && bodyParams.isNotEmpty) {
        print('Body Params: $bodyParams');
      }
      
      print('==================');
    } catch (e) {
      print('Error logging API call: $e');
    }
  }

  /// Middleware function to log all requests
  Handler loggingMiddleware(Handler innerHandler) {
    return (Request request) async {
      final method = request.method;
      final path = request.url.path;
      
      // Extract path parameters
      final pathParams = <String, String>{};
      final pathSegments = request.url.pathSegments;
      
      // Extract body parameters if present
      Map<String, dynamic>? bodyParams;
      if (request.method == 'POST' || request.method == 'PUT') {
        try {
          final body = await request.readAsString();
          if (body.isNotEmpty) {
            bodyParams = jsonDecode(body);
          }
        } catch (e) {
          // Body might not be JSON, that's okay
        }
      }
      
      // Extract query parameters
      final queryParams = request.url.queryParameters;
      if (queryParams.isNotEmpty) {
        pathParams.addAll(queryParams);
      }
      
      // Log the API call
      logApiCall(method, path, pathParams, bodyParams);
      
      // Continue with the original handler
      return await innerHandler(request);
    };
  }
}
