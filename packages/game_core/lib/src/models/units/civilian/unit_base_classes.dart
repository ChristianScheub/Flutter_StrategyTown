import '../../map/position.dart';
import '../unit.dart';
import '../capabilities/combat_capability.dart';
import '../capabilities/building_capability.dart';
import '../capabilities/harvesting_capability.dart';

/// Basisklasse für alle zivilen Einheiten im Spiel
abstract class CivilianUnit extends Unit {
  final int maxHealth;
  final int currentHealth;

  const CivilianUnit({
    required String id,
    required UnitType type,
    required Position position,
    required int maxActions,
    required int actionsLeft,
    this.maxHealth = 50,
    int? currentHealth,
    bool isSelected = false,
    BuildingCapability? buildingCapability,
    HarvestingCapability? harvestingCapability,
    required String ownerID,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
  }) : currentHealth = currentHealth ?? maxHealth,
        super(
          id: id,
          type: type,
          position: position,
          maxActions: maxActions,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          buildingCapability: buildingCapability,
          harvestingCapability: harvestingCapability,
          ownerID: ownerID,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
        );

  CivilianUnit copyWithBase({
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
  });

  @override
  Map<String, dynamic> copyWithBaseValues({
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
    return {
      'id': id ?? this.id,
      'position': position ?? this.position,
      'actionsLeft': actionsLeft ?? this.actionsLeft,
      'isSelected': isSelected ?? this.isSelected,
      'buildingCapability': buildingCapability ?? this.buildingCapability,
      'harvestingCapability': harvestingCapability ?? this.harvestingCapability,
      'combatCapability': combatCapability ?? this.combatCapability,
      'ownerID': ownerID ?? this.ownerID,
      'creationTurn': creationTurn ?? this.creationTurn,
      'hasBuiltSomething': hasBuiltSomething ?? this.hasBuiltSomething,
    };
  }
}

/// Basisklasse für alle militärischen Einheiten im Spiel
abstract class MilitaryUnit extends Unit {
  const MilitaryUnit({
    required String id,
    required UnitType type,
    required Position position,
    required int maxActions,
    required int actionsLeft,
    bool isSelected = false,
    required CombatCapability combatCapability,
    BuildingCapability? buildingCapability,
    HarvestingCapability? harvestingCapability,
    required String ownerID,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
  }) : super(
          id: id,
          type: type,
          position: position,
          maxActions: maxActions,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          buildingCapability: buildingCapability,
          harvestingCapability: harvestingCapability,
          combatCapability: combatCapability,
          ownerID: ownerID,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
        );
  
  @override
  Map<String, dynamic> copyWithBaseValues({
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
    return {
      'id': id ?? this.id,
      'position': position ?? this.position,
      'actionsLeft': actionsLeft ?? this.actionsLeft,
      'isSelected': isSelected ?? this.isSelected,
      'buildingCapability': buildingCapability ?? this.buildingCapability,
      'harvestingCapability': harvestingCapability ?? this.harvestingCapability,
      'combatCapability': combatCapability ?? this.combatCapability,
      'ownerID': ownerID ?? this.ownerID,
      'creationTurn': creationTurn ?? this.creationTurn,
      'hasBuiltSomething': hasBuiltSomething ?? this.hasBuiltSomething,
    };
  }
}
