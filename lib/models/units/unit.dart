import 'package:equatable/equatable.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/units/capabilities/combat_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/harvesting_capability.dart';
import 'package:flutter_sim_city/models/units/capabilities/building_capability.dart';

enum UnitType {
  settler,
  farmer,
  lumberjack, // Renamed from worker
  miner, // New unit type
  commander, // Previously soldier, now a commander
  knight,
  soldierTroop,
  archer,
  architect,
  virtualTower, // For tower combat calculations
}

/// Basisklasse für alle Einheiten im Spiel
abstract class Unit extends Equatable {
  final String id;
  final UnitType type;
  final Position position;
  final int maxActions;
  final int actionsLeft;
  final bool isSelected;
  
  // Unit capabilities
  final CombatCapability? combatCapability;
  final HarvestingCapability? harvestingCapability;
  final BuildingCapability? buildingCapability;
  
  // Owner information - used to identify which player or AI controls this unit
  final String ownerID;
  
  // Tracking when unit was created (for AI builder logic)
  final int creationTurn;
  final bool hasBuiltSomething;

  bool get isCombatUnit => combatCapability != null;
  int get attackValue => combatCapability?.attackValue ?? 0;
  int get defenseValue => combatCapability?.defenseValue ?? 0;
  int get maxHealth => combatCapability?.maxHealth ?? 50;
  int get currentHealth => combatCapability?.currentHealth ?? maxHealth;

  const Unit({
    required this.id,
    required this.type,
    required this.position,
    required this.maxActions,
    required this.actionsLeft,
    this.isSelected = false,
    this.combatCapability,
    this.harvestingCapability,
    this.buildingCapability,
    this.ownerID = 'player', // Default owner is the player
    this.creationTurn = 0,
    this.hasBuiltSomething = false,
  });


  /// Abstrakte copyWith-Methode, die von allen Unterklassen implementiert werden muss
  Unit copyWith({
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
  });
  
  /// Hilfsmethode zum Reduzieren von dupliziertem Code in Unterklassen
  Map<String, dynamic> copyWithBaseValues({
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
    return {
      'id': id ?? this.id,
      'position': position ?? this.position,
      'actionsLeft': actionsLeft ?? this.actionsLeft,
      'isSelected': isSelected ?? this.isSelected,
      'combatCapability': combatCapability ?? this.combatCapability,
      'harvestingCapability': harvestingCapability ?? this.harvestingCapability,
      'buildingCapability': buildingCapability ?? this.buildingCapability,
      'ownerID': ownerID ?? this.ownerID,
      'creationTurn': creationTurn ?? this.creationTurn,
      'hasBuiltSomething': hasBuiltSomething ?? this.hasBuiltSomething,
    };
  }

  Unit move(Position newPosition) {
    // Berechne die Distanz für die Bewegung (Manhattan-Distanz)
    final distance = position.manhattanDistance(newPosition);
    
    // Verbrauche Aktionspunkte entsprechend der zurückgelegten Entfernung
    return copyWith(
      position: newPosition,
      actionsLeft: actionsLeft - distance,
    );
  }

  Unit resetActions() {
    return copyWith(actionsLeft: maxActions);
  }

  Unit spendAction() {
    return copyWith(actionsLeft: actionsLeft - 1);
  }

  Unit select() {
    return copyWith(isSelected: true);
  }

  Unit deselect() {
    return copyWith(isSelected: false);
  }

  bool get canAct => actionsLeft > 0;

  String get name => type.toString().split('.').last;

  String get displayName => '${name[0].toUpperCase()}${name.substring(1)}';

  @override
  List<Object?> get props => [
        id,
        type,
        position,
        maxActions,
        actionsLeft,
        isSelected,
        attackValue,
        defenseValue,
        maxHealth,
        currentHealth,
        isCombatUnit,
        ownerID,
        creationTurn,
        hasBuiltSomething,
      ];

  String get emoji {
    switch (type) {
      case UnitType.settler:
        return '👨‍👩‍👧‍👦';
      case UnitType.farmer:
        return '👨‍🌾';
      case UnitType.lumberjack:
        return '🪓';
      case UnitType.miner:
        return '⛏️';
      case UnitType.commander:
        return '👨‍✈️';
      case UnitType.knight:
        return '🏇';
      case UnitType.soldierTroop:
        return '💂';
      case UnitType.archer:
        return '🏹';
      case UnitType.architect:
        return '🏗️';
      case UnitType.virtualTower:
        return '🗼'; // Tower emoji for virtual tower unit
    }
  }

  // Serialization method for all units
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'position': position.toJson(),
      'maxActions': maxActions,
      'actionsLeft': actionsLeft,
      'isSelected': isSelected,
      'attackValue': attackValue,
      'defenseValue': defenseValue,
      'maxHealth': maxHealth,
      'currentHealth': currentHealth,
      'isCombatUnit': isCombatUnit,
      'ownerID': ownerID,
    };
  }
  
  // Helper for deserialization in derived classes
  static Map<String, dynamic> baseJsonValues(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'position': Position.fromJson(json['position']),
      'maxActions': json['maxActions'],
      'actionsLeft': json['actionsLeft'],
      'isSelected': json['isSelected'],
      'attackValue': json['attackValue'],
      'defenseValue': json['defenseValue'],
      'maxHealth': json['maxHealth'],
      'currentHealth': json['currentHealth'],
      'isCombatUnit': json['isCombatUnit'],
      'ownerID': json['ownerID'] ?? 'player', // Default to player if not specified
    };
  }
}