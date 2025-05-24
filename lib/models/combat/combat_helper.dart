import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/services/score_service.dart';

/// Hilfsfunktionen für Kampfmechaniken
class CombatHelper {
  /// Prüft, ob eine Position angreifbar ist
  /// Verwendet für Spielereinheiten, die feindliche Einheiten angreifen wollen
  static bool canAttackEnemyAt(GameState state, Unit attackingUnit, Position targetPosition) {
    // Nur Kampfeinheiten können angreifen
    if (attackingUnit.combatCapability == null) return false;
    
    // Prüfe, ob die Einheit an dieser Position angreifen kann
    if (!attackingUnit.combatCapability!.canAttackAt(attackingUnit.position, targetPosition)) return false;
    
    // Prüfe, ob an dieser Position eine feindliche Einheit oder ein Gebäude steht
    if (state.enemyFaction == null) return false;
    
    final hasEnemyUnit = state.enemyFaction!.units
        .any((unit) => unit.position == targetPosition);
    
    final hasEnemyBuilding = state.enemyFaction!.buildings
        .any((building) => building.position == targetPosition);
    
    return hasEnemyUnit || hasEnemyBuilding;
  }

  /// Führt einen Angriff einer Spielereinheit gegen eine feindliche Einheit oder Gebäude durch
  static GameState attackEnemyAt(GameState state, Unit attackingUnit, Position targetPosition) {
    if (state.enemyFaction == null) return state;
    
    // Hier angreifen (können) nur Kampfeinheiten
    if (attackingUnit.combatCapability == null) return state;
    
    // Feindliche Einheit an der Zielposition finden
    final enemyUnitsAtPosition = state.enemyFaction!.units
        .where((unit) => unit.position == targetPosition)
        .toList();
        
    if (enemyUnitsAtPosition.isNotEmpty) {
      return _attackEnemyUnit(state, attackingUnit, enemyUnitsAtPosition.first);
    }
    
    // Feindliches Gebäude an der Zielposition finden
    final enemyBuildingsAtPosition = state.enemyFaction!.buildings
        .where((building) => building.position == targetPosition)
        .toList();
        
    if (enemyBuildingsAtPosition.isNotEmpty) {
      final targetBuilding = enemyBuildingsAtPosition.first;
      // Mauern können nur beschädigt, nicht erobert werden
      if (targetBuilding is Wall) {
        return _damageEnemyBuilding(state, attackingUnit, targetBuilding);
      } else {
        return _captureEnemyBuilding(state, attackingUnit, targetBuilding);
      }
    }
    
    return state;
  }
  
  /// Führt einen Angriff auf eine feindliche Einheit durch
  static GameState _attackEnemyUnit(
      GameState state, 
      Unit attackingUnit,
      Unit targetUnit) {
    
    // Berechne Schaden
    if (targetUnit.combatCapability == null) {
      // Ziel ist keine Kampfeinheit (z.B. Farmer) – wird sofort entfernt
      List<Unit> updatedEnemyUnits = state.enemyFaction!.units
          .where((unit) => unit.id != targetUnit.id)
          .toList();
      print("Spieler hat nicht-kampffähige feindliche Einheit \\${targetUnit.type} besiegt!");
      // Aktionspunkte abziehen
      final updatedPlayerUnits = state.units.map((unit) {
        if (unit.id == attackingUnit.id) {
          return unit.copyWith(actionsLeft: 0);
        }
        return unit;
      }).toList();
      final updatedEnemyFaction = state.enemyFaction!.copyWith(
        units: updatedEnemyUnits,
      );
      return ScoreService.handleUnitKill(
        state.copyWith(
          units: updatedPlayerUnits,
          enemyFaction: updatedEnemyFaction,
        ),
        targetUnit,
        attackingUnit.ownerID
      );
    }
    int damage = attackingUnit.combatCapability!.calculateDamage(targetUnit);
    int newHealth = targetUnit.combatCapability!.currentHealth - damage;
        
    // Aktualisiere die Einheiten der feindlichen Fraktion
    List<Unit> updatedEnemyUnits;
    
    if (newHealth <= 0) {
      // Einheit wurde besiegt
      updatedEnemyUnits = state.enemyFaction!.units
          .where((unit) => unit.id != targetUnit.id)
          .toList();
      
      print("Spieler hat feindliche Einheit ${targetUnit.type} besiegt!");
    } else {
      // Aktualisiere die Zieleinheit mit neuer Gesundheit
      updatedEnemyUnits = state.enemyFaction!.units.map((unit) {
        if (unit.id == targetUnit.id) {
          return unit.copyWith(
            combatCapability: unit.combatCapability?.copyWith(
              currentHealth: newHealth
            ),
          );
        }
        return unit;
      }).toList();
    }
    
    // Verbrauche Aktionspunkte der angreifenden Einheit
    final updatedPlayerUnits = state.units.map((unit) {
      if (unit.id == attackingUnit.id) {
        return unit.copyWith(
          actionsLeft: 0 // Angriff verbraucht alle verbleibenden Aktionspunkte
        );
      }
      return unit;
    }).toList();
    
    // Aktualisiere die Feindfraktion
    final updatedEnemyFaction = state.enemyFaction!.copyWith(
      units: updatedEnemyUnits,
    );
    
    // Wenn die Einheit besiegt wurde, aktualisiere den Punktestand
    if (newHealth <= 0) {
      return ScoreService.handleUnitKill(
        state.copyWith(
          units: updatedPlayerUnits,
          enemyFaction: updatedEnemyFaction,
        ),
        targetUnit,
        attackingUnit.ownerID
      );
    }
    
    return state.copyWith(
      units: updatedPlayerUnits,
      enemyFaction: updatedEnemyFaction,
    );
  }
  
