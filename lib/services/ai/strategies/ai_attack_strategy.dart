import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/services/ai/utilities/ai_combat_evaluator.dart';
import 'package:flutter_sim_city/services/score_service.dart';

/// Strategie für das Angreifen von Spielereinheiten und -gebäuden
class AIAttackStrategy {
  
  /// Führt die Angriffsstrategie aus
  GameState execute(GameState state, EnemyFaction faction, double difficultyScale) {
    var playerUnits = List<Unit>.from(state.units);
    var playerBuildings = List<Building>.from(state.buildings);
    var enemyUnits = List<Unit>.from(faction.units);
    
    int allowedAttacks = _calculateAllowedAttacks(state.turn);
    int attacksMade = 0;
    
    // Get combat-capable enemy units
    final combatUnits = enemyUnits
        .where((u) => u.isCombatUnit && u.canAct)
        .toList();
    
    // First evaluate the survival chances of each combat unit
    for (final unit in combatUnits) {
      // Check survival chance in current position
      final survivalChance = AICombatEvaluator.calculateSurvivalChance(state, unit);
      final hasSupport = AICombatEvaluator.hasSupportNearby(state, unit, true);
      
      if (survivalChance < 0.5 && !hasSupport) {
        // Unit is in danger and alone - retreat instead of attacking
        final retreatPos = AICombatEvaluator.getRetreatDirection(state, unit);
        final unitIndex = enemyUnits.indexWhere((u) => u.id == unit.id);
        if (unitIndex != -1) {
          // Move towards retreat position
          final newPos = _moveTowardsPosition(unit.position, retreatPos, state);
          if (newPos != unit.position) {
            enemyUnits[unitIndex] = unit.copyWith(
              position: newPos,
              actionsLeft: 0
            );
          }
        }
        continue; // Skip attack with this unit
      }
      
      // Unit is safe enough to attack - look for targets
      if (attacksMade >= allowedAttacks) break;
      
      // Look for the best target based on tactical evaluation
      final target = _findBestTarget(state, unit, playerUnits);
      if (target != null) {
        final targetIndex = playerUnits.indexWhere((u) => u.id == target.id);
        if (targetIndex != -1) {
          playerUnits.removeAt(targetIndex);
          
          final updatedUnit = unit.copyWith(actionsLeft: 0);
          final unitIndex = enemyUnits.indexWhere((u) => u.id == unit.id);
          if (unitIndex != -1) {
            enemyUnits[unitIndex] = updatedUnit;
          }
          
          print("Enemy ${unit.type} attacked and defeated player ${target.type}!");
          attacksMade++;
          state = ScoreService.handleUnitKill(state, target, "ai1");
        }
      }
    }
    
    // Now try to attack buildings if we still have attacks available
    if (attacksMade < allowedAttacks) {
      final remainingUnits = enemyUnits
          .where((u) => u.isCombatUnit && u.canAct)
          .toList();
          
      for (final unit in remainingUnits) {
        if (attacksMade >= allowedAttacks) break;
        
        // Evaluate survival chance before attacking building
        final survivalChance = AICombatEvaluator.calculateSurvivalChance(state, unit);
        final hasSupport = AICombatEvaluator.hasSupportNearby(state, unit, true);
        
        if (survivalChance < 0.3 && !hasSupport) {
          continue; // Too dangerous to attack building
        }
        
        // Find best target building - prioritizing regular buildings over defensive structures
        Building? targetBuilding;
        int closestDistance = 999;
        int targetIndex = -1;
        bool isRegularBuildingFound = false;
        bool isDefensiveStructureFound = false;
        bool isBlockingWallFound = false;
        
        // First pass: Find nearby walls that are blocking paths to valuable targets
        for (int i = 0; i < playerBuildings.length; i++) {
          final building = playerBuildings[i];
          final distance = unit.position.manhattanDistance(building.position);
          
          // Check for walls that block path to valuable targets
          if (distance <= 1 && building.type == BuildingType.wall) {
            // Check if this wall is blocking path to a valuable target
            final isBlockingPath = _isWallBlockingPathToValueableTarget(state, building);
            
            if (isBlockingPath) {
              // Count nearby friendly units that could help attack this wall
              final nearbyAllies = _countNearbyAlliesForWallAttack(state, faction, building.position);
              
              // Only attack walls if we have enough units nearby (at least 2 for coordination)
              if (nearbyAllies >= 2) {
                targetBuilding = building;
                closestDistance = distance;
                targetIndex = i;
                isBlockingWallFound = true;
                break; // Prioritize this coordinated wall attack
              }
            }
          }
        }
        
        // If no blocking wall attack is planned, proceed with normal targeting
        if (!isBlockingWallFound) {
          for (int i = 0; i < playerBuildings.length; i++) {
            final building = playerBuildings[i];
            final distance = unit.position.manhattanDistance(building.position);
            
            // Only attack buildings in range
            if (distance <= 1) {
              final isDefensive = building.type == BuildingType.wall || 
                                building.type == BuildingType.defensiveTower;
              
              // Always prioritize regular buildings (non-defensive)
              if (!isDefensive && (!isRegularBuildingFound || distance < closestDistance)) {
                targetBuilding = building;
                closestDistance = distance;
                targetIndex = i;
                isRegularBuildingFound = true;
              } 
              // Only consider defensive structures if no regular buildings are in range
              // or if the defensive structure is actively attacking our units
              else if (!isRegularBuildingFound) {
                if (building.type == BuildingType.defensiveTower) {
                  // Check if this tower is actively threatening our units
                  final isThreatening = _isTowerThreateningOurUnits(state, building, faction);
                  if (isThreatening && (!isDefensiveStructureFound || distance < closestDistance)) {
                    targetBuilding = building;
                    closestDistance = distance;
                    targetIndex = i;
                    isDefensiveStructureFound = true;
                  }
                }
                else if (!isDefensiveStructureFound || distance < closestDistance) {
                  targetBuilding = building;
                  closestDistance = distance;
                  targetIndex = i;
                  isDefensiveStructureFound = true;
                }
              }
            }
          }
        }
        
        if (targetBuilding != null && targetIndex >= 0) {
          playerBuildings.removeAt(targetIndex);
          
          final updatedUnit = unit.copyWith(actionsLeft: 0);
          final unitIndex = enemyUnits.indexWhere((u) => u.id == unit.id);
          if (unitIndex != -1) {
            enemyUnits[unitIndex] = updatedUnit;
          }
          
          print("Enemy ${unit.type} captured ${targetBuilding.type}!");
          attacksMade++;
          // Verwende den ScoreService für die Punkteberechnung
          if (targetBuilding.type != BuildingType.defensiveTower && targetBuilding.type != BuildingType.wall) {
            state = ScoreService.handleBuildingCapture(state, targetBuilding, "ai1");
          }
        }
      }
    }
    
    // Update faction with modified units
    final updatedFaction = faction.copyWith(
      units: enemyUnits,
      currentStrategy: faction.currentStrategy
    );
    
    return state.copyWith(
      units: playerUnits,
      buildings: playerBuildings,
      enemyFaction: updatedFaction
    );
  }
  
