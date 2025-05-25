import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';
import 'package:flutter_sim_city/services/controlService/terminal_game_interface.dart';
import 'package:flutter_sim_city/services/controlService/init_game_for_gui_service.dart';

/// Beispiel für Mehrspielerzüge über das Terminal Interface
/// Zeigt wie KI und menschliche Spieler abwechselnd spielen können
class MultiplayerTerminalExample {
  final Ref _ref;
  
  MultiplayerTerminalExample(this._ref);
  
  /// Initialisiert ein Mehrspielerspiel mit 2 Menschen + 1 KI
  void initializeMultiplayerGame() {
    final initService = _ref.read(initGameForGuiServiceProvider);
    final gameController = _ref.read(gameControllerProvider);
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    print('=== Initializing Multiplayer Game ===');
    
    // Mehrspielerspiel starten
    final success = initService.initMultiPlayerGame(
      playerNames: ["Alice", "Bob"],
      includeAI: true,
      aiPlayerName: "SmartAI",
    );
    
    if (!success) {
      print('❌ Failed to initialize multiplayer game');
      return;
    }
    
    print('✅ Multiplayer game initialized');
    print(terminalInterface.listAllPlayers());
    print(terminalInterface.getCurrentPlayer());
  }
  
  /// Simuliert mehrere Spielerzüge
  void simulateMultiplayerTurns() {
    final gameController = _ref.read(gameControllerProvider);
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    print('\n=== Simulating Multiplayer Turns ===');
    
    // 3 Runden mit 3 Spielern = 9 Züge
    for (int round = 1; round <= 3; round++) {
      print('\n--- ROUND $round ---');
      
      // Jeder Spieler macht einen Zug
      final players = gameController.getAllPlayerIds();
      
      for (String playerId in players) {
        // Wechsle zu diesem Spieler
        print('\n🎮 Switching to player: $playerId');
        print(terminalInterface.switchToPlayer(playerId));
        
        // Zeige aktuellen Status
        print(terminalInterface.getCurrentPlayer());
        
        // Spiele abhängig vom Spielertyp
        if (gameController.isCurrentPlayerHuman) {
          _playHumanTurn(playerId);
        } else {
          _playAITurn(playerId);
        }
        
        // Optional: Kurze Pause zwischen Spielern
        print('--- Turn completed for $playerId ---');
      }
    }
    
    print('\n=== Final Game Status ===');
    print(terminalInterface.getDetailedGameStatus());
  }
  
  /// Simuliert einen menschlichen Spielerzug
  void _playHumanTurn(String playerId) {
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    print('👤 Human player $playerId turn:');
    
    // Zeige verfügbare Ressourcen und Einheiten
    final resources = terminalInterface.processCommand('get_player_resources $playerId');
    final units = terminalInterface.processCommand('get_player_units $playerId');
    
    print('Resources: $resources');
    print('Units: $units');
    
    // Einfache menschliche Aktionen simulieren
    final commands = [
      'get_units',  // Einheiten auflisten
      'select_unit settler_1',  // Einheit auswählen (falls vorhanden)
      'move_unit settler_1 ${_randomCoord()} ${_randomCoord()}',  // Zufällige Bewegung
      'found_city',  // Stadt gründen (falls möglich)
    ];
    
    for (String command in commands) {
      try {
        final result = terminalInterface.processCommand(command);
        if (!result.contains('Error') && !result.contains('Failed')) {
          print('✅ $command -> $result');
          break; // Erfolgreiche Aktion, Zug beenden
        }
      } catch (e) {
        print('❌ $command failed: $e');
      }
    }
  }
  
  /// Simuliert einen KI-Spielerzug
  void _playAITurn(String playerId) {
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    print('🤖 AI player $playerId turn:');
    
    // KI-spezifische Strategie
    final playerUnits = terminalInterface.processCommand('get_player_units $playerId');
    print('AI analyzing units: $playerUnits');
    
    // Einfache KI-Strategie
    final aiCommands = [
      'get_units',
      'select_unit settler_1',
      'move_unit settler_1 ${_randomCoord()} ${_randomCoord()}',
      'build farm ${_randomCoord()} ${_randomCoord()}',
      'train_unit worker barracks_1',
    ];
    
    // KI probiert mehrere Aktionen
    for (String command in aiCommands) {
      try {
        final result = terminalInterface.processCommand(command);
        print('🤖 AI: $command -> ${result.substring(0, result.length.clamp(0, 60))}...');
        
        if (!result.contains('Error') && !result.contains('Failed')) {
          break; // Erfolgreiche Aktion
        }
      } catch (e) {
        print('❌ AI command failed: $e');
      }
    }
  }
  
  /// Zeigt detaillierte Spielerstatistiken
  void showPlayerStatistics() {
    final gameController = _ref.read(gameControllerProvider);
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    print('\n=== PLAYER STATISTICS ===');
    
    final players = gameController.getAllPlayerIds();
    
    for (String playerId in players) {
      print('\n📊 Player: $playerId');
      print('Type: ${gameController.currentGameState.isHumanPlayer(playerId) ? 'Human' : 'AI'}');
      
      // Spielerdaten abrufen
      final resources = terminalInterface.processCommand('get_player_resources $playerId');
      final units = terminalInterface.processCommand('get_player_units $playerId');
      final buildings = terminalInterface.processCommand('get_player_buildings $playerId');
      
      print('Resources: $resources');
      print('Units: ${units.split('\n').length - 1} units');
      print('Buildings: ${buildings.split('\n').length - 1} buildings');
    }
  }
  
  /// Hilfsmethode für zufällige Koordinaten
  int _randomCoord() {
    return DateTime.now().millisecondsSinceEpoch % 10;
  }
  
  /// Komplettes Beispiel ausführen
  void runCompleteExample() {
    print('🎮 MULTIPLAYER TERMINAL EXAMPLE');
    print('================================');
    
    try {
      initializeMultiplayerGame();
      simulateMultiplayerTurns();
      showPlayerStatistics();
      
      print('\n✅ Multiplayer example completed successfully!');
    } catch (e) {
      print('❌ Error in multiplayer example: $e');
    }
  }
}

/// Beispiel-Provider
final multiplayerTerminalExampleProvider = Provider<MultiplayerTerminalExample>((ref) {
  return MultiplayerTerminalExample(ref);
});

/// Beispiel-Aufruf:
/// ```dart
/// final example = ref.read(multiplayerTerminalExampleProvider);
/// example.runCompleteExample();
/// ```
