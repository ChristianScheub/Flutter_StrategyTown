import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:uuid/uuid.dart';

/// Holzfäller - eine spezialisierte Zivileinheit, die Holzfällerlager bauen und
/// Holz sammeln kann
class Lumberjack extends CivilianUnit implements BuilderUnit, HarvesterUnit {
  final BuildingCapability? buildingCapability;
  final HarvestingCapability? harvestingCapability;

  const Lumberjack({
    required String id,
    required Position position,
    int actionsLeft = 4,
    bool isSelected = false,
    int maxHealth = 50,
    int? currentHealth,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    String ownerID = 'player',
    this.harvestingCapability,
    this.buildingCapability,
  }) : super(
          id: id,
          type: UnitType.lumberjack,
          position: position,
          maxActions: 4,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          buildingCapability: buildingCapability,
          harvestingCapability: harvestingCapability,
          ownerID: ownerID,
        );

  factory Lumberjack.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Lumberjack(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      buildingCapability: BuildingCapability(
        buildableTypes: [BuildingType.lumberCamp],
        actionCosts: {BuildingType.lumberCamp: 2},
      ),
      harvestingCapability: HarvestingCapability(
        harvestEfficiency: {ResourceType.wood: 5},
        actionCosts: {ResourceType.wood: 1},
      ),
    );
  }

  bool canBuild(BuildingType buildingType, Tile tile) {
    if (buildingCapability == null || !buildingCapability!.canBuild(buildingType, tile)) {
      return false;
    }
    if (!tile.canBuildLumberCamp()) {
      return false;
    }
    return actionsLeft >= getBuildActionCost(buildingType);
  }

  int getBuildActionCost(BuildingType buildingType) {
    return buildingCapability?.getBuildActionCost(buildingType) ?? 999;
  }

  bool canHarvest(ResourceType resourceType, Tile tile) {
    if (harvestingCapability == null || !harvestingCapability!.canHarvest(resourceType, tile)) {
      return false;
    }
    // Only allow harvesting wood on forest tiles
    return tile.type == TileType.forest && resourceType == ResourceType.wood;
  }

  int getHarvestAmount(ResourceType resourceType) {
    return harvestingCapability?.getHarvestAmount(resourceType) ?? 0;
  }

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
    return Lumberjack(
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
  Lumberjack copyWithBase({
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
    return Lumberjack(
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

  /// Spezialisierte Methode für Holzfäller: Schärft die Axt für bessere Holzernte
  Lumberjack sharpenAxe() {
    if (harvestingCapability == null || !canAct) return this;
    final currentHarvestAmount = harvestingCapability!.getHarvestAmount(ResourceType.wood);
    final newHarvestAmount = (currentHarvestAmount * 1.5).round();
    return copyWith(
      actionsLeft: actionsLeft - 1,
      harvestingCapability: harvestingCapability!.copyWith(
        harvestEfficiency: {ResourceType.wood: newHarvestAmount},
      ),
    ) as Lumberjack;
  }
}
