import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/services/ai/ai_strategy_engine.dart';

/// Hauptservice für die Feind-KI
/// Steuert die Ausführung von KI-Strategien und aktualisiert den Spielzustand
class AIService {
  final AIStrategyEngine _strategyEngine;
  
  AIService() : _strategyEngine = AIStrategyEngine();
  
  /// Verarbeitet einen KI-Zug und gibt den aktualisierten GameState zurück
  GameState processEnemyTurn(GameState state) {
    // Wenn keine feindliche Fraktion vorhanden ist, erstelle eine
    if (state.enemyFaction == null) {
      return _initializeEnemyFaction(state);
    }
    
    // 1. Schwierigkeitsskalierung basierend auf der Rundenanzahl
    final difficultyScale = calculateDifficultyScaling(state.turn);
    
    // 2. Ressourcen sammeln und Einheiten zurücksetzen
    final updatedFaction = _collectResources(state.enemyFaction!, difficultyScale);
    
    // 3. Strategie basierend auf dem aktuellen Spielzustand auswählen
    final strategyType = _strategyEngine.determineStrategy(state, updatedFaction);
    
    // 4. Strategie ausführen
    return _strategyEngine.executeStrategy(state, updatedFaction, strategyType, difficultyScale);
  }

  /// Berechnet den Schwierigkeitsfaktor basierend auf der aktuellen Runde
  double calculateDifficultyScaling(int turn) {
    // Ab Runde 1 steigende Schwierigkeit, begrenzt auf 2.5 (250% Stärke)
    return (turn < 5) ? 1.0 : 1.0 + (turn - 5) * 0.05 > 2.5 ? 2.5 : 1.0 + (turn - 5) * 0.05;
  }
  
  /// Initialisiert eine neue feindliche Fraktion
  /// Diese Methode wurde aus der alten KI-Klasse übernommen
  GameState _initializeEnemyFaction(GameState state) {
    // Implementation wird in einem separaten AIInitializer delegiert
    return AIStrategyEngine().initializeEnemyFaction(state);
  }
  
  /// Sammelt Ressourcen für die feindliche Fraktion und setzt Einheiten zurück
  EnemyFaction _collectResources(EnemyFaction faction, double difficultyScale) {
    return _strategyEngine.collectResources(faction, difficultyScale);
  }
}
