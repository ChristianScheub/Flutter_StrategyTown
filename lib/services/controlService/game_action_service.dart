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
  
  /// Wählt eine Einheit aus (nur wenn sie dem aktuellen Spieler gehört)
  void selectUnit(String unitId) {
    print('GameActionService.selectUnit called with ID: $unitId');
    print('Current player ID: "${_currentState.currentPlayerId}"');
    print('Available players: ${_currentState.playerManager.playerIds}');
    
    // First, try to find the unit by ID in ALL units (regardless of owner)
    Unit? unit = _currentState.units.where((u) => u.id == unitId).firstOrNull;
    
    if (unit != null) {
      print('🚶 Unit found in global list: ${unit.type}');
      print('🚶 Unit owner ID: "${unit.ownerID}"');
      print('🚶 Unit owner ID length: ${unit.ownerID.length}');
      print('🚶 Current player ID: "${_currentState.currentPlayerId}"');
      print('🚶 Current player ID length: ${_currentState.currentPlayerId.length}');
    }
    
    // Now check if it belongs to any modern player
    Unit? ownedUnit;
    for (final playerId in _currentState.playerManager.playerIds) {
      print('Checking player: "$playerId"');
      final playerUnits = _currentState.getUnitsByOwner(playerId);
      print('Player $playerId has ${playerUnits.length} units');
      
      ownedUnit = playerUnits.where((u) => u.id == unitId).firstOrNull;
      if (ownedUnit != null) {
        print('Unit found in player units: ${ownedUnit.type}');
        break;
      }
    }
    
    // Use the unit from global list for ownership check
    unit = ownedUnit ?? unit;
    
    // Prüfe, ob die Einheit dem aktuellen Spieler gehört
    if (unit == null) {
      print('Kann Einheit $unitId nicht auswählen: Einheit existiert nicht');
      return;
    }

    if (unit.ownerID != _currentState.currentPlayerId) {
      print('Einheit gehört nicht dem aktuellen Spieler, aber Details werden angezeigt.');
      _gameNotifier.selectUnitForDetails(unit.id);
      return;
    }

    // Einheit gehört dem aktuellen Spieler, Auswahl erlauben
    _gameNotifier.selectUnit(unit.id);
  }

  /// Wählt ein Gebäude aus (nur wenn es dem aktuellen Spieler gehört)
  void selectBuilding(String buildingId) {
    print('GameActionService.selectBuilding called with ID: $buildingId');
    print('Current player ID: "${_currentState.currentPlayerId}"');
    print('Available players: ${_currentState.playerManager.playerIds}');
    
    // First, try to find the building by ID in ALL buildings (regardless of owner)
    Building? building = _currentState.buildings.where((b) => b.id == buildingId).firstOrNull;
    
    if (building != null) {
      print('🏢 Building found in global list: ${building.displayName}');
      print('🏢 Building owner ID: "${building.ownerID}"');
      print('🏢 Building owner ID length: ${building.ownerID.length}');
      print('🏢 Current player ID: "${_currentState.currentPlayerId}"');
      print('🏢 Current player ID length: ${_currentState.currentPlayerId.length}');
    }
    
    // Now check if it belongs to any modern player
    Building? ownedBuilding;
    for (final playerId in _currentState.playerManager.playerIds) {
      print('Checking player: "$playerId"');
      final playerBuildings = _currentState.getBuildingsByOwner(playerId);
      print('Player $playerId has ${playerBuildings.length} buildings');
      
      ownedBuilding = playerBuildings.where((b) => b.id == buildingId).firstOrNull;
      if (ownedBuilding != null) {
        print('Building found in player buildings: ${ownedBuilding.displayName}');
        break;
      }
    }
    
    // Use the building from global list for ownership check
    building = ownedBuilding ?? building;
    
    // Prüfe, ob das Gebäude dem aktuellen Spieler gehört
    if (building == null || building.ownerID != _currentState.currentPlayerId) {
      if (building != null) {
        print('🚨 Building owner ID: "${building.ownerID}"');
        print('🚨 Current player ID: "${_currentState.currentPlayerId}"');
        print('🚨 String length check - Building: ${building.ownerID.length}, Current: ${_currentState.currentPlayerId.length}');
      }
      print('Kann Gebäude $buildingId nicht auswählen: gehört nicht dem aktuellen Spieler');
      return;
    }
    
    print('Selecting building: ${building.displayName}');
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
      // Finde die Einheit in allen Spieler-Einheiten
      Unit? unit;
      for (final playerId in _currentState.playerManager.playerIds) {
        final playerUnits = _currentState.getUnitsByOwner(playerId);
        unit = playerUnits.where((u) => u.id == unitId).firstOrNull;
        if (unit != null) break;
      }
      
      // Prüfe, ob die Einheit gefunden wurde und dem aktuellen Spieler gehört
      if (unit == null) {
        print('Einheit $unitId nicht gefunden');
        return false;
      }
      
      if (unit.ownerID != _currentState.currentPlayerId) {
        print('Einheit $unitId gehört nicht dem aktuellen Spieler ${_currentState.currentPlayerId}');
        return false;
      }
      
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
      // Finde das Gebäude in allen Spieler-Gebäuden
      Building? building;
      for (final playerId in _currentState.playerManager.playerIds) {
        final playerBuildings = _currentState.getBuildingsByOwner(playerId);
        building = playerBuildings.where((b) => b.id == buildingId).firstOrNull;
        if (building != null) break;
      }
      
      // Prüfe, ob das Gebäude gefunden wurde und dem aktuellen Spieler gehört
      if (building == null) {
        print('Gebäude $buildingId nicht gefunden');
        return false;
      }
      
      if (building.ownerID != _currentState.currentPlayerId) {
        print('Gebäude $buildingId gehört nicht dem aktuellen Spieler ${_currentState.currentPlayerId}');
        return false;
      }
      
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
      // Finde die Angreifer-Einheit in allen Spieler-Einheiten
      Unit? attackerUnit;
      for (final playerId in _currentState.playerManager.playerIds) {
        final playerUnits = _currentState.getUnitsByOwner(playerId);
        attackerUnit = playerUnits.where((u) => u.id == attackerUnitId).firstOrNull;
        if (attackerUnit != null) break;
      }
      
      // Prüfe, ob die Einheit gefunden wurde und dem aktuellen Spieler gehört
      if (attackerUnit == null) {
        print('Angreifer-Einheit $attackerUnitId nicht gefunden');
        return false;
      }
      
      if (attackerUnit.ownerID != _currentState.currentPlayerId) {
        print('Angreifer-Einheit $attackerUnitId gehört nicht dem aktuellen Spieler ${_currentState.currentPlayerId}');
        return false;
      }
      
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
  
  /// Springt zum ersten Siedler
  void jumpToFirstSettler() {
    _gameNotifier.jumpToFirstSettler();
  }
}
