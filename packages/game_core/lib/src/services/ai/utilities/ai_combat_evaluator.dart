import 'dart:math';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/buildings/building.dart';

/// Utility class to evaluate combat situations and make tactical decisions
class AICombatEvaluator {
  /// Calculates survival chance (0.0 to 1.0) for a unit in its current position
  static double calculateSurvivalChance(GameState state, Unit unit) {
    // Get all defensive towers in range
    final towersInRange = _getDefensiveTowersInRange(state, unit.position);
    if (towersInRange.isEmpty) return 1.0;
    
    // Base survival chance starts at 1.0 and decreases with each threat
    double survivalChance = 1.0;
    
    // Defensive towers typically deal 20 damage
    const towerDamage = 20;
    
    // Calculate damage from all towers
    final totalPotentialDamage = towersInRange.length * towerDamage;
    
    // Calculate survival chance based on health and potential damage
    survivalChance = (unit.currentHealth - totalPotentialDamage) / unit.maxHealth;
    
    // Clamp between 0 and 1
    return survivalChance.clamp(0.0, 1.0);
  }
  
  /// Checks if there are friendly units nearby that could help
  static bool hasSupportNearby(GameState state, Unit unit, bool isEnemy) {
    const supportRange = 2; // Units within 2 tiles are considered nearby
    final allies = isEnemy ? state.enemyFaction?.units ?? [] : state.units;
    
    for (final ally in allies) {
      if (ally.id == unit.id) continue;
      
      if (unit.position.manhattanDistance(ally.position) <= supportRange) {
        return true;
      }
    }
    return false;
  }
  
  /// Returns the best retreat direction away from threats
  static Position getRetreatDirection(GameState state, Unit unit) {
    // Get threatening towers
    final towersInRange = _getDefensiveTowersInRange(state, unit.position);
    if (towersInRange.isEmpty) return unit.position;
    
    // Calculate average threat position
    final avgX = towersInRange.map((t) => t.position.x).reduce((a, b) => a + b) / towersInRange.length;
    final avgY = towersInRange.map((t) => t.position.y).reduce((a, b) => a + b) / towersInRange.length;
    
    // Move in opposite direction
    final dx = unit.position.x - avgX;
    final dy = unit.position.y - avgY;
    
    // Normalize direction
    final magnitude = _magnitude(dx, dy);
    if (magnitude == 0) return unit.position;
    
    final normalizedDx = dx / magnitude;
    final normalizedDy = dy / magnitude;
    
    // Return a position 3 tiles away in retreat direction
    return Position(
      x: unit.position.x + (normalizedDx * 3).round(),
      y: unit.position.y + (normalizedDy * 3).round()
    );
  }

  /// Gets all defensive towers that can attack a given position
  static List<Building> _getDefensiveTowersInRange(GameState state, Position pos) {
    const towerRange = 3; // Defensive towers have a range of 3 tiles
    final towers = <Building>[];
    
    // Check player towers
    for (final building in state.buildings) {
      if (building.type == BuildingType.defensiveTower &&
          building.position.manhattanDistance(pos) <= towerRange) {
        towers.add(building);
      }
    }
    
    // Check enemy towers
    if (state.enemyFaction != null) {
      for (final building in state.enemyFaction!.buildings) {
        if (building.type == BuildingType.defensiveTower &&
            building.position.manhattanDistance(pos) <= towerRange) {
          towers.add(building);
        }
      }
    }
    
    return towers;
  }
  
  /// Calculate magnitude of a 2D vector
  static double _magnitude(double x, double y) {
    return sqrt(x * x + y * y);
  }
}
