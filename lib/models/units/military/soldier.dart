import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:uuid/uuid.dart';

/// Der Commander ist eine Hybrid-Einheit mit Kampffähigkeiten und Baufertigkeiten
class Commander extends MilitaryUnit implements BuilderUnit {
  static const int meleeAttackRange = 1;
  final BuildingCapability? buildingCapability;

  const Commander({
    required String id,
    required Position position,
    int actionsLeft = 3,
    bool isSelected = false,
    required CombatCapability combatCapability,
    this.buildingCapability,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
  }) : super(
          id: id,
          type: UnitType.commander,
          position: position,
          maxActions: 3,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          combatCapability: combatCapability,
          buildingCapability: buildingCapability,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
        );

  factory Commander.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Commander(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
      combatCapability: const CombatCapability(
        attackValue: 5,
        defenseValue: 5,
        maxHealth: 50,
      ),
      buildingCapability: const BuildingCapability(
        buildableTypes: [BuildingType.barracks],
        actionCosts: {BuildingType.barracks: 2},
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
    HarvestingCapability? harvestingCapability,
    CombatCapability? combatCapability,
    String? ownerID,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Commander(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      combatCapability: (combatCapability ?? this.combatCapability) as CombatCapability,
      buildingCapability: buildingCapability ?? this.buildingCapability,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }
}