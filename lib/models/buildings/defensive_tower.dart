import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/building_abilities.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';
import 'package:flutter_sim_city/models/combat/combat_system.dart';
import 'package:flutter_sim_city/models/units/military/virtual_tower.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:uuid/uuid.dart';

class DefensiveTower extends Building implements DefensiveStructure {
  final int baseAttackValue;
  final String ownerID;
  
  DefensiveTower({
    required String id,
    required Position position,
    int level = 1,
    required this.baseAttackValue,
    int? maxHealth,
    int? currentHealth,
    required this.ownerID,
  }) : super(
          id: id,
          type: BuildingType.defensiveTower,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
        );

  factory DefensiveTower.create(Position position, {int? baseAttackValue, required String ownerID}) {
    return DefensiveTower(
      id: const Uuid().v4(),
      position: position,
      baseAttackValue: baseAttackValue ?? 10,
      ownerID: '',
    );
  }

  @override
  DefensiveTower copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
    int? baseAttackValue,
  }) {
    return DefensiveTower(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      baseAttackValue: baseAttackValue ?? this.baseAttackValue,
    );
  }

  @override
  DefensiveTower upgrade() {
    return copyWith(
      level: level + 1,
      maxHealth: (maxHealth * 1.2).round(),
      baseAttackValue: (baseAttackValue * 1.3).round(), // 30% mehr Schaden pro Level
    );
  }

  @override
  DefensiveTower applyUpgradeValues() {
    // Beispiel: erhöhe den Angriffswert pro Level
    return copyWith(
      baseAttackValue: (baseAttackValue * 1.3).round(),
    );
  }

  // DefensiveStructure implementation
  @override
  int get defenseBonus => 3 * level; // +3 Verteidigung pro Level

  @override
  int get garrisonCapacity => 2; // Fester Wert für Türme

  @override
  int get attackRange => 3; // Fester Wert für Türme

  @override
  int get attackValue => (baseAttackValue * (1 + (level - 1) * 0.3)).round(); // +30% pro Level

  /// Creates a virtual unit for tower attacks
  VirtualUnit _createVirtualAttackUnit() {
    return VirtualUnit(
      id: '${id}_virtual',
      position: position,
      maxActions: 1,
      actionsLeft: 1,
      isSelected: false,
      combatCapability: CombatCapability(
        attackValue: attackValue,
        defenseValue: 0,
        maxHealth: 999,
        attackRange: attackRange,
      ),
      creationTurn: 0,
      hasBuiltSomething: false,
    );
  }

  /// Performs automatic tower attacks on enemy units in range
  GameState performAutoAttack(GameState state, bool isEnemy) {
    // Create virtual unit for attack
    final virtualUnit = _createVirtualAttackUnit();
    
    // Get potential targets (either player or enemy units)
    final targets = isEnemy ? state.units : (state.enemyFaction?.units ?? []);
    
    // Filter targets in range
    final targetsInRange = targets.where((target) => 
      target.position.manhattanDistance(position) <= attackRange
    ).toList();
    
    if (targetsInRange.isEmpty) return state;
    
    // Attack the first target in range
    // Der Parameter isEnemy bestimmt, ob der Turm dem Spieler oder der KI gehört
    return CombatSystem.performAttack(state, virtualUnit, targetsInRange.first);
  }

  @override
  List<Object?> get props => [...super.props, baseAttackValue, ownerID];
}
