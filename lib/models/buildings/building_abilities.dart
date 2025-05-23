import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';

/// Interface für Gebäude, die Units trainieren können
abstract class UnitTrainer {
  /// Prüft ob eine bestimmte Unit trainiert werden kann
  bool canTrainUnit(UnitType unitType);
  
  /// Gibt die Trainingskosten für eine Unit zurück
  Map<ResourceType, int> getTrainingCost(UnitType unitType);
  
  /// Gibt die Liste der trainierbaren Units zurück
  List<UnitType> get trainableUnits;
}

/// Interface für Gebäude, die Ressourcen produzieren
abstract class ResourceProducer {
  /// Berechnet die Ressourcenproduktion pro Runde
  Map<ResourceType, int> calculateProduction();
  
  /// Gibt den Produktionsbonus basierend auf dem Level zurück
  double get productionBonus => 1.0 + (level - 1) * 0.2; // +20% pro Level
  
  /// Level des Gebäudes (muss von der Implementierung bereitgestellt werden)
  int get level;
}

/// Interface für Gebäude mit Verteidigungsfähigkeiten
abstract class DefensiveStructure {
  /// Berechnet den Verteidigungsbonus für Units in diesem Gebäude
  int get defenseBonus;
  
  /// Maximale Anzahl an Units die das Gebäude aufnehmen kann
  int get garrisonCapacity;
  
  /// Reichweite für Angriffe (0 wenn das Gebäude nicht angreifen kann)
  int get attackRange;
  
  /// Angriffsstärke (0 wenn das Gebäude nicht angreifen kann)
  int get attackValue;
}

/// Interface für Gebäude die Ressourcen lagern können
abstract class ResourceStorage {
  /// Maximale Lagerkapazität pro Ressourcentyp
  Map<ResourceType, int> get storageCapacity;
  
  /// Aktuelle Lagerbestände
  Map<ResourceType, int> get currentStorage;
  
  /// Prüft ob eine bestimmte Menge einer Ressource gelagert werden kann
  bool canStore(ResourceType type, int amount);
  
  /// Fügt Ressourcen zum Lager hinzu
  bool addResources(ResourceType type, int amount);
  
  /// Entfernt Ressourcen aus dem Lager
  bool removeResources(ResourceType type, int amount);
}