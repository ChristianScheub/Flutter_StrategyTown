import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';

/// Service für Spielaktionen
/// Stellt eine vereinfachte API für alle Spielaktionen zur Verfügung
class GameActionService {
  final Ref _ref;
  
  GameActionService(this._ref);
  
  GameStateNotifier get _gameNotifier => _ref.read(gameStateProvider.notifier);
  GameState get _currentState => _ref.read(gameStateProvider);
  
  /// Wählt eine Einheit aus
  void selectUnit(String unitId) {
    _gameNotifier.selectUnit(unitId);
  }
  
  /// Wählt ein Gebäude aus
  void selectBuilding(String buildingId) {
    _gameNotifier.selectBuilding(buildingId);
  }
  
  /// Wählt eine Kachel aus
  void selectTile(Position position) {
    _gameNotifier.selectTile(position);
  }
  
  /// Hebt die Auswahl auf
  void clearSelection() {
    _gameNotifier.clearSelection();
  }
  
  /// Bewegt eine Einheit zu einer Position
  bool moveUnit(String unitId, Position targetPosition) {
    try {
      // Erst die Einheit auswählen
      selectUnit(unitId);
      
      // Dann die Zielposition auswählen (bewegt automatisch wenn möglich)
      selectTile(targetPosition);
      
      return true;
    } catch (e) {
      print('Fehler beim Bewegen der Einheit: $e');
      return false;
    }
  }
  
  /// Baut ein Gebäude an einer Position
  bool buildBuilding(BuildingType buildingType, Position position) {
    try {
      // Gebäude zum Bauen auswählen
      _gameNotifier.selectBuildingToBuild(buildingType);
      
      // Position für den Bau auswählen
      _gameNotifier.buildBuilding(position);
      
      return true;
    } catch (e) {
      print('Fehler beim Bauen des Gebäudes: $e');
      return false;
    }
  }
  
  /// Trainiert eine Einheit in einem Gebäude
  bool trainUnit(UnitType unitType, String buildingId) {
    try {
      // Gebäude auswählen
      selectBuilding(buildingId);
      
      // Einheit zum Trainieren auswählen
      _gameNotifier.selectUnitToTrain(unitType);
      
      // Einheit trainieren
      _gameNotifier.trainUnit(unitType);
      
      return true;
    } catch (e) {
      print('Fehler beim Trainieren der Einheit: $e');
      return false;
    }
  }
  
  /// Greift ein Ziel an
  bool attackTarget(String attackerUnitId, Position targetPosition) {
    try {
      // Angreifer auswählen
      selectUnit(attackerUnitId);
      
      // Ziel angreifen
      _gameNotifier.attackEnemyTarget(targetPosition);
      
      return true;
    } catch (e) {
      print('Fehler beim Angriff: $e');
      return false;
    }
  }
  
  /// Gründet eine Stadt mit der ausgewählten Einheit
  bool foundCity() {
    try {
      _gameNotifier.foundCity();
      return true;
    } catch (e) {
      print('Fehler beim Gründen der Stadt: $e');
      return false;
    }
  }
  
  /// Erntet Ressourcen mit der ausgewählten Einheit
  bool harvestResource() {
    try {
      _gameNotifier.harvestResource();
      return true;
    } catch (e) {
      print('Fehler beim Ernten der Ressourcen: $e');
      return false;
    }
  }
  
  /// Repariert eine Mauer
  bool repairWall() {
    try {
      _gameNotifier.repairWall();
      return true;
    } catch (e) {
      print('Fehler beim Reparieren der Mauer: $e');
      return false;
    }
  }
  
  /// Verbessert ein Gebäude
  bool upgradeBuilding() {
    try {
      _gameNotifier.upgradeBuilding();
      return true;
    } catch (e) {
      print('Fehler beim Verbessern des Gebäudes: $e');
      return false;
    }
  }
  
  /// Beendet den aktuellen Zug
  void endTurn() {
    _gameNotifier.nextTurn();
  }
  
  /// Springt zur ersten Stadt
  void jumpToFirstCity() {
    _gameNotifier.jumpToFirstCity();
  }
  
  /// Springt zum feindlichen Hauptquartier
  void jumpToEnemyHeadquarters() {
    _gameNotifier.jumpToEnemyHeadquarters();
  }
}
