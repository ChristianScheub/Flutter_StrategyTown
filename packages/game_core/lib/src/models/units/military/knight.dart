import 'package:uuid/uuid.dart';

import '../../map/position.dart';
import '../unit.dart';
import '../civilian/unit_base_classes.dart';
import '../capabilities/combat_capability.dart';
import '../capabilities/building_capability.dart';
import '../capabilities/harvesting_capability.dart';

class Knight extends MilitaryUnit {
  const Knight({
    required String id,
    required Position position,
    int actionsLeft = 3,
    bool isSelected = false,
    required CombatCapability combatCapability,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
  }) : super(
          id: id,
          type: UnitType.knight,
          position: position,
          maxActions: 3,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          combatCapability: combatCapability,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
        );

  factory Knight.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Knight(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
      combatCapability: const CombatCapability(
        attackValue: 15,
        defenseValue: 10,
        maxHealth: 100,
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
    return Knight(
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
