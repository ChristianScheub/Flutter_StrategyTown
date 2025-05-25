import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/game/player.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';
import 'package:flutter_sim_city/services/save_game_service.dart';

/// Service für den Zugriff auf den Spielzustand
/// Stellt eine vereinfachte API für das Lesen von Spielinformationen zur Verfügung
class GameStateService {
  final Ref _ref;
  
  GameStateService(this._ref);
  
  GameStateNotifier get _gameNotifier => _ref.read(gameStateProvider.notifier);
  GameState get currentState => _ref.read(gameStateProvider);
  
  /// Prüft ob das Spiel aktiv ist
  bool get isGameActive => true; // Vereinfacht - könnte erweitert werden
  
  /// Holt die aktuellen Ressourcen des Spielers als Map
  Map<String, int> getPlayerResources([String? playerId]) {
    // Use current player if no playerId specified
    final targetPlayerId = playerId ?? currentState.currentPlayerId;
    final resources = currentState.getPlayerResources(targetPlayerId);
    return {
      'food': resources.getAmount(ResourceType.food),
      'wood': resources.getAmount(ResourceType.wood),
      'stone': resources.getAmount(ResourceType.stone),
      'gold': resources.getAmount(ResourceType.iron), // Iron wird als Gold dargestellt
    };
  }
  
  /// Holt alle Einheiten des Spielers
  List<Unit> getPlayerUnits([String? playerId]) {
    final targetPlayerId = playerId ?? currentState.currentPlayerId;
    return currentState.getUnitsByOwner(targetPlayerId);
  }
  
  /// Holt alle Gebäude des Spielers
  List<Building> getPlayerBuildings([String? playerId]) {
    final targetPlayerId = playerId ?? currentState.currentPlayerId;
    return currentState.getBuildingsByOwner(targetPlayerId);
  }
   /// Holt alle feindlichen Einheiten (alle Spieler außer dem aktuellen)
  List<Unit> getEnemyUnits() {
    final allUnits = <Unit>[];
    final currentPlayer = currentPlayerId;
    
    // Wenn kein aktueller Spieler gesetzt ist, gebe leere Liste zurück
    if (currentPlayer.isEmpty) {
      return allUnits;
    }
    
    // Sammle Einheiten aller anderen Spieler
    for (final playerId in currentState.playerManager.playerIds) {
      if (playerId != currentPlayer) {
        allUnits.addAll(currentState.getUnitsByOwner(playerId));
      }
    }
    
    // Füge auch Legacy enemyFaction hinzu, falls vorhanden
    if (currentState.enemyFaction != null) {
      allUnits.addAll(currentState.enemyFaction!.units);
    }
    
    return allUnits;
  }

  /// Holt alle feindlichen Gebäude (alle Spieler außer dem aktuellen)
  List<Building> getEnemyBuildings() {
    final allBuildings = <Building>[];
    final currentPlayer = currentPlayerId;
    
    // Wenn kein aktueller Spieler gesetzt ist, gebe leere Liste zurück
    if (currentPlayer.isEmpty) {
      return allBuildings;
    }
    
    // Sammle Gebäude aller anderen Spieler
    for (final playerId in currentState.playerManager.playerIds) {
      if (playerId != currentPlayer) {
        allBuildings.addAll(currentState.getBuildingsByOwner(playerId));
      }
    }
    
    // Füge auch Legacy enemyFaction hinzu, falls vorhanden
    if (currentState.enemyFaction != null) {
      allBuildings.addAll(currentState.enemyFaction!.buildings);
    }
    
    return allBuildings;
  }
   /// Holt die Anzahl der Einheiten des Spielers
  int getPlayerUnitCount() {
    return getCurrentPlayerUnits().length;
  }

  /// Holt die Anzahl der Gebäude des Spielers
  int getPlayerBuildingCount() {
    return getCurrentPlayerBuildings().length;
  }
   /// Holt die Anzahl der feindlichen Einheiten
  int getEnemyUnitCount() {
    return getEnemyUnits().length;
  }

  /// Holt die Anzahl der feindlichen Gebäude
  int getEnemyBuildingCount() {
    return getEnemyBuildings().length;
  }
  
  // === ADDED: Mehrspielermethoden ===
  