  /// Calculate allowed attacks based on game phase
  int _calculateAllowedAttacks(int turn) {
    if (turn > 30) return 3;
    if (turn > 15) return 2;
    return 1;
  }
  
  /// Find the most advantageous target based on tactical evaluation
  Unit? _findBestTarget(GameState state, Unit attacker, List<Unit> playerUnits) {
    Unit? bestTarget;
    double bestScore = -1;
    
    for (final target in playerUnits) {
      final distance = attacker.position.manhattanDistance(target.position);
      if (distance > 1) continue; // Must be adjacent to attack
      
      // Calculate target score based on multiple factors
      double score = 0;
      
      // Prefer low health targets
      score += (1 - target.currentHealth / target.maxHealth) * 2;
      
      // Prefer isolated targets
      if (!AICombatEvaluator.hasSupportNearby(state, target, false)) {
        score += 1;
      }
      
      // Consider target's combat capabilities - strongly prefer civilian targets
      if (!target.isCombatUnit) {
        score += 2.0; // Higher preference for civilian targets
      }
      
      // Check if target is blocking path to valuable buildings
      if (_isUnitBlockingPathToValueableTarget(state, target)) {
        score += 1.5; // Prioritize units blocking path to valuable targets
      }
      
      // Consider our own safety after the attack
      final postAttackSurvival = AICombatEvaluator.calculateSurvivalChance(state, attacker);
      score *= postAttackSurvival; // Scale score by our survival chance
      
      if (score > bestScore) {
        bestScore = score;
        bestTarget = target;
      }
    }
    
    return bestTarget;
  }
  
