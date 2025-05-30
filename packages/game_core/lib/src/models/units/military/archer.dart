import 'package:uuid/uuid.dart';

import '../../map/position.dart';
import '../unit.dart';
import '../civilian/unit_base_classes.dart';
import '../capabilities/combat_capability.dart';
import '../capabilities/harvesting_capability.dart';
import '../capabilities/building_capability.dart';

/// Bogenschütze - eine spezialisierte Kampfeinheit mit Fernkampffähigkeiten
class Archer extends MilitaryUnit {
  /// Maximale Angriffsreichweite für Bogenschützen
  static const int attackRange = 3;

  @override
  bool canAttackAt(Position targetPosition) {
    // Prüft, ob das Ziel in der Reichweite liegt und ob die Einheit noch agieren kann
    final distance = position.manhattanDistance(targetPosition);
    return distance <= attackRange && canAct;
  }

  const Archer({
    required String id,
    required Position position,
    int actionsLeft = 4,
    bool isSelected = false,
    required CombatCapability combatCapability,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
  }) : super(
          id: id,
          type: UnitType.archer,
          position: position,
          maxActions: 4, // 4 fields movement range per turn
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          combatCapability: combatCapability,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
        );

  factory Archer.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Archer(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
      combatCapability: const CombatCapability(
        attackValue: 12,
        defenseValue: 4,
        maxHealth: 80,
      ),
    );
  }

  @override
  Archer copyWith({
    String? id,
    Position? position,
    int? actionsLeft,
    bool? isSelected,
    CombatCapability? combatCapability,
    HarvestingCapability? harvestingCapability,
    BuildingCapability? buildingCapability,
    String? ownerID,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    final values = copyWithBaseValues(
      id: id,
      position: position,
      actionsLeft: actionsLeft,
      isSelected: isSelected,
      combatCapability: combatCapability,
      harvestingCapability: harvestingCapability,
      buildingCapability: buildingCapability,
      ownerID: ownerID,
      creationTurn: creationTurn,
      hasBuiltSomething: hasBuiltSomething,
    );
    return Archer(
      id: values['id'] as String,
      position: values['position'] as Position,
      actionsLeft: values['actionsLeft'] as int,
      isSelected: values['isSelected'] as bool,
      combatCapability: values['combatCapability'] as CombatCapability,
      ownerID: values['ownerID'] as String,
      creationTurn: values['creationTurn'] as int,
      hasBuiltSomething: values['hasBuiltSomething'] as bool,
    );
  }
  
  /// Spezialisierte Methode für den Bogenschützen: Fernkampfangriff
  Archer prepareRangedAttack() {
    // Verbraucht einen Aktionspunkt für die Vorbereitung eines Fernkampfangriffs
    return copyWith(actionsLeft: actionsLeft - 1);
  }
}
