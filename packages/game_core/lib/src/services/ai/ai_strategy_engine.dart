import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/enemy_faction.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/resource/resources_collection.dart';
import 'package:game_core/src/services/ai/strategies/ai_attack_strategy.dart';
import 'package:game_core/src/services/ai/strategies/ai_build_strategy.dart';
import 'package:game_core/src/services/ai/strategies/ai_expand_strategy.dart';
import 'package:game_core/src/services/ai/strategies/ai_recruit_strategy.dart';
import 'package:game_core/src/services/ai/initializers/ai_faction_initializer.dart';
import 'package:game_core/src/services/ai/strategies/ai_strategy_determiner.dart';

/// Strategiemotor für die KI - bestimmt und führt Strategien aus
class AIStrategyEngine {
  final AIFactionInitializer _initializer = AIFactionInitializer();
  final AIAttackStrategy _attackStrategy = AIAttackStrategy();
  final AIBuildStrategy _buildStrategy = AIBuildStrategy();
  final AIExpandStrategy _expandStrategy = AIExpandStrategy();
  final AIRecruitStrategy _recruitStrategy = AIRecruitStrategy();
  
  /// Initialisiert eine neue feindliche Fraktion
  GameState initializeEnemyFaction(GameState state) {
    return _initializer.initialize(state);
  }

  /// Sammelt Ressourcen von Gebäuden und fügt passive Einnahmen hinzu
  EnemyFaction collectResources(EnemyFaction faction, double difficultyScale) {
    var resources = faction.resources;
    
    // 1. Einheiten zurücksetzen
    final resetUnits = faction.units.map((u) => u.resetActions()).toList();
    
    // 2. Ressourcen von existierenden Gebäuden sammeln
    resources = _collectBuildingResources(faction, resources, difficultyScale);
    
    // 3. Passive Ressourcen hinzufügen (skaliert mit Schwierigkeit)
    resources = _addPassiveResources(faction, resources, difficultyScale);
    
    return faction.copyWith(
      resources: resources,
      units: resetUnits,
    );
  }

  /// Berechnet Ressourcen von Gebäuden
  ResourcesCollection _collectBuildingResources(
    EnemyFaction faction, 
    ResourcesCollection resources,
    double difficultyScale
  ) {
    var result = resources;
    
    for (final building in faction.buildings) {
      switch (building.type) {
        case BuildingType.farm:
          result = result.add(ResourceType.food, (10 * difficultyScale * building.level).round());
          break;
        case BuildingType.mine:
          result = result.add(ResourceType.stone, (8 * difficultyScale * building.level).round());
          result = result.add(ResourceType.iron, (3 * difficultyScale * building.level).round());
          break;
        case BuildingType.lumberCamp:
          result = result.add(ResourceType.wood, (12 * difficultyScale * building.level).round());
          break;
        case BuildingType.cityCenter:
          result = result.add(ResourceType.food, (5 * difficultyScale).round());
          result = result.add(ResourceType.wood, (3 * difficultyScale).round());
          result = result.add(ResourceType.stone, (2 * difficultyScale).round());
          break;
        default:
          break;
      }
    }
    
    return result;
  }

  /// Fügt passive Ressourceneinnahmen abhängig von Schwierigkeit hinzu
  ResourcesCollection _addPassiveResources(
    EnemyFaction faction,
    ResourcesCollection resources,
    double difficultyScale
  ) {
    final buildingCount = faction.buildings.length;
    final basePassiveFood = 3 + (difficultyScale * 2).floor();
    final basePassiveWood = 2 + difficultyScale.floor();
    final basePassiveStone = 1 + (difficultyScale * 0.5).floor();
    
    // Bonus basierend auf der Anzahl der Gebäude
    final buildingBonus = buildingCount;
    
    var result = resources;
    result = result.add(ResourceType.food, basePassiveFood + buildingBonus ~/ 2);
    result = result.add(ResourceType.wood, basePassiveWood + buildingBonus ~/ 3);
    result = result.add(ResourceType.stone, basePassiveStone + buildingBonus ~/ 4);
    
    return result;
  }

  /// Bestimmt die optimale Strategie für den aktuellen Spielzustand
  String determineStrategy(GameState state, EnemyFaction faction) {
    // Implementation in separater Datei
    final result = AIStrategyDeterminer().determineStrategy(state, faction);
    if (result is Map && result.containsKey('main')) {
      return result['main']?.toString() ?? 'build';
    }
    return result?.toString() ?? 'build';
  }

  /// Führt die ausgewählte Strategie aus
  GameState executeStrategy(GameState state, EnemyFaction faction, dynamic strategy, double difficultyScale) {
    // Unterstützt jetzt Map-Objekt: {main: 'attack', alsoBuild: true}
    String mainStrategy;
    bool alsoBuild = false;
    if (strategy is Map) {
      mainStrategy = strategy['main'] ?? 'build';
      alsoBuild = strategy['alsoBuild'] == true;
    } else {
      mainStrategy = strategy?.toString() ?? 'build';
    }
    // Setze die aktuelle Strategie in der Faction
    final updatedFaction = faction.copyWith(currentStrategy: mainStrategy);
    GameState resultState;
    // Hauptstrategie ausführen
    switch (mainStrategy) {
      case 'recruit':
        resultState = _recruitStrategy.execute(state, updatedFaction, difficultyScale);
        break;
      case 'attack':
        resultState = _attackStrategy.execute(state, updatedFaction, difficultyScale);
        break;
      case 'build':
        resultState = _buildStrategy.execute(state, updatedFaction, difficultyScale);
        break;
      case 'expand':
        resultState = _expandStrategy.execute(state, updatedFaction, difficultyScale);
        break;
      default:
        resultState = state.copyWith(enemyFaction: updatedFaction);
        break;
    }
    // Falls auch gebaut werden soll und build nicht die Hauptstrategie war, führe build zusätzlich aus
    if (alsoBuild && mainStrategy != 'build') {
      resultState = _buildStrategy.execute(resultState, resultState.enemyFaction!, difficultyScale);
    }
    return resultState;
  }
}
