import 'dart:math';
import 'package:flutter_sim_city/models/buildings/city_center.dart';
import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile_map.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:flutter_sim_city/services/score_service.dart';

/// Initialisiert eine neue feindliche Fraktion
class AIFactionInitializer {
  final Random _random = Random();
  
  /// Initialisiert eine neue feindliche Fraktion an einer geeigneten Position
  GameState initialize(GameState state) {
    // Geeignete Position für die feindliche Stadt finden
    final Position position = _findSuitableLocation(state.map, state.units);
    
    // Erstelle die feindliche Fraktion
    final faction = EnemyFaction.create("Feindliche Zivilisation", position);
    
    // Erstelle ein City Center und füge es der Fraktion hinzu
    final cityCenter = CityCenter.create(position);
    
    // Diese Position auf der Karte als bebaut markieren
    final tile = state.map.getTile(position);
    state.map.setTile(tile.copyWith(hasBuilding: true));
    
    // Erstelle einen Farmer als erste Einheit (friedlicher Start)
    final farmer = UnitFactory.createUnit(
      UnitType.farmer, 
      Position(x: position.x, y: position.y + 1)
    );
    
    // Erstelle einen Siedler als zweite Einheit
    final settler = UnitFactory.createUnit(
      UnitType.settler,
      Position(x: position.x - 1, y: position.y)
    );
    
    // Aktualisiere die Fraktion
    final updatedFaction = faction.copyWith(
      buildings: [cityCenter],
      units: [farmer, settler],
    );
    
    // Aktualisiere den GameState mit Punkten für die KI
    return ScoreService.addCityFoundationPoints(
      state.copyWith(enemyFaction: updatedFaction),
      false
    );
  }

  /// Findet eine geeignete Position für die Gründung einer feindlichen Stadt
  Position _findSuitableLocation(TileMap map, List<Unit> playerUnits) {
    // Maximale Versuche, eine Position zu finden
    const int maxAttempts = 20;
    
    // Mindestabstand zu Spielereinheiten
    const int minDistanceToPlayer = 7;
    
    for (int i = 0; i < maxAttempts; i++) {
      // Zufällige Position in angemessener Entfernung generieren
      final x = _random.nextInt(30) - 15; // -15 bis 15
      final y = _random.nextInt(30) - 15; // -15 bis 15
      
      final position = Position(x: x, y: y);
      
      // Prüfe, ob die Position geeignet ist
      final tile = map.getTile(position);
      
      // Prüfe, ob das Tile bebaubar ist und kein Wasser ist
      if (!tile.canBuildOn || tile.hasBuilding) {
        continue;
      }
      
      // Prüfe den Abstand zu Spielereinheiten
      bool tooCloseToPlayer = false;
      for (final unit in playerUnits) {
        if (position.manhattanDistance(unit.position) < minDistanceToPlayer) {
          tooCloseToPlayer = true;
          break;
        }
      }
      
      if (!tooCloseToPlayer) {
        return position;
      }
    }
    
    // Fallback, falls keine geeignete Position gefunden wurde
    return Position(x: 20, y: 20);
  }
}
