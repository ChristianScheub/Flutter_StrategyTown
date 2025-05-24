import 'dart:math';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/farm.dart';
import 'package:flutter_sim_city/models/buildings/barracks.dart';
import 'package:flutter_sim_city/models/buildings/lumber_camp.dart';
import 'package:flutter_sim_city/models/buildings/mine.dart';
import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/services/ai/strategies/ai_expand_strategy.dart';
import 'package:flutter_sim_city/services/score_service.dart';

/// Strategie für den Bau neuer Gebäude
class AIBuildStrategy {
  final Random _random = Random();
  final AIExpandStrategy _expandStrategy = AIExpandStrategy();
  
  /// Führt die Baustrategie aus
  GameState execute(GameState state, EnemyFaction faction, double difficultyScale) {
    // Analyse der aktuellen Gebäude
    final farmCount = faction.buildings.where((b) => b.type == BuildingType.farm).length;
    final barracksCount = faction.buildings.where((b) => b.type == BuildingType.barracks).length;
    final lumberCampCount = faction.buildings.where((b) => b.type == BuildingType.lumberCamp).length;
    final mineCount = faction.buildings.where((b) => b.type == BuildingType.mine).length;
    
    // Bestimme, welche Gebäude am meisten benötigt werden
    List<BuildingType> prioritizedBuildings = _determineBuildingPriorities(
      state, faction, farmCount, barracksCount, lumberCampCount, mineCount
    );
    
    // Wenn keine Gebäude priorisiert wurden, verwende Standardliste
    if (prioritizedBuildings.isEmpty) {
      prioritizedBuildings = [
        BuildingType.farm,
        BuildingType.lumberCamp,
        BuildingType.mine,
        BuildingType.barracks,
      ];
    }
    
    // Versuche, ein Gebäude zu bauen
    for (final buildingType in prioritizedBuildings) {
      final buildingCost = baseBuildingCosts[buildingType] ?? {};
      if (!faction.resources.hasEnoughMultiple(buildingCost)) {
        continue;
      }

      // --- Erweiterung: Builder, die nach 6 Runden noch nichts gebaut haben, werden gezielt zum Bauplatz bewegt ---
      bool builderMoved = false;
      List<Unit> builderUnitsMove = faction.units
          .where((unit) => unit is BuilderUnit && !unit.hasBuiltSomething)
          .toList();
      builderUnitsMove.sort((a, b) => a.creationTurn.compareTo(b.creationTurn));

      List<Unit> movedUnits = List<Unit>.from(faction.units);
      for (final unit in builderUnitsMove) {
        if (state.turn - unit.creationTurn >= 6 && unit.canAct) {
          final buildPos = _findNearbyBuildableTile(state, unit, buildingType, range: 3);
          if (buildPos != null && buildPos != unit.position) {
            final nextPos = _moveTowards(unit.position, buildPos, state);
            movedUnits = movedUnits.map((u) {
              if (u.id == unit.id) {
                return u.copyWith(position: nextPos, actionsLeft: u.actionsLeft - 1);
              }
              return u;
            }).toList();
            builderMoved = true;
            break;
          }
        }
      }
      if (builderMoved) {
        final updatedFaction = faction.copyWith(units: movedUnits);
        return state.copyWith(enemyFaction: updatedFaction);
      }
      // --- Ende Erweiterung ---

      // Suche eine geeignete Position und Einheit zum Bauen
      Position? buildPosition;
      Unit? builderUnit;
      List<Unit> builderUnits = faction.units
          .where((unit) => unit is BuilderUnit && !unit.hasBuiltSomething)
          .toList();
      builderUnits.sort((a, b) => a.creationTurn.compareTo(b.creationTurn));
      for (final unit in builderUnits) {
        final tile = state.map.getTile(unit.position);
        if (unit is BuilderUnit) {
          final builder = unit as BuilderUnit;
          if (builder.canBuild(buildingType, tile)) {
            builderUnit = unit;
            buildPosition = unit.position;
            break;
          }
        }
      }
      if (builderUnit == null) {
        for (final unit in faction.units) {
          if (unit is BuilderUnit) {
            final builder = unit as BuilderUnit;
            final tile = state.map.getTile(unit.position);
            if (builder.canBuild(buildingType, tile)) {
              builderUnit = unit;
              buildPosition = unit.position;
              break;
            }
          }
        }
      }
      if (builderUnit == null || buildPosition == null) {
        continue; // Versuche den nächsten Gebäudetyp
      }
      
      // Erstelle das neue Gebäude
      Building? newBuilding;
      
      switch (buildingType) {
        case BuildingType.farm:
          newBuilding = Farm.create(buildPosition, ownerID: "ai1");
          break;
        case BuildingType.barracks:
          newBuilding = Barracks.create(buildPosition, ownerID: "ai1");
          break;
        case BuildingType.lumberCamp:
          newBuilding = LumberCamp.create(buildPosition, ownerID: "ai1");
          break;
        case BuildingType.mine:
          newBuilding = Mine.create(buildPosition, ownerID: "ai1");
          break;
        default:
          continue; // Unbekannter Gebäudetyp, nächsten probieren
      }
      
      // Position als bebaut markieren
      final tile = state.map.getTile(buildPosition);
      state.map.setTile(tile.copyWith(hasBuilding: true));
      
      // Ressourcen aktualisieren
      final newResources = faction.resources.subtractMultiple(buildingCost);
      
      // Einheiten aktualisieren (Aktion verbrauchen und als gebaut markieren)
      final updatedUnits = faction.units.map((unit) {
        if (unit.id == builderUnit!.id) {
          return unit.copyWith(
            actionsLeft: 0, 
            hasBuiltSomething: true // Markiere, dass diese Einheit etwas gebaut hat
          );
        }
        return unit;
      }).toList();
      
      // Fraktion aktualisieren
      final updatedFaction = faction.copyWith(
        buildings: [...faction.buildings, newBuilding],
        resources: newResources,
        units: updatedUnits,
        currentStrategy: faction.currentStrategy, // Strategy beibehalten
      );
      
      print("KI hat ${newBuilding.displayName} an Position (${buildPosition.x}, ${buildPosition.y}) gebaut");
      
      // Update GameState with new faction and add building upgrade points
      final newState = state.copyWith(enemyFaction: updatedFaction);
      return ScoreService.addBuildingUpgradePoints(newState, newBuilding, "ai1");
    }
    
    // Wenn kein Gebäude gebaut werden konnte, Einheiten bewegen
    return _expandStrategy.execute(state, faction, difficultyScale);
  }
  
