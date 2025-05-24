import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/services/score_service.dart';

class CombatSystem {
  /// Führt einen Angriff zwischen zwei Einheiten durch
  static GameState performAttack(GameState state, Unit attacker, Unit defender) {
    if (!_canAttack(attacker, defender)) {
      return state;
    }

    // Berechne den Schaden basierend auf der Angriffskraft
    final damage = _calculateDamage(attacker, defender);
    
    // Print debug information to track tower attacks
    if (attacker.type == UnitType.virtualTower) {
      print('🗼 Tower attack: Damage = $damage, Target = ${defender.type}, Target Health = ${defender.currentHealth}');
    }
    
    // Wenn der Verteidiger kein combatCapability hat (z.B. Farmer), sofort entfernen
    if (defender.combatCapability == null) {
      bool defenderIsAI = state.enemyFaction?.units.any((u) => u.id == defender.id) ?? false;
      bool attackerIsAI = state.enemyFaction?.buildings.any((b) => b.id == attacker.id.split('_')[0]) ?? false;
      
      if (attacker.type == UnitType.virtualTower) {
        print('🗼 Tower killed (non-combat) ${defender.type}!');
        // Verwende ScoreService für Turmangriffe - use attacker's ownerID for tower kills
        state = ScoreService.handleUnitKill(state, defender, attacker.ownerID, isTowerKill: true);
      } else {
        // Verwende ScoreService für normale Angriffe
        state = ScoreService.handleUnitKill(state, defender, attacker.ownerID);
      }
      
      if (defenderIsAI) {
        final updatedEnemyUnits = state.enemyFaction!.units
            .where((unit) => unit.id != defender.id)
            .toList();
        final updatedEnemyFaction = state.enemyFaction!.copyWith(
          units: updatedEnemyUnits,
          currentStrategy: state.enemyFaction!.currentStrategy,
        );
        return state.copyWith(
          enemyFaction: updatedEnemyFaction,
        );
      } else {
        final updatedPlayerUnits = state.units
            .where((unit) => unit.id != defender.id)
            .toList();
        return state.copyWith(
          units: updatedPlayerUnits,
        );
      }
    }

    // Calculate defender's new health
    final updatedDefender = defender.copyWith(
      combatCapability: defender.combatCapability?.copyWith(
        currentHealth: defender.currentHealth - damage
      )
    );

    // Punktesystem: Punkte für besiegte Einheiten
    bool defenderDefeated = updatedDefender.currentHealth <= 0;
    bool defenderIsAI = state.enemyFaction?.units.any((u) => u.id == defender.id) ?? false;
    bool attackerIsAI = state.enemyFaction?.buildings.any((b) => b.id == attacker.id.split('_')[0]) ?? false;

    if (defenderDefeated) {
      if (attacker.type == UnitType.virtualTower) {
        print('🗼 Tower killed ${defender.type}!');
        // Verwende ScoreService für Turmangriffe - use attacker's ownerID for tower kills
        state = ScoreService.handleUnitKill(state, defender, attacker.ownerID, isTowerKill: true);
      } else {
        // Verwende ScoreService für normale Angriffe
        state = ScoreService.handleUnitKill(state, defender, attacker.ownerID);
      }
    }

    // Print result after damage
    if (attacker.type == UnitType.virtualTower) {
      print('🗼 After attack: Target Health = ${updatedDefender.currentHealth}');
    }

    // Wenn der Verteidiger eine feindliche Einheit ist
    if (state.enemyFaction?.units.any((u) => u.id == defender.id) ?? false) {
      // Only keep units with health above zero
      final updatedEnemyUnits = state.enemyFaction!.units
          .map((unit) => unit.id == defender.id ? updatedDefender : unit)
          .where((unit) => unit.currentHealth > 0)
          .toList();

      final updatedEnemyFaction = state.enemyFaction!.copyWith(
        units: updatedEnemyUnits,
        currentStrategy: state.enemyFaction!.currentStrategy,
      );

      return state.copyWith(
        enemyFaction: updatedEnemyFaction,
      );
    } 
    // Wenn der Verteidiger eine Spielereinheit ist
    else {
      // Only keep units with health above zero
      final updatedPlayerUnits = state.units
          .map((unit) => unit.id == defender.id ? updatedDefender : unit)
          .where((unit) => unit.currentHealth > 0)
          .toList();

      return state.copyWith(
        units: updatedPlayerUnits,
      );
    }
  }

  /// Berechnet den verursachten Schaden
  static int _calculateDamage(Unit attacker, Unit defender) {
    if (attacker.combatCapability == null) return 0;
    
    return attacker.combatCapability!.calculateDamage(defender);
  }

  /// Überprüft, ob ein Angriff möglich ist
  static bool _canAttack(Unit attacker, Unit defender) {
    // Nur Einheiten mit Kampffähigkeiten können angreifen
    if (attacker.combatCapability == null) return false;
    
    // Überprüfe die Angriffreichweite
    if (!attacker.combatCapability!.canAttackAt(
      attacker.position, 
      defender.position
    )) return false;
    
    // Überprüfe, ob der Angreifer genügend Aktionspunkte hat
    if (attacker.actionsLeft <= 0) return false;
    
    // Überprüfe, ob der Verteidiger eine Lebensverfolgung hat
    if (defender.combatCapability == null && defender.currentHealth <= 0) return false;
    
    return true;
  }
}
