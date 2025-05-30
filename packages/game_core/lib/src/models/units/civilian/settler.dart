import 'package:uuid/uuid.dart';

import '../../map/position.dart';
import '../unit.dart';
import '../unit_abilities.dart';
import 'unit_base_classes.dart';
import '../capabilities/combat_capability.dart';
import '../capabilities/building_capability.dart';
import '../capabilities/harvesting_capability.dart';

/// Siedler - eine spezialisierte Zivileinheit, die neue Städte gründen kann
class Settler extends CivilianUnit implements SettlerCapable {
  final bool canFoundCityNow;

  const Settler({
    required String id,
    required Position position,
    int actionsLeft = 2,
    bool isSelected = false,
    int maxHealth = 50,
    int? currentHealth,
    this.canFoundCityNow = true,
    int creationTurn = 0,
    bool hasBuiltSomething = false,
    required String ownerID,
  }) : super(
          id: id,
          type: UnitType.settler,
          position: position,
          maxActions: 2,
          actionsLeft: actionsLeft,
          isSelected: isSelected,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          creationTurn: creationTurn,
          hasBuiltSomething: hasBuiltSomething,
          ownerID: ownerID,
        );

  factory Settler.create(Position position, {int creationTurn = 0, required String ownerID}) {
    return Settler(
      id: const Uuid().v4(),
      position: position,
      creationTurn: creationTurn,
      ownerID: ownerID,
    );
  }

  @override
  bool canFoundCity() {
    return canFoundCityNow && actionsLeft >= 2;
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
    String? ownerID,
    int? maxHealth,
    int? currentHealth,
    bool? canFoundCityNow,
    int? creationTurn,
    bool? hasBuiltSomething,
  }) {
    return Settler(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      canFoundCityNow: canFoundCityNow ?? this.canFoundCityNow,
      ownerID: ownerID ?? this.ownerID,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }

  @override
  Settler copyWithBase({
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
    return Settler(
      id: id ?? this.id,
      position: position ?? this.position,
      actionsLeft: actionsLeft ?? this.actionsLeft,
      isSelected: isSelected ?? this.isSelected,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      canFoundCityNow: canFoundCityNow,
      creationTurn: creationTurn ?? this.creationTurn,
      hasBuiltSomething: hasBuiltSomething ?? this.hasBuiltSomething,
    );
  }
}