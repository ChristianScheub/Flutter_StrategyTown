import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/game/player.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';

/// Service für die Verwaltung von Spielern
/// Stellt eine einfache API für Spieleroperationen zur Verfügung
class PlayerControlService {
  final Ref _ref;
  
  PlayerControlService(this._ref);
  
  GameStateNotifier get _gameNotifier => _ref.read(gameStateProvider.notifier);
  GameState get _currentState => _ref.read(gameStateProvider);
  
  /// Fügt einen menschlichen Spieler hinzu
  bool addHumanPlayer(String playerName, {String? playerId}) {
    try {
      final currentState = _currentState;
      final updatedPlayerManager = currentState.playerManager.addHumanPlayer(
        name: playerName,
        id: playerId,
      );
      
      final newState = currentState.copyWith(playerManager: updatedPlayerManager);
      _gameNotifier.updateState(newState);
      return true;
    } catch (e) {
      print('Fehler beim Hinzufügen des menschlichen Spielers: $e');
      return false;
    }
  }
  
  /// Fügt einen KI-Spieler hinzu
  bool addAIPlayer(String playerName, {String? playerId}) {
    try {
      final currentState = _currentState;
      final updatedPlayerManager = currentState.playerManager.addAIPlayer(
        name: playerName,
        id: playerId,
      );
      
      final newState = currentState.copyWith(playerManager: updatedPlayerManager);
      _gameNotifier.updateState(newState);
      return true;
    } catch (e) {
      print('Fehler beim Hinzufügen des KI-Spielers: $e');
      return false;
    }
  }
  
  /// Entfernt einen Spieler
  bool removePlayer(String playerId) {
    try {
      final currentState = _currentState;
      final updatedPlayerManager = currentState.playerManager.removePlayer(playerId);
      
      final newState = currentState.copyWith(playerManager: updatedPlayerManager);
      _gameNotifier.updateState(newState);
      return true;
    } catch (e) {
      print('Fehler beim Entfernen des Spielers: $e');
      return false;
    }
  }
  
  /// Holt alle Spieler-IDs
  List<String> getAllPlayerIds() {
    return _currentState.playerManager.playerIds;
  }
  
  /// Holt einen Spieler
  Player? getPlayer(String playerId) {
    return _currentState.playerManager.getPlayer(playerId);
  }
  
  /// Prüft ob ein Spieler existiert
  bool hasPlayer(String playerId) {
    return _currentState.playerManager.hasPlayer(playerId);
  }
  
  /// Prüft ob ein Spieler ein KI-Spieler ist
  bool isAIPlayer(String playerId) {
    return _currentState.playerManager.isAIPlayer(playerId);
  }
  
  /// Prüft ob ein Spieler ein menschlicher Spieler ist
  bool isHumanPlayer(String playerId) {
    return _currentState.playerManager.isHumanPlayer(playerId);
  }
  
  /// Holt die Anzahl der Spieler
  int getPlayerCount() {
    return _currentState.playerManager.playerCount;
  }
  
  /// Holt die Anzahl der aktiven Spieler
  int getActivePlayerCount() {
    return _currentState.playerManager.activePlayerCount;
  }
  
  /// Aktiviert einen Spieler
  bool activatePlayer(String playerId) {
    try {
      final currentState = _currentState;
      final updatedPlayerManager = currentState.playerManager.activatePlayer(playerId);
      
      final newState = currentState.copyWith(playerManager: updatedPlayerManager);
      _gameNotifier.updateState(newState);
      return true;
    } catch (e) {
      print('Fehler beim Aktivieren des Spielers: $e');
      return false;
    }
  }
  
  /// Deaktiviert einen Spieler
  bool deactivatePlayer(String playerId) {
    try {
      final currentState = _currentState;
      final updatedPlayerManager = currentState.playerManager.deactivatePlayer(playerId);
      
      final newState = currentState.copyWith(playerManager: updatedPlayerManager);
      _gameNotifier.updateState(newState);
      return true;
    } catch (e) {
      print('Fehler beim Deaktivieren des Spielers: $e');
      return false;
    }
  }
}
