import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
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
  Map<String, int> getPlayerResources() {
    final resources = currentState.resources;
    return {
      'food': resources.getAmount(ResourceType.food),
      'wood': resources.getAmount(ResourceType.wood),
      'stone': resources.getAmount(ResourceType.stone),
      'gold': resources.getAmount(ResourceType.iron), // Iron wird als Gold dargestellt
    };
  }
  
  /// Holt alle Einheiten des Spielers
  List<Unit> getPlayerUnits() {
    return currentState.units;
  }
  
  /// Holt alle Gebäude des Spielers
  List<Building> getPlayerBuildings() {
    return currentState.buildings;
  }
  
  /// Holt alle feindlichen Einheiten
  List<Unit> getEnemyUnits() {
    return currentState.enemyFaction?.units ?? [];
  }
  
  /// Holt alle feindlichen Gebäude
  List<Building> getEnemyBuildings() {
    return currentState.enemyFaction?.buildings ?? [];
  }
  
  /// Holt die Anzahl der Einheiten des Spielers
  int getPlayerUnitCount() {
    return currentState.units.length;
  }
  
  /// Holt die Anzahl der Gebäude des Spielers
  int getPlayerBuildingCount() {
    return currentState.buildings.length;
  }
  
  /// Holt die Anzahl der feindlichen Einheiten
  int getEnemyUnitCount() {
    return currentState.enemyFaction?.units.length ?? 0;
  }
  
  /// Holt die Anzahl der feindlichen Gebäude
  int getEnemyBuildingCount() {
    return currentState.enemyFaction?.buildings.length ?? 0;
  }
  
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
    final newState = GameState.initial();
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
