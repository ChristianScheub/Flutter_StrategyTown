import 'dart:math';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/enemy_faction.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/units/unit.dart';

/// Bestimmt die optimale Strategie für den aktuellen Spielzustand
class AIStrategyDeterminer {
  final Random _random = Random();
  
  /// Bestimmt die beste Strategie basierend auf Spielstatus und eigenen Einheiten/Gebäuden
  /// Gibt jetzt ein Map-Objekt zurück: {main: 'attack', alsoBuild: true}
  dynamic determineStrategy(GameState state, EnemyFaction faction) {
    // Skalierte Aggressivität basierend auf Rundenzahl
    // Je höher die Rundenzahl, desto aggressiver wird die KI
    final scaledAggressiveness = faction.aggressiveness + (state.turn / 10).floor();
    final lateGameModifier = state.turn > 30 ? 3 : (state.turn > 15 ? 2 : 1);
    
    // Zielanzahl an Einheiten basierend auf der Rundenzahl
    // Stellt sicher, dass die KI auch im späteren Spielverlauf weiter Einheiten baut
    final targetUnitCount = 3 + (state.turn / 5).floor();
    
    // Analyse der aktuellen Militäreinheiten und verbleibenden Builder
    final militaryUnits = faction.units.where((u) => u.isCombatUnit).length;
    final buildersWithoutBuilds = faction.units.where((u) => 
        !u.isCombatUnit && u.creationTurn + 8 <= state.turn && !u.hasBuiltSomething).length;
    
    final militaryTarget = (targetUnitCount * 0.7).ceil(); // 70% sollten Militäreinheiten sein
    
    // Analyse der Gebäudetypen
    final farmCount = faction.buildings.where((b) => b.type == BuildingType.farm).length;
    final militaryBuildingCount = faction.buildings.where((b) => b.type == BuildingType.barracks).length;
    final resourceBuildingCount = faction.buildings.where((b) => 
        b.type == BuildingType.mine || b.type == BuildingType.lumberCamp).length;
    
    // Analyse der Ressourcensituation
    final hasEnoughFood = faction.resources.getAmount(ResourceType.food) >= 30;
    final hasEnoughWood = faction.resources.getAmount(ResourceType.wood) >= 25;
    final hasEnoughStone = faction.resources.getAmount(ResourceType.stone) >= 15;
    final hasGoodResources = hasEnoughFood && hasEnoughWood && hasEnoughStone;
    
    // Spielerbedrohungsanalyse - Prüfe ob Spieler in der Nähe ist 
    // (durch Distanz zwischen Einheiten oder Stadt-Zentren)
    final isPlayerNearby = _isPlayerProximityThreat(state, faction);
    
    // Truppenstärkenanalyse
    final playerMilitaryStrength = _calculateMilitaryStrength(state.units.where((u) => u.isCombatUnit).toList());
    final aiMilitaryStrength = _calculateMilitaryStrength(faction.units.where((u) => u.isCombatUnit).toList());
    final strengthRatio = playerMilitaryStrength > 0 ? 
        aiMilitaryStrength / playerMilitaryStrength : 1.5; // Ratio > 1 means AI is stronger
    
    // --- bisherige Entscheidungslogik ---
    String mainStrategy = (() {
      // Priorität 1: Bauen mit "überfälligen" Builder-Einheiten
      if (buildersWithoutBuilds > 0) {
        return 'build';
      }
      // Priorität 2: Verteidigungsstrategie (wenn in Gefahr und schwach)
      if (isPlayerNearby && strengthRatio < 0.8) {
        // Spieler ist nahe und wir sind schwächer - rekrutiere mehr Militäreinheiten!
        return militaryBuildingCount > 0 ? 'recruit' : 'build';
      }
      // Priorität 3: Angriffsstrategie (wenn stark genug und nahe am Spieler)
      if (militaryUnits >= 5 && (strengthRatio > 1.0 || state.turn > 25) && isPlayerNearby) {
        // Wir sind stark genug für einen Angriff!
        final attackProbability = 40 + (strengthRatio * 20).floor() + (state.turn / 2).floor();
        return (_random.nextInt(100) < attackProbability) ? 'attack' : 'expand';
      }
      // Priorität 4: Aufbaustrategie basierend auf Ressourcen und Einheiten
      // 4.1 Wenn wir zu wenige Einheiten haben, rekrutieren oder expandieren wir
      if (faction.units.length < targetUnitCount) {
        return (hasGoodResources && _random.nextInt(10) < 7) ? 'recruit' : 'expand';
      }
      // 4.2 Wenn wir genügend Militäreinheiten haben, opportunistisch angreifen
      if (militaryUnits >= 3 && (scaledAggressiveness > 5 || state.turn > 25)) {
        // Im späteren Spielverlauf: erhöhte Angriffswahrscheinlichkeit
        final attackProbability = 30 + (state.turn / 2).floor() + (strengthRatio * 15).floor();
        return (_random.nextInt(100) < attackProbability) ? 'attack' : 'expand';
      }
      // 4.3 Ressourcengebäude-Balance
      if (farmCount < faction.units.length / 4) {
        return 'build'; // Priorisiere Nahrungsproduktion
      }
      // 4.4 Militärische Balance
      if (faction.units.length >= targetUnitCount && militaryUnits < militaryTarget) {
        return militaryBuildingCount > 0 ? 'recruit' : 'build';
      }
      // 4.5 Ressourcengebäude-Balance
      if (resourceBuildingCount < faction.units.length / 5) {
        return 'build';
      }
      // 4.6 Militärische Gebäude
      if (militaryBuildingCount == 0 && faction.units.length > 5) {
        return 'build';
      }
      // Standardstrategie: Balance zwischen den verschiedenen Optionen basierend auf Spielphase
      final randomChoice = _random.nextInt(10);
      if (randomChoice < 3 * lateGameModifier) {
        return 'expand';
      } else if (randomChoice < 6 * lateGameModifier) {
        return 'build';
      } else if (randomChoice < 8 * lateGameModifier) {
        return 'recruit';
      } else {
        return strengthRatio > 0.9 ? 'attack' : 'recruit';
      }
    })();
    // --- Ende Entscheidungslogik ---
    // Prüfe, ob zivile Einheiten existieren, die bauen können
    final hasCivilianBuilder = faction.units.any((u) => !u.isCombatUnit && u.actionsLeft > 0);
    // Wenn Builder vorhanden, immer auch Build-Flag setzen
    if (hasCivilianBuilder) {
      return {'main': mainStrategy, 'alsoBuild': true};
    } else {
      return {'main': mainStrategy, 'alsoBuild': false};
    }
  }
  
