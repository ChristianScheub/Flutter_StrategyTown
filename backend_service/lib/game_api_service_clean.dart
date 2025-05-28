import 'package:riverpod/riverpod.dart';
import 'package:game_core/game_core.dart';
import 'package:shelf_router/shelf_router.dart';
import 'api/api_router_clean.dart';

/// Main Game API Service - Refactored and streamlined
class GameApiService {
  // Singleton instance of ProviderContainer for accessing providers
  final ProviderContainer container = ProviderContainer();
  
  // API Router instance
  late final ApiRouter _apiRouter;
  
  /// Constructor
  GameApiService() {
    _apiRouter = ApiRouter(container);
  }
  
  /// Access the terminal game interface through the provider
  TerminalGameInterface get gameInterface => container.read(terminalGameInterfaceProvider);
  
  /// Initialize a new game
  void initializeGame() {
    try {
      // Initialize game service
      container.read(initGameForGuiServiceProvider);
      
      // Start an empty game
      final gameController = container.read(gameControllerProvider);
      gameController.startNewGame();
      
      print('Game initialized successfully');
    } catch (e) {
      print('Error in game initialization: $e');
      rethrow;
    }
  }

  /// Get the main router with all API endpoints
  Router get router => _apiRouter.router;
}
