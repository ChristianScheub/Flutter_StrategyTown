import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:uuid/uuid.dart';

/// Farmer - eine spezialisierte Zivileinheit, die Bauernhöfe bauen und 
/// Nahrung sammeln kann
class Farmer extends CivilianUnit implements BuilderUnit, HarvesterUnit {
  final BuildingCapability? buildingCapability;
  final HarvestingCapability? harvestingCapability;

  const Farmer({
    required String id,
    required Position position,
    int actionsLeft = 3,
    bool isSelected = false,
    int maxHealth = 50,
    int? currentHealth,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    this.buildingCapability,
    this.harvestingCapability,
  }) : super(
          id: id,
          type: UnitType.farmer,
          position: position,
          maxActions: 3,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          buildingCapability: buildingCapability,
          harvestingCapability: harvestingCapability,
        );

  factory Farmer.create(Position position, {int creationTurn = 0}) {
    return Farmer(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      buildingCapability: BuildingCapability(
        buildableTypes: [BuildingType.farm],
        actionCosts: {BuildingType.farm: 2},
      ),
      harvestingCapability: HarvestingCapability(
        harvestEfficiency: {ResourceType.food: 15},
        actionCosts: {ResourceType.food: 1},
      ),
    );
  }

  @override
  bool canBuild(BuildingType buildingType, Tile tile) {
    // Check if we have the capability first
    if (buildingCapability == null || !buildingCapability!.canBuild(buildingType, tile)) {
      return false;
    }
    
    // Prüfe, ob das Feld für den Bau geeignet ist
    if (!tile.canBuildFarm()) {
      return false;
    }
    
    // Prüfe, ob genug Aktionspunkte vorhanden sind
    return actionsLeft >= getBuildActionCost(buildingType);
  }

  @override
  int getBuildActionCost(BuildingType buildingType) {
    return buildingCapability?.getBuildActionCost(buildingType) ?? 999;
  }

  @override
  bool canHarvest(ResourceType resourceType, Tile tile) {
    return harvestingCapability?.canHarvest(resourceType, tile) ?? false;
  }

  @override
  int getHarvestAmount(ResourceType resourceType) {
    return harvestingCapability?.getHarvestAmount(resourceType) ?? 0;
  }

  @override
  int getHarvestActionCost(ResourceType resourceType) {
    return harvestingCapability?.getHarvestActionCost(resourceType) ?? 999;
  }

  @override
  Unit copyWith({
    String? id,
    Position? position,
    int? actionsLeft,
    bool? isSelected,
    BuildingCapability? buildingCapability,
    HarvestingCapability? harvestingCapability,
    CombatCapability? combatCapability, // für Signatur-Kompatibilität
    int? maxHealth,
    int? currentHealth,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Farmer(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      harvestingCapability: harvestingCapability ?? this.harvestingCapability,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  @override
  Farmer copyWithBase({
    String? id,
    Position? position,
    int? actionsLeft,
    bool? isSelected,
    int? maxHealth,
    int? currentHealth,
    BuildingCapability? buildingCapability,
    HarvestingCapability? harvestingCapability,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Farmer(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      harvestingCapability: harvestingCapability ?? this.harvestingCapability,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  /// Spezialisierte Methode für Farmer: Düngen eines Feldes für bessere Erträge
  Farmer fertilizeField() {
    // Verbraucht einen Aktionspunkt
    return copyWith(actionsLeft: actionsLeft - 1) as Farmer;
  }
}