  /// Beschädigt ein feindliches Gebäude (für Mauern)
  static GameState _damageEnemyBuilding(
      GameState state, 
      Unit attackingUnit,
      Building targetBuilding) {
    
    if (attackingUnit is! CombatCapable || !(targetBuilding is Wall)) {
      return state; // Nur Kampfeinheiten können angreifen und nur Mauern können beschädigt, aber nicht erobert werden
    }
    
    final wall = targetBuilding;
    
    // Berechne Schaden (ähnlich wie bei der Berechnung von Einheitenschaden)
    // Für Mauern wird ein fester Schadenswert basierend auf dem Angriffswert der Einheit verwendet
    int damage = (attackingUnit as CombatCapable).attackValue;
    
    // Schaden auf die Mauer anwenden
    int newHealth = wall.currentHealth - damage;
    
    List<Building> updatedEnemyBuildings;
    
    if (newHealth <= 0) {
      // Mauer wurde zerstört
      updatedEnemyBuildings = state.enemyFaction!.buildings
          .where((building) => building.id != targetBuilding.id)
          .toList();
      
      print("Spieler hat feindliche Mauer zerstört!");
    } else {
      // Aktualisiere die Mauer mit neuer Gesundheit
      updatedEnemyBuildings = state.enemyFaction!.buildings.map((building) {
        if (building.id == targetBuilding.id) {
          return (building as Wall).copyWith(
            currentHealth: newHealth
          );
        }
        return building;
      }).toList();
      
      print("Spieler hat feindliche Mauer beschädigt! Verbleibende Gesundheit: $newHealth");
    }
    
    // Verbrauche Aktionspunkte der angreifenden Einheit
    final updatedPlayerUnits = state.units.map((unit) {
      if (unit.id == attackingUnit.id) {
        return unit.copyWith(
          actionsLeft: 0 // Angriff verbraucht alle verbleibenden Aktionspunkte
        );
      }
      return unit;
    }).toList();
    
    // Aktualisiere die Feindfraktion
    final updatedEnemyFaction = state.enemyFaction!.copyWith(
      buildings: updatedEnemyBuildings,
    );
    
    return state.copyWith(
      units: updatedPlayerUnits,
      enemyFaction: updatedEnemyFaction,
    );
  }
  
  /// Erobert ein feindliches Gebäude
  static GameState _captureEnemyBuilding(
      GameState state, 
      Unit attackingUnit,
      Building targetBuilding) {
    
    // Entferne das Gebäude von der feindlichen Fraktion
    final updatedEnemyBuildings = state.enemyFaction!.buildings
        .where((building) => building.id != targetBuilding.id)
        .toList();
    
    // Füge das Gebäude zu den Spielergebäuden hinzu
    final updatedPlayerBuildings = [...state.buildings, targetBuilding];
    
    // Verbrauche Aktionspunkte der angreifenden Einheit
    final updatedPlayerUnits = state.units.map((unit) {
      if (unit.id == attackingUnit.id) {
        return unit.copyWith(
          actionsLeft: 0 // Eroberung verbraucht alle verbleibenden Aktionspunkte
        );
      }
      return unit;
    }).toList();
    
    // Aktualisiere die Feindfraktion
    final updatedEnemyFaction = state.enemyFaction!.copyWith(
      buildings: updatedEnemyBuildings,
    );
    
    print("Spieler hat feindliches Gebäude vom Typ ${targetBuilding.type} erobert!");
    
    return ScoreService.handleBuildingCapture(
      state.copyWith(
        units: updatedPlayerUnits,
        buildings: updatedPlayerBuildings,
        enemyFaction: updatedEnemyFaction,
      ),
      targetBuilding,
      attackingUnit.ownerID
    );
  }
}
