import 'dart:math';
import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/services/ai/utilities/ai_combat_evaluator.dart';

/// Strategie für die Erweiterung des Territoriums und die Bewegung von Einheiten
class AIExpandStrategy {
  final Random _random = Random();
  
  /// Führt die Erweiterungsstrategie aus
  GameState execute(GameState state, EnemyFaction faction, double difficultyScale) {
    return _moveUnitsTowardsPlayer(state, faction);
  }
  
  /// Bewegt Einheiten in Richtung Spieler
  GameState _moveUnitsTowardsPlayer(GameState state, EnemyFaction faction) {
    // Sammle Spielerpositionen - Einheiten und Gebäude
    List<Position> playerUnitPositions = state.units.map((u) => u.position).toList();
    List<Position> playerBuildingPositions = state.buildings.map((b) => b.position).toList();
    
    // Wenn keine Spielerziele gefunden wurden, Standard ist Kartenmitte
    if (playerUnitPositions.isEmpty && playerBuildingPositions.isEmpty) {
      return state.copyWith(enemyFaction: faction);
    }
    
    final isLateGame = state.turn > 20;
    final updatedUnits = faction.units.map((unit) {
      if (!unit.canAct) return unit;
      
      // First evaluate the unit's safety
      final survivalChance = AICombatEvaluator.calculateSurvivalChance(state, unit);
      final hasSupport = AICombatEvaluator.hasSupportNearby(state, unit, true);
      Position? targetPosition;
      
      // Handle different unit types differently
      if (unit.isCombatUnit) {
        // Military units are more aggressive
        if (survivalChance < 0.4 && !hasSupport) {
          // Retreat if in serious danger and alone
          targetPosition = AICombatEvaluator.getRetreatDirection(state, unit);
        } else {
          // Otherwise, move towards objectives
          targetPosition = _selectMilitaryTargetPosition(
            unit, 
            playerUnitPositions, 
            playerBuildingPositions,
            survivalChance
          );
        }
      } else {
        // Civilian units are more cautious
        if (survivalChance < 0.7) {
          // Retreat to safety at lower health threshold
          targetPosition = AICombatEvaluator.getRetreatDirection(state, unit);
        } else {
          // Select expansion position away from threats
          targetPosition = _selectCivilianTargetPosition(
            state,
            unit,
            playerBuildingPositions,
            isLateGame
          );
        }
      }
      
      final newPos = _moveTowardsPosition(unit.position, targetPosition, state);
      if (newPos != unit.position) {
        return unit.copyWith(
          position: newPos,
          actionsLeft: unit.actionsLeft - 1
        );
      }
      
      return unit;
    }).toList();
    
    // Fraktion aktualisieren
    final updatedFaction = faction.copyWith(
      units: updatedUnits,
      currentStrategy: faction.currentStrategy
    );
    
    return state.copyWith(enemyFaction: updatedFaction);
  }
  
  /// Select target position for military units based on tactical evaluation
  Position _selectMilitaryTargetPosition(
    Unit unit,
    List<Position> playerUnitPositions,
    List<Position> playerBuildingPositions,
    double survivalChance
  ) {
    if (playerUnitPositions.isEmpty && playerBuildingPositions.isEmpty) {
      return unit.position;
    }
    
    // If unit is healthy, be more aggressive
    if (survivalChance > 0.7) {
      if (playerUnitPositions.isNotEmpty) {
        return _findClosestPosition(unit.position, playerUnitPositions);
      }
    }
    
    // Otherwise, prefer buildings as safer targets
    if (playerBuildingPositions.isNotEmpty) {
      return _findClosestPosition(unit.position, playerBuildingPositions);
    }
    
    return playerUnitPositions.first;
  }
  
  /// Select target position for civilian units with awareness of threats
  Position _selectCivilianTargetPosition(
    GameState state,
    Unit unit,
    List<Position> playerBuildingPositions,
    bool isLateGame
  ) {
    if (playerBuildingPositions.isEmpty) {
      return unit.position;
    }
    
    if (isLateGame) {
      // Calculate player territory center
      final playerCenter = _calculateCentroid(playerBuildingPositions);
      
      // Move away from player center while avoiding threats
      int dx = unit.position.x - playerCenter.x;
      int dy = unit.position.y - playerCenter.y;
      
      // Normalize direction
      if (dx != 0) dx = dx ~/ dx.abs();
      if (dy != 0) dy = dy ~/ dy.abs();
      
      // Create several candidate positions
      final candidates = <Position>[
        Position(x: unit.position.x + dx * 3, y: unit.position.y + dy * 3),
        Position(x: unit.position.x + dx * 3, y: unit.position.y),
        Position(x: unit.position.x, y: unit.position.y + dy * 3),
      ];
      
      // Find the safest candidate position
      Position safestPos = unit.position;
      double bestSafety = 0;
      
      for (final pos in candidates) {
        // Check if position is valid on map
        if (!state.map.isValidPosition(pos)) continue;
        
        final tile = state.map.getTile(pos);
        if (!tile.isWalkable || tile.hasBuilding) continue;
        
        // Create a temporary unit at this position to evaluate safety
        final testUnit = unit.copyWith(position: pos);
        final safety = AICombatEvaluator.calculateSurvivalChance(state, testUnit);
        
        if (safety > bestSafety) {
          bestSafety = safety;
          safestPos = pos;
        }
      }
      
      return safestPos;
    } else {
      // Early game: Choose random expansion direction
      final angle = _random.nextDouble() * 2 * pi;
      final distance = 5;
      final targetPos = Position(
        x: unit.position.x + (cos(angle) * distance).round(),
        y: unit.position.y + (sin(angle) * distance).round()
      );
      
      // Validate the position
      if (state.map.isValidPosition(targetPos)) {
        return targetPos;
      }
      return unit.position;
    }
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
    if (!state.map.isValidPosition(newPos)) return current;
    
    final tile = state.map.getTile(newPos);
    if (!tile.isWalkable || tile.hasBuilding) {
      return current;
    }
    
    return newPos;
  }
  
  /// Hilfsmethod: Findet die nächste Position aus einer Liste von Positionen
  Position _findClosestPosition(Position source, List<Position> targets) {
    Position closest = targets.first;
    int minDistance = source.manhattanDistance(closest);
    
    for (var pos in targets) {
      int distance = source.manhattanDistance(pos);
      if (distance < minDistance) {
        closest = pos;
        minDistance = distance;
      }
    }
    
    return closest;
  }
  
  /// Hilfsmethod: Berechnet den Schwerpunkt (Centroid) einer Gruppe von Positionen
  Position _calculateCentroid(List<Position> positions) {
    if (positions.isEmpty) {
      return Position(x: 0, y: 0);
    }
    
    int sumX = positions.fold(0, (sum, pos) => sum + pos.x);
    int sumY = positions.fold(0, (sum, pos) => sum + pos.y);
    
    return Position(
      x: sumX ~/ positions.length,
      y: sumY ~/ positions.length
    );
  }
}