  /// Überprüft, ob sich der Spieler in gefährlicher Nähe befindet
  bool _isPlayerProximityThreat(GameState state, EnemyFaction faction) {
    // Konstanten für die Bedrohungsanalyse
    const PROXIMITY_THRESHOLD = 10; // Schwellwert für "nah"
    
    // Prüfe Einheitenproximität - gibt es feindliche Einheiten in der Nähe unserer Einheiten?
    for (final aiUnit in faction.units) {
      for (final playerUnit in state.units) {
        if (aiUnit.position.manhattanDistance(playerUnit.position) < PROXIMITY_THRESHOLD) {
          return true;
        }
      }
    }
    
    // Prüfe Stadt-Zentren-Proximität
    final aiCityCenters = faction.buildings.where((b) => b.type == BuildingType.cityCenter).toList();
    final playerCityCenters = state.buildings.where((b) => b.type == BuildingType.cityCenter).toList();
    
    for (final aiCity in aiCityCenters) {
      for (final playerCity in playerCityCenters) {
        if (aiCity.position.manhattanDistance(playerCity.position) < PROXIMITY_THRESHOLD * 2) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// Berechnet die militärische Stärke einer Gruppe von Einheiten
  double _calculateMilitaryStrength(List<dynamic> units) {
    double totalStrength = 0;
    
    for (final unit in units) {
      // Grundstärke basierend auf den Einheitenstats
      double unitStrength = unit.attackValue * 1.5 + unit.defenseValue;
      
      // Gesundheitsmodifikator
      if (unit.maxHealth > 0) {
        unitStrength *= (unit.currentHealth / unit.maxHealth);
      }
      
      // Einheitentyp-Bonusfaktoren
      if (unit.type == UnitType.archer) {
        unitStrength *= 1.2; // Fernkampfbonus
      }
      if (unit.type == UnitType.knight) {
        unitStrength *= 1.3; // Stärkere Kampfeinheit
      }
      
      totalStrength += unitStrength;
    }
    
    return totalStrength;
  }
}
