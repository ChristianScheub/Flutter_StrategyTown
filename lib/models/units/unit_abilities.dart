import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/unit.dart';

/// Interface für Einheiten, die bauen können
abstract class BuilderUnit {
  /// Prüft, ob die Einheit ein bestimmtes Gebäude auf einem bestimmten Feld bauen kann
  bool canBuild(BuildingType buildingType, Tile tile);
  
  /// Gibt die Aktionspunkte zurück, die für den Bau benötigt werden
  int getBuildActionCost(BuildingType buildingType);
}

/// Interface für Einheiten mit Kampffähigkeiten
abstract class CombatCapable {
  /// Attackwert der Einheit
  int get attackValue;
  
  /// Verteidigungswert der Einheit
  int get defenseValue;
  
  /// Maximale Gesundheit
  int get maxHealth;
  
  /// Aktuelle Gesundheit
  int get currentHealth;
  
  /// Prüft, ob eine Position angreifbar ist (innerhalb der Reichweite)
  bool canAttackAt(Position targetPosition);
  
  /// Berechnet den Schaden bei einem Angriff auf ein Ziel
  int calculateDamage(Unit target);
}

/// Interface für Einheiten, die Ressourcen sammeln können
abstract class HarvesterUnit {
  /// Prüft, ob die Einheit Ressourcen eines bestimmten Typs sammeln kann
  bool canHarvest(ResourceType resourceType, Tile tile);
  
  /// Gibt die Menge an Ressourcen zurück, die gesammelt werden kann
  int getHarvestAmount(ResourceType resourceType);
  
  /// Gibt die Aktionspunkte zurück, die für das Sammeln benötigt werden
  int getHarvestActionCost(ResourceType resourceType);
}

/// Interface für Einheiten, die Städte gründen können
abstract class SettlerCapable {
  /// Prüft, ob die Einheit eine Stadt gründen kann
  bool canFoundCity();
}
