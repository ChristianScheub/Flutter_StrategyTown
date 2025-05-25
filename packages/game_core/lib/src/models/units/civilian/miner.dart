import 'package:uuid/uuid.dart';

import '../../buildings/building.dart';
import '../../map/position.dart';
import '../../resource/resource.dart';
import '../../map/tile.dart';
import '../unit.dart';
import '../unit_abilities.dart';
import 'unit_base_classes.dart';
import '../capabilities/building_capability.dart';
import '../capabilities/harvesting_capability.dart';
import '../capabilities/combat_capability.dart';

/// Bergarbeiter - eine spezialisierte Zivileinheit, die Minen bauen und
/// Stein und Eisen sammeln kann
class Miner extends CivilianUnit implements BuilderUnit, HarvesterUnit {
  final BuildingCapability? buildingCapability;
  final HarvestingCapability? harvestingCapability;

  const Miner({
    required String id,
    required Position position,
    int actionsLeft = 2,
    bool isSelected = false,
    int maxHealth = 50,
    int? currentHealth,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
    this.buildingCapability,
    this.harvestingCapability,
  }) : super(
          id: id,
          type: UnitType.miner,
          position: position,
          maxActions: 2,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
          buildingCapability: buildingCapability,
          harvestingCapability: harvestingCapability,
        );

  factory Miner.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Miner(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
      // ownerID wird nur übergeben wenn explizit gesetzt, sonst Standardwert vom Konstruktor
      buildingCapability: BuildingCapability(
        buildableTypes: [BuildingType.mine],
        actionCosts: {BuildingType.mine: 2},
      ),
      harvestingCapability: HarvestingCapability(
        harvestEfficiency: {
          ResourceType.stone: 10,
          ResourceType.iron: 5,
        },
        actionCosts: {
          ResourceType.stone: 1,
          ResourceType.iron: 1,
        },
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
    if (!tile.canBuildMine()) {
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
    if (harvestingCapability == null || !harvestingCapability!.canHarvest(resourceType, tile)) {
      return false;
    }

    // Additional check for tile resource type
    return tile.resourceType == resourceType;
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
    CombatCapability? combatCapability,
    String? ownerID,
    int? maxHealth,
    int? currentHealth,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Miner(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      harvestingCapability: harvestingCapability ?? this.harvestingCapability,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  @override
  Miner copyWithBase({
    String? id,
    Position? position,
    int? actionsLeft,
    bool? isSelected,
    int? maxHealth,
    int? currentHealth,
    BuildingCapability? buildingCapability,
    HarvestingCapability? harvestingCapability,
    String? ownerID,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Miner(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      harvestingCapability: harvestingCapability ?? this.harvestingCapability,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  /// Spezialisierte Methode für Bergarbeiter: Analysiert das Gestein für bessere Ernte
  Miner analyzeRock() {
    // Verbraucht einen Aktionspunkt, verbessert aber die nächste Ernte
    return copyWith(actionsLeft: actionsLeft - 1) as Miner;
  }
}
