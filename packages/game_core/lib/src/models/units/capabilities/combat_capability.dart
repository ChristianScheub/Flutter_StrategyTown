
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/units/capabilities/unit_capability.dart';
import 'package:game_core/src/models/units/unit.dart';

class CombatCapability extends UnitCapability {
  final int attackValue;
  final int defenseValue;
  final int maxHealth;
  final int currentHealth;
  final int attackRange;

  const CombatCapability({
    required this.attackValue,
    required this.defenseValue,
    required this.maxHealth,
    int? currentHealth,  // made optional
    this.attackRange = 1,
  }) : this.currentHealth = currentHealth ?? maxHealth;  // defaults to maxHealth if not provided

  bool canAttackAt(Position unitPosition, Position targetPosition) {
    final distance = unitPosition.manhattanDistance(targetPosition);
    return distance <= attackRange;
  }

  int calculateDamage(Unit target) {
    // Base damage is the attack value
    int baseDamage = attackValue;
    
    // Check target's defense if it has combat capability
    if (target.combatCapability != null) {
      final targetDefense = target.defenseValue;
      // Defense reduces damage by percentage (each point of defense reduces damage by 5%)
      final damageReduction = targetDefense * 0.05;
      baseDamage = (baseDamage * (1 - damageReduction)).round();
    }
    
    // Ensure minimum damage of 1
    return baseDamage.clamp(1, 999);
  }

  @override
  CombatCapability copyWith({
    int? attackValue,
    int? defenseValue,
    int? maxHealth,
    int? currentHealth,
    int? attackRange,
  }) {
    return CombatCapability(
      attackValue: attackValue ?? this.attackValue,
      defenseValue: defenseValue ?? this.defenseValue,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      attackRange: attackRange ?? this.attackRange,
    );
  }

  @override
  List<Object?> get props => [
        attackValue,
        defenseValue,
        maxHealth,
        currentHealth,
        attackRange,
      ];
}
