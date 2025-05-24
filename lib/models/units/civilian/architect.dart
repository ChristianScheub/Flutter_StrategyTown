import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:uuid/uuid.dart';

class Architect extends CivilianUnit implements BuilderUnit {
  static const int buildRange = 2;
  final BuildingCapability? buildingCapability;

  const Architect({
    required String id,
    required Position position,
    int actionsLeft = 2,
    bool isSelected = false,
    int maxHealth = 50,
    int? currentHealth,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    this.buildingCapability,
    String ownerID = 'player',
  }) : super(
          id: id,
          type: UnitType.architect,
          position: position,
          maxActions: 2,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          buildingCapability: buildingCapability,
        );

  factory Architect.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Architect(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      buildingCapability: BuildingCapability(
        buildableTypes: [BuildingType.defensiveTower, BuildingType.wall],
        actionCosts: {
          BuildingType.defensiveTower: 2,
          BuildingType.wall: 1,
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
    if (tile.type == TileType.water ||
        tile.type == TileType.mountain || 
        tile.hasBuilding) {
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
  Unit copyWith({
    String? id,
    Position? position,
    int? actionsLeft,
    bool? isSelected,
    BuildingCapability? buildingCapability,
    CombatCapability? combatCapability,
    HarvestingCapability? harvestingCapability,
    String? ownerID,
    int? maxHealth,
    int? currentHealth,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Architect(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  @override
  Architect copyWithBase({
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
    return Architect(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }
}
