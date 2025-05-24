import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';

/// Service für die Verwaltung des Punktestands
class ScoreService {
  /// Punkte für verschiedene Aktionen
  static const int CITY_FOUNDATION_POINTS = 500;
  static const int UNIT_TRAINING_POINTS = 3;
  static const int UNIT_KILL_POINTS = 5;
  static const int BUILDING_CAPTURE_POINTS = 10;
  static const int BUILDING_UPGRADE_POINTS = 1;

  /// Aktualisiert den Punktestand für das Gründen einer Stadt
  static GameState addCityFoundationPoints(GameState state, String playerID) {
    final player = state.playerManager.getPlayer(playerID);
    if (player == null) return state;
    
    // Gründung einer Stadt gibt Punkte, aber kostet auch einen Siedler
    final newPoints = player.points + CITY_FOUNDATION_POINTS - UNIT_TRAINING_POINTS;
    final updatedPlayerManager = state.playerManager.updatePlayer(
      player.copyWith(points: newPoints)
    );
    
    return state.copyWith(playerManager: updatedPlayerManager);
  }

  /// Aktualisiert den Punktestand für das Ausbilden einer Einheit
  static GameState addUnitTrainingPoints(GameState state, String playerID) {
    final player = state.playerManager.getPlayer(playerID);
    if (player == null) return state;
    
    final updatedPlayerManager = state.playerManager.addPlayerPoints(playerID, UNIT_TRAINING_POINTS);
    return state.copyWith(playerManager: updatedPlayerManager);
  }

  /// Aktualisiert den Punktestand für das Töten einer Einheit
  static GameState handleUnitKill(GameState state, Unit killedUnit, String killerPlayerID, {bool isTowerKill = false}) {
    final killer = state.playerManager.getPlayer(killerPlayerID);
    final victim = state.playerManager.getPlayer(killedUnit.ownerID);
    
    if (killer == null || victim == null) return state;
    
    var updatedPlayerManager = state.playerManager;
    
    // Killer erhält Punkte
    updatedPlayerManager = updatedPlayerManager.addPlayerPoints(killerPlayerID, UNIT_KILL_POINTS);
    
    // Opfer verliert Punkte (außer bei Turmangriffen)
    if (!isTowerKill) {
      final newVictimPoints = (victim.points - UNIT_TRAINING_POINTS).clamp(0, double.infinity).toInt();
      updatedPlayerManager = updatedPlayerManager.updatePlayer(
        victim.copyWith(points: newVictimPoints)
      );
    }
    
    return state.copyWith(playerManager: updatedPlayerManager);
  }

  /// Aktualisiert den Punktestand für das Erobern eines Gebäudes
  static GameState handleBuildingCapture(GameState state, Building capturedBuilding, String newOwnerID) {
    final newOwner = state.playerManager.getPlayer(newOwnerID);
    final oldOwner = state.playerManager.getPlayer(capturedBuilding.ownerID);
    
    if (newOwner == null) return state;
    
    // Berechne die Punkte basierend auf dem Gebäudetyp und Level
    final buildingPoints = BUILDING_CAPTURE_POINTS + capturedBuilding.level;
    
    var updatedPlayerManager = state.playerManager;
    
    // Neuer Besitzer erhält Punkte
    updatedPlayerManager = updatedPlayerManager.addPlayerPoints(newOwnerID, buildingPoints);
    
    // Alter Besitzer verliert Punkte (falls er existiert)
    if (oldOwner != null) {
      final newOldOwnerPoints = (oldOwner.points - buildingPoints).clamp(0, double.infinity).toInt();
      updatedPlayerManager = updatedPlayerManager.updatePlayer(
        oldOwner.copyWith(points: newOldOwnerPoints)
      );
    }
    
    return state.copyWith(playerManager: updatedPlayerManager);
  }

  /// Aktualisiert den Punktestand für das Upgraden eines Gebäudes
  static GameState addBuildingUpgradePoints(GameState state, Building building, String playerID) {
    // Defensive Strukturen geben keine Upgrade-Punkte
    if (building.type == BuildingType.defensiveTower || building.type == BuildingType.wall) {
      return state;
    }

    final player = state.playerManager.getPlayer(playerID);
    if (player == null) return state;
    
    final updatedPlayerManager = state.playerManager.addPlayerPoints(playerID, BUILDING_UPGRADE_POINTS);
    return state.copyWith(playerManager: updatedPlayerManager);
  }

  /// Holt die Punkte eines bestimmten Spielers
  static int getPlayerPoints(GameState state, String playerID) {
    final player = state.playerManager.getPlayer(playerID);
    return player?.points ?? 0;
  }

  /// Holt die Punktestände aller Spieler
  static Map<String, int> getAllPlayerPoints(GameState state) {
    final points = <String, int>{};
    for (final player in state.playerManager.allPlayers) {
      points[player.id] = player.points;
    }
    return points;
  }

  /// Ermittelt den Spieler mit den meisten Punkten
  static String? getLeadingPlayer(GameState state) {
    if (state.playerManager.playerCount == 0) return null;
    
    String? leadingPlayer;
    int maxPoints = -1;
    
    for (final player in state.playerManager.allPlayers) {
      if (player.points > maxPoints) {
        maxPoints = player.points;
        leadingPlayer = player.id;
      }
    }
    
    return leadingPlayer;
  }

  /// Ermittelt das Ranking aller Spieler nach Punkten
  static List<MapEntry<String, int>> getPlayerRanking(GameState state) {
    final points = getAllPlayerPoints(state);
    final ranking = points.entries.toList();
    ranking.sort((a, b) => b.value.compareTo(a.value)); // Absteigend sortieren
    return ranking;
  }

  /// Überprüft, ob ein Spieler eine bestimmte Punktzahl erreicht hat (für Siegbedingungen)
  static bool hasPlayerReachedScore(GameState state, String playerID, int targetScore) {
    return getPlayerPoints(state, playerID) >= targetScore;
  }

  /// Überprüft, ob irgendein Spieler eine bestimmte Punktzahl erreicht hat
  static bool hasAnyPlayerReachedScore(GameState state, int targetScore) {
    return state.playerManager.allPlayers.any((player) => player.points >= targetScore);
  }
}