  /// Move towards a position while respecting map boundaries and obstacles
  Position _moveTowardsPosition(Position current, Position target, GameState state) {
    final dx = target.x - current.x;
    final dy = target.y - current.y;
    
    Position newPos;
    if (dx.abs() > dy.abs()) {
      newPos = Position(
        x: current.x + (dx > 0 ? 1 : -1),
        y: current.y
      );
    } else {
      newPos = Position(
        x: current.x,
        y: current.y + (dy > 0 ? 1 : -1)
      );
    }
    
    // Verify new position is valid
    final tile = state.map.getTile(newPos);
    if (!tile.isWalkable || tile.hasBuilding) {
      return current;
    }
    
    return newPos;
  }
  
  /// Determines if a unit is blocking path to a valuable target
  /// (regular buildings, city centers, resource buildings)
  bool _isUnitBlockingPathToValueableTarget(GameState state, Unit targetUnit) {
    // Define valuable targets (player buildings)
    final valuableBuildings = state.buildings.where((b) {
      return b.type == BuildingType.cityCenter || 
             b.type == BuildingType.farm ||
             b.type == BuildingType.mine ||
             b.type == BuildingType.lumberCamp ||
             b.type == BuildingType.barracks;
    }).toList();
    
    if (valuableBuildings.isEmpty) return false;
    
    // Check if the unit is adjacent to any defensive structure
    final isAdjacentToDefense = state.buildings.any((b) {
      return (b.type == BuildingType.wall || b.type == BuildingType.defensiveTower) &&
             targetUnit.position.manhattanDistance(b.position) <= 1;
    });
    
    // Check if any valuable building is in close proximity (within 4 tiles)
    final isNearValuableTarget = valuableBuildings.any((b) {
      return targetUnit.position.manhattanDistance(b.position) <= 4;
    });
    
    // Unit is considered blocking if it's near a valuable target and adjacent to defense
    return isAdjacentToDefense && isNearValuableTarget;
  }
  
  /// Determines if a wall is blocking path to a valuable target
  bool _isWallBlockingPathToValueableTarget(GameState state, Building wall) {
    if (wall.type != BuildingType.wall) return false;
    
    // Define valuable targets (player buildings)
    final valuableBuildings = state.buildings.where((b) {
      return b.type == BuildingType.cityCenter || 
             b.type == BuildingType.farm ||
             b.type == BuildingType.mine ||
             b.type == BuildingType.lumberCamp ||
             b.type == BuildingType.barracks;
    }).toList();
    
    if (valuableBuildings.isEmpty) return false;
    
    // Check if any valuable building is in close proximity (within 5 tiles)
    final isNearValuableTarget = valuableBuildings.any((b) {
      return wall.position.manhattanDistance(b.position) <= 5;
    });
    
    return isNearValuableTarget;
  }
  
  /// Counts nearby allied units that could help attack a wall
  int _countNearbyAlliesForWallAttack(GameState state, EnemyFaction faction, Position wallPosition) {
    // Combat units within 3 tiles could potentially help attack
    const ATTACK_COORDINATION_RANGE = 3;
    
    // Count ally combat units within range
    int nearbyAllies = 0;
    for (final unit in faction.units) {
      if (unit.isCombatUnit && 
          unit.canAct && 
          unit.position.manhattanDistance(wallPosition) <= ATTACK_COORDINATION_RANGE) {
        nearbyAllies++;
      }
    }
    
    return nearbyAllies;
  }
  
  /// Checks if a defensive tower is actively threatening our units
  bool _isTowerThreateningOurUnits(GameState state, Building tower, EnemyFaction faction) {
    if (tower.type != BuildingType.defensiveTower) return false;
    
    // Tower attack range is typically 3 tiles
    const TOWER_RANGE = 3;
    
    // Check if any of our units are within tower attack range
    return faction.units.any((unit) => 
      tower.position.manhattanDistance(unit.position) <= TOWER_RANGE);
  }
}