  /// Wechselt zum nächsten Spieler
  void switchToNextPlayer() {
    final newState = currentState.switchToNextPlayer();
    _gameNotifier.updateState(newState);
  }
  
  /// Wechselt zu einem bestimmten Spieler
  void switchToPlayer(String playerId) {
    final newState = currentState.switchToPlayer(playerId);
    _gameNotifier.updateState(newState);
  }
  
  /// Holt den aktuellen Spieler ID
  String get currentPlayerId {
    final id = currentState.currentPlayerId;
    if (id.isEmpty && currentState.playerManager.playerIds.isNotEmpty) {
      // Fallback wenn noch kein Spieler gesetzt, aber Spieler existieren
      return currentState.playerManager.playerIds.first;
    }
    return id;
  }
  
  /// Prüft ob der aktuellen Spieler ein Mensch ist
  bool get isCurrentPlayerHuman => currentState.isCurrentPlayerHuman;
  
  /// Prüft ob der aktuellen Spieler KI ist
  bool get isCurrentPlayerAI => currentState.isCurrentPlayerAI;
  
  /// Holt den aktuellen Spieler
  Player? getCurrentPlayer() => currentState.currentPlayer;
  
  /// Holt alle aktiven Spieler
  List<Player> getActivePlayers() => currentState.playerManager.activePlayers;
  
  /// Holt Einheiten des aktuellen Spielers
  List<Unit> getCurrentPlayerUnits() => currentState.currentPlayerUnits;
  
  /// Holt Gebäude des aktuellen Spielers
  List<Building> getCurrentPlayerBuildings() => currentState.currentPlayerBuildings;
  
  /// Holt Ressourcen des aktuellen Spielers
  Map<String, int> getCurrentPlayerResources() {
    final resources = currentState.currentPlayerResources;
    return {
      'food': resources.getAmount(ResourceType.food),
      'wood': resources.getAmount(ResourceType.wood),
      'stone': resources.getAmount(ResourceType.stone),
      'gold': resources.getAmount(ResourceType.iron),
    };
  }
  
  // === END Mehrspielermethoden ===
  
  /// Holt die Punktzahl aller Spieler
  Map<String, int> getAllPlayerScores() {
    final scores = <String, int>{};
    for (final player in currentState.playerManager.allPlayers) {
      scores[player.id] = player.points;
    }
    return scores;
  }
  
  /// Holt die aktuell ausgewählte Einheit
  Unit? getSelectedUnit() {
    return currentState.selectedUnit;
  }
  
  /// Holt das aktuell ausgewählte Gebäude
  Building? getSelectedBuilding() {
    return currentState.selectedBuilding;
  }
  
  /// Prüft ob eine bestimmte Ressourcenmenge verfügbar ist
  bool hasEnoughResources(Map<String, int> requiredResources) {
    final resources = currentState.resources;
    
    for (final entry in requiredResources.entries) {
      final resourceType = _getResourceType(entry.key);
      final required = entry.value;
      
      if (resourceType != null) {
        final available = resources.getAmount(resourceType);
        if (available < required) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  ResourceType? _getResourceType(String resourceName) {
    switch (resourceName.toLowerCase()) {
      case 'food':
        return ResourceType.food;
      case 'wood':
        return ResourceType.wood;
      case 'stone':
        return ResourceType.stone;
      case 'gold':
        return ResourceType.iron; // Iron wird als Gold dargestellt
      default:
        return null;
    }
  }
  
  /// Startet ein neues Spiel
  void startNewGame() {
    final newState = GameState.empty(); // Verwende leeres Spiel ohne Legacy-Player
    _gameNotifier.updateState(newState);
  }
  
  /// Speichert das aktuelle Spiel
  Future<bool> saveGame({String? saveName}) async {
    try {
      return await SaveGameService.saveGame(currentState, name: saveName);
    } catch (e) {
      print('Fehler beim Speichern: $e');
      return false;
    }
  }
  
  /// Lädt ein gespeichertes Spiel
  Future<bool> loadGame(String saveKey) async {
    try {
      final gameState = await SaveGameService.loadGame(saveKey);
      if (gameState != null) {
        _gameNotifier.loadGameState(gameState);
        return true;
      }
      return false;
    } catch (e) {
      print('Fehler beim Laden: $e');
      return false;
    }
  }
}
