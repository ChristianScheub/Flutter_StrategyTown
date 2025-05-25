import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/game/player.dart';
import 'package:flutter_sim_city/models/map/tile.dart'; // Added for TileType
import 'package:flutter_sim_city/models/resource/resources_collection.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';

/// Service zur Initialisierung von Spielen für die GUI
/// Stellt vorkonfigurierte Spielsetups zur Verfügung
class InitGameForGuiService {
  final Ref _ref;
  
  InitGameForGuiService(this._ref);
  
  GameController get _gameController => _ref.read(gameControllerProvider);
  
  /// Initialisiert ein "Einzelspielerspiel" (nutzt intern trotzdem Mehrspieler-Modus)
  /// Fügt einen menschlichen Spieler und einen KI-Gegner hinzu
  bool initSinglePlayerGame({
    String humanPlayerName = "Player",
    String aiPlayerName = "Computer",
  }) {
    try {
      // Neues Spiel starten (im Mehrspieler-Modus)
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
      
      // Setze den menschlichen Spieler als aktuellen Player
      _gameController.switchToPlayer("human_player_1");
      
      // Alle Spieler bekommen einen Startsiedler
      _giveStartingUnitsToAllPlayers();
      
      print('Spiel erfolgreich initialisiert (Mehrspielermodus mit einem menschlichen Spieler)');
      print('- Menschlicher Spieler: $humanPlayerName');
      print('- KI-Spieler: $aiPlayerName');
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des Spiels: $e');
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
      
      // ADDED: Setze den ersten menschlichen Spieler als aktuellen Player
      if (playerNames.isNotEmpty) {
        _gameController.switchToPlayer("human_player_1");
      }
      
      // ADDED: Alle Spieler bekommen einen Startsiedler
      _giveStartingUnitsToAllPlayers();
      
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
      
      // ADDED: Setze den ersten KI-Spieler als aktuellen Player
      if (aiPlayerCount > 0) {
        _gameController.switchToPlayer("ai_player_1");
      }
      
      // ADDED: Alle Spieler bekommen einen Startsiedler
      _giveStartingUnitsToAllPlayers();
      
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
      
      // ADDED: Setze den ersten Spieler als aktuellen Player
      final firstHumanPlayerConfig = playerConfigs.where((config) => !config.isAI).firstOrNull;
      if (firstHumanPlayerConfig != null) {
        final firstHumanId = firstHumanPlayerConfig.playerId ?? "human_player_1";
        _gameController.switchToPlayer(firstHumanId);
      } else if (playerConfigs.isNotEmpty) {
        // If no human players, set first player as current
        final firstPlayerId = playerConfigs[0].playerId ?? "ai_player_1";
        _gameController.switchToPlayer(firstPlayerId);
      }
      
      // ADDED: Alle Spieler bekommen einen Startsiedler
      _giveStartingUnitsToAllPlayers();
      
      print('Benutzerdefiniertes Spiel erfolgreich initialisiert');
      print('- Anzahl Spieler: ${playerConfigs.length}');
      
      return true;
    } catch (e) {
      print('Fehler beim Initialisieren des benutzerdefinierten Spiels: $e');
      return false;
    }
  }

  /// Gibt allen Spielern einen Startsiedler
  void _giveStartingUnitsToAllPlayers() {
    final gameState = _ref.read(gameStateProvider);
    final notifier = _ref.read(gameStateProvider.notifier);
    
    // Hole alle Spieler-IDs
    final allPlayerIds = gameState.playerManager.playerIds;
    if (allPlayerIds.isEmpty) return;
    
    final updatedUnits = <Unit>[...gameState.units];
    
    // Finde unterschiedliche Startpositionen für jeden Spieler
    final startPositions = _generateStartPositions(allPlayerIds.length);
    
    for (int i = 0; i < allPlayerIds.length; i++) {
      final playerId = allPlayerIds[i];
      final startPosition = startPositions[i];
      
      // Erstelle einen Siedler für diesen Spieler
      final settler = UnitFactory.createUnit(
        UnitType.settler, 
        startPosition, 
        ownerID: playerId,
        currentTurn: gameState.turn,
      );
      
      updatedUnits.add(settler);
      print('Siedler erstellt für Spieler $playerId bei Position ($startPosition)');
    }
    
    // Aktualisiere den GameState mit allen neuen Siedlern
    notifier.updateState(gameState.copyWith(units: updatedUnits));
  }
  
  /// Generiert unterschiedliche Startpositionen für Spieler
  /// Stellt sicher, dass Startpositionen:
  /// 1. Nur auf Gras-Kacheln sind (nicht auf Wasser/Berg/Wald)
  /// 2. Nicht direkt nebeneinander liegen
  List<Position> _generateStartPositions(int playerCount) {
    final gameState = _ref.read(gameStateProvider);
    final positions = <Position>[];
    const baseSpacing = 10; // Erhöhter Mindestabstand zwischen Spielern
    const maxAttempts = 50; // Maximale Anzahl von Versuchen, eine passende Position zu finden
    const minPlayerDistance = 5; // Mindestabstand zwischen Spielern (Manhattan-Distanz)
    
    // Startwinkel für den ersten Spieler - zufällig, um Variation zu haben
    final random = Random();
    final startAngle = random.nextDouble() * 2 * pi;
    
    for (int i = 0; i < playerCount; i++) {
      // Startposition im Kreis berechnen (als Ausgangspunkt)
      final angle = startAngle + (2 * pi * i) / playerCount;
      int baseX = (baseSpacing * cos(angle)).round();
      int baseY = (baseSpacing * sin(angle)).round();
      Position validPosition = Position(x: baseX, y: baseY);
      
      // Versuche, eine gültige Position zu finden
      bool foundValid = false;
      
      for (int attempt = 0; attempt < maxAttempts && !foundValid; attempt++) {
        // Probiere Positionen in der Nähe der berechneten Ausgangsposition
        int testX = baseX + random.nextInt(5) - 2; // -2 bis +2 Variation
        int testY = baseY + random.nextInt(5) - 2;
        final testPosition = Position(x: testX, y: testY);
        
        // Prüfen, ob die Position gültig ist
        if (!gameState.map.isValidPosition(testPosition)) continue;
        
        final tile = gameState.map.getTile(testPosition);
        
        // Prüfe 1: Position muss auf Gras sein
        if (tile.type != TileType.grass) continue;
        
        // Prüfe 2: Position darf kein Gebäude haben
        if (tile.hasBuilding) continue;
        
        // Prüfe 3: Mindestabstand zu anderen Spielern einhalten
        bool tooCloseToOther = false;
        for (final existingPos in positions) {
          if (testPosition.manhattanDistance(existingPos) < minPlayerDistance) {
            tooCloseToOther = true;
            break;
          }
        }
        
        if (!tooCloseToOther) {
          validPosition = testPosition;
          foundValid = true;
          print('Gültige Startposition für Spieler $i gefunden: ($testX, $testY)');
        }
      }
      
      // Wenn keine gültige Position gefunden wurde, verwende die Ausgangsposition
      // und hoffe, dass die TileMap sie bei Bedarf korrigiert
      if (!foundValid) {
        print('Keine gültige Startposition für Spieler $i gefunden, verwende Fallback');
      }
      
      positions.add(validPosition);
    }
    
    return positions;
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