  /// Bestimmt die prioritären Gebäudetypen basierend auf dem aktuellen Spielzustand
  List<BuildingType> _determineBuildingPriorities(
    GameState state,
    EnemyFaction faction,
    int farmCount,
    int barracksCount,
    int lumberCampCount,
    int mineCount
  ) {
    List<BuildingType> priorities = [];
    
    // Frühe Phase: Fokus stark auf Ressourcengebäude
    if (state.turn < 15) {
      if (farmCount < 3) priorities.add(BuildingType.farm);
      if (lumberCampCount < 2) priorities.add(BuildingType.lumberCamp);
      if (mineCount < 2) priorities.add(BuildingType.mine);
      // Nur Barracken bauen, wenn die grundlegende Ressourceninfrastruktur vorhanden ist
      if (farmCount >= 2 && (lumberCampCount >= 1 || mineCount >= 1) && barracksCount < 1) {
        priorities.add(BuildingType.barracks);
      }
    } else if (state.turn < 25) {
      // Mittlere Phase: Ausgewogenes Wachstum, aber Fokus auf Ressourcen beibehalten
      if (farmCount < faction.units.length / 3) priorities.add(BuildingType.farm);
      if (lumberCampCount < 3) priorities.add(BuildingType.lumberCamp);
      if (mineCount < 2) priorities.add(BuildingType.mine);
      if (barracksCount < 2) priorities.add(BuildingType.barracks);
    } else {
      // Späte Phase: Militär und spezialisierte Ressourcen
      if (barracksCount < 3) priorities.add(BuildingType.barracks);
      if (farmCount < faction.units.length / 2) priorities.add(BuildingType.farm);
      if (mineCount < 3) priorities.add(BuildingType.mine);
      if (lumberCampCount < 4) priorities.add(BuildingType.lumberCamp);
    }
    
    // Berücksichtige Ressourcenengpässe mit höherer Priorität
    if (faction.resources.getAmount(ResourceType.food) < 50) {
      priorities.insert(0, BuildingType.farm);
    }
    if (faction.resources.getAmount(ResourceType.wood) < 50) {
      priorities.insert(0, BuildingType.lumberCamp);
    }
    if (faction.resources.getAmount(ResourceType.stone) < 30) {
      priorities.insert(0, BuildingType.mine);
    }
    
    // Etwas Zufall für Varianz
    if (_random.nextInt(10) < 3) {
      priorities.shuffle();
    }
    
    return priorities;
  }
  
  // Hilfsmethode: Finde ein passendes Bau-Feld in der Nähe
  Position? _findNearbyBuildableTile(GameState state, Unit unit, BuildingType buildingType, {int range = 3}) {
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        final pos = Position(x: unit.position.x + dx, y: unit.position.y + dy);
        if (!state.map.isValidPosition(pos)) continue;
        final tile = state.map.getTile(pos);
        if (tile.hasBuilding) continue;
        if (unit is BuilderUnit) {
          final builder = unit as BuilderUnit;
          if (builder.canBuild(buildingType, tile)) {
            return pos;
          }
        }
      }
    }
    return null;
  }

  // Hilfsmethode: Bewege eine Einheit einen Schritt in Richtung Ziel
  Position _moveTowards(Position from, Position to, GameState state) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    Position next = from;
    if (dx.abs() > dy.abs()) {
      next = Position(x: from.x + (dx > 0 ? 1 : -1), y: from.y);
    } else if (dy != 0) {
      next = Position(x: from.x, y: from.y + (dy > 0 ? 1 : -1));
    }
    if (state.map.isValidPosition(next) && state.map.getTile(next).isWalkable && !state.map.getTile(next).hasBuilding) {
      return next;
    }
    return from;
  }
}
