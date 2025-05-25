import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:uuid/uuid.dart';

/// Soldatentrupp - eine defensive Kampfeinheit mit hohem Verteidigungswert
class SoldierTroop extends MilitaryUnit {
  const SoldierTroop({
    required String id,
    required Position position,
    int actionsLeft = 2,
    bool isSelected = false,
    required CombatCapability combatCapability,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
  }) : super(
          id: id,
          type: UnitType.soldierTroop,
          position: position,
          maxActions: 2, // 4 fields movement range per turn
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          combatCapability: combatCapability,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
        );

  factory SoldierTroop.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return SoldierTroop(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
      combatCapability: const CombatCapability(
        attackValue: 10,
        defenseValue: 5,
        maxHealth: 80,
      ),
    );
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
    return SoldierTroop(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      combatCapability: (combatCapability ?? this.combatCapability) as CombatCapability,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }
}
