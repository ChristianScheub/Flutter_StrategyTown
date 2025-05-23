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
  static GameState addCityFoundationPoints(GameState state, bool isPlayer) {
    if (isPlayer) {
      return state.copyWith(
        playerPoints: state.playerPoints + CITY_FOUNDATION_POINTS - UNIT_TRAINING_POINTS
      );
    } else {
      return state.copyWith(
        aiPoints: state.aiPoints + CITY_FOUNDATION_POINTS
      );
    }
  }

  /// Aktualisiert den Punktestand für das Ausbilden einer Einheit
  static GameState addUnitTrainingPoints(GameState state, bool isPlayer) {
    if (isPlayer) {
      return state.copyWith(
        playerPoints: state.playerPoints + UNIT_TRAINING_POINTS
      );
    } else {
      return state.copyWith(
        aiPoints: state.aiPoints + UNIT_TRAINING_POINTS
      );
    }
  }

  /// Aktualisiert den Punktestand für das Töten einer Einheit
  static GameState handleUnitKill(GameState state, Unit killedUnit, bool killedByPlayer, {bool isTowerKill = false}) {
    if (killedByPlayer) {
      // Spieler erhält Punkte für das Töten einer feindlichen Einheit
      return state.copyWith(
        playerPoints: state.playerPoints + UNIT_KILL_POINTS,
        aiPoints: state.aiPoints - UNIT_TRAINING_POINTS
      );
    } else {
      // KI erhält Punkte für das Töten einer Spielereinheit
      // Bei Turmangriffen verliert der Spieler keine Punkte
      return state.copyWith(
        aiPoints: state.aiPoints + UNIT_KILL_POINTS,
        playerPoints: isTowerKill ? state.playerPoints : state.playerPoints - UNIT_TRAINING_POINTS
      );
    }
  }

  /// Aktualisiert den Punktestand für das Erobern eines Gebäudes
  static GameState handleBuildingCapture(GameState state, Building capturedBuilding, bool capturedByPlayer) {
    // Berechne die Punkte basierend auf dem Gebäudetyp und Level
    final buildingPoints = BUILDING_CAPTURE_POINTS + capturedBuilding.level;
    
    if (capturedByPlayer) {
      return state.copyWith(
        playerPoints: state.playerPoints + buildingPoints,
        aiPoints: state.aiPoints - buildingPoints
      );
    } else {
      return state.copyWith(
        aiPoints: state.aiPoints + buildingPoints,
        playerPoints: state.playerPoints - buildingPoints
      );
    }
  }

  /// Aktualisiert den Punktestand für das Upgraden eines Gebäudes
  static GameState addBuildingUpgradePoints(GameState state, Building building, bool isPlayer) {
    // Defensive Strukturen geben keine Upgrade-Punkte
    if (building.type == BuildingType.defensiveTower || building.type == BuildingType.wall) {
      return state;
    }

    if (isPlayer) {
      return state.copyWith(
        playerPoints: state.playerPoints + BUILDING_UPGRADE_POINTS
      );
    } else {
      return state.copyWith(
        aiPoints: state.aiPoints + BUILDING_UPGRADE_POINTS
      );
    }
  }
} 