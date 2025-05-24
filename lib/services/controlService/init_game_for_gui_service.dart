import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/game/player.dart';
import 'package:flutter_sim_city/models/resource/resources_collection.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';

/// Service zur Initialisierung von Spielen für die GUI
/// Stellt vorkonfigurierte Spielsetups zur Verfügung
class InitGameForGuiService {
  final Ref _ref;
  
  InitGameForGuiService(this._ref);
  
  GameController get _gameController => _ref.read(gameControllerProvider);
  
  /// Initialisiert ein Standard-Einzelspielerspiel
  /// Fügt einen menschlichen Spieler und einen KI-Gegner hinzu
  bool initSinglePlayerGame({
    String humanPlayerName = "Player",
    String aiPlayerName = "Computer",
  }) {
    try {
      // Neues Spiel starten
      _gameController.startNewGame();
      
      // Menschlichen Spieler hinzufügen
      final humanAdded = _gameController.addHumanPlayer(
        humanPlayerName,
        playerId: "human_player_1",
      );
      
      if (!humanAdded) {
        print('Fehler: Konnte menschlichen Spieler nicht hinzufügen');
        return false;
      }
      
      // KI-Spieler hinzufügen
      final aiAdded = _gameController.addAIPlayer(
        aiPlayerName,
        playerId: "ai_player_1",
      );
      
      if (!aiAdded) {
        print('Fehler: Konnte KI-Spieler nicht hinzufügen');
        return false;
      }
      
      print('Einzelspielerspiel erfolgreich initialisiert');
      print('- Menschlicher Spieler: $humanPlayerName');
      print('- KI-Spieler: $aiPlayerName');
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des Einzelspielerspiels: $e');
      return false;
    }
  }
  
  /// Initialisiert ein Mehrspielerspiel mit mehreren menschlichen Spielern
  bool initMultiPlayerGame({
    required List<String> playerNames,
    bool includeAI = false,
    String aiPlayerName = "Computer",
  }) {
    try {
      // Neues Spiel starten
      _gameController.startNewGame();
      
      // Menschliche Spieler hinzufügen
      for (int i = 0; i < playerNames.length; i++) {
        final playerName = playerNames[i];
        final playerId = "human_player_${i + 1}";
        
        final added = _gameController.addHumanPlayer(playerName, playerId: playerId);
        if (!added) {
          print('Fehler: Konnte Spieler $playerName nicht hinzufügen');
          return false;
        }
      }
      
      // Optional KI-Spieler hinzufügen
      if (includeAI) {
        final aiAdded = _gameController.addAIPlayer(
          aiPlayerName,
          playerId: "ai_player_1",
        );
        
        if (!aiAdded) {
          print('Fehler: Konnte KI-Spieler nicht hinzufügen');
          return false;
        }
      }
      
      print('Mehrspielerspiel erfolgreich initialisiert');
      print('- Menschliche Spieler: ${playerNames.join(", ")}');
      if (includeAI) {
        print('- KI-Spieler: $aiPlayerName');
      }
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des Mehrspielerspiels: $e');
      return false;
    }
  }
  
  /// Initialisiert ein KI-Testspiel (nur KI-Spieler)
  bool initAITestGame({
    int aiPlayerCount = 2,
    String aiNamePrefix = "AI Player",
  }) {
    try {
      // Neues Spiel starten
      _gameController.startNewGame();
      
      // KI-Spieler hinzufügen
      for (int i = 0; i < aiPlayerCount; i++) {
        final aiName = "$aiNamePrefix ${i + 1}";
        final aiId = "ai_player_${i + 1}";
        
        final added = _gameController.addAIPlayer(aiName, playerId: aiId);
        if (!added) {
          print('Fehler: Konnte KI-Spieler $aiName nicht hinzufügen');
          return false;
        }
      }
      
      print('KI-Testspiel erfolgreich initialisiert');
      print('- Anzahl KI-Spieler: $aiPlayerCount');
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des KI-Testspiels: $e');
      return false;
    }
  }
  
  /// Initialisiert ein Spiel basierend auf einer Konfiguration
  bool initCustomGame({
    required List<PlayerConfig> playerConfigs,
  }) {
    try {
      // Neues Spiel starten
      _gameController.startNewGame();
      
      // Spieler basierend auf Konfiguration hinzufügen
      for (int i = 0; i < playerConfigs.length; i++) {
        final config = playerConfigs[i];
        final playerId = config.playerId ?? "${config.isAI ? 'ai' : 'human'}_player_${i + 1}";
        
        bool added;
        if (config.isAI) {
          added = _gameController.addAIPlayer(config.name, playerId: playerId);
        } else {
          added = _gameController.addHumanPlayer(config.name, playerId: playerId);
        }
        
        if (!added) {
          print('Fehler: Konnte Spieler ${config.name} nicht hinzufügen');
          return false;
        }
      }
      
      print('Benutzerdefiniertes Spiel erfolgreich initialisiert');
      print('- Anzahl Spieler: ${playerConfigs.length}');
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des benutzerdefinierten Spiels: $e');
      return false;
    }
  }
  
  /// Gibt Informationen über das aktuelle Spiel zurück
  Map<String, dynamic> getGameInfo() {
    final playerIds = _gameController.getAllPlayerIds();
    final playerDetails = <Map<String, dynamic>>[];
    
    for (final playerId in playerIds) {
      // Hier könnte man zusätzliche Spielerinformationen hinzufügen
      playerDetails.add({
        'id': playerId,
        'isAI': playerId.startsWith('ai_'),
        'isHuman': playerId.startsWith('human_'),
      });
    }
    
    return {
      'playerCount': playerIds.length,
      'currentTurn': _gameController.currentTurn,
      'players': playerDetails,
    };
  }
}

/// Konfiguration für einen Spieler
class PlayerConfig {
  final String name;
  final bool isAI;
  final String? playerId;
  
  const PlayerConfig({
    required this.name,
    required this.isAI,
    this.playerId,
  });
  
  factory PlayerConfig.human(String name, {String? playerId}) {
    return PlayerConfig(name: name, isAI: false, playerId: playerId);
  }
  
  factory PlayerConfig.ai(String name, {String? playerId}) {
    return PlayerConfig(name: name, isAI: true, playerId: playerId);
  }
}

/// Provider für den InitGameForGuiService
final initGameForGuiServiceProvider = Provider<InitGameForGuiService>((ref) {
  return InitGameForGuiService(ref);
});
