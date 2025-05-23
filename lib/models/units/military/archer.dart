import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';
import 'package:uuid/uuid.dart';

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
        );

  factory Archer.create(Position position, {int creationTurn = 0}) {
    return Archer(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
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
      creationTurn: creationTurn,
      hasBuiltSomething: hasBuiltSomething,
    );
    return Archer(
      id: values['id'] as String,
      position: values['position'] as Position,
      actionsLeft: values['actionsLeft'] as int,
      isSelected: values['isSelected'] as bool,
      combatCapability: values['combatCapability'] as CombatCapability,
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
