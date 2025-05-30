import '../map/position.dart';
import 'unit.dart';
import 'military/archer.dart';
import 'civilian/farmer.dart';
import 'military/knight.dart';
import 'civilian/lumberjack.dart';
import 'civilian/miner.dart';
import 'civilian/settler.dart';
import 'military/soldier.dart';
import 'military/soldier_troop.dart';
import 'civilian/architect.dart';
import 'military/virtual_tower.dart';
import 'capabilities/combat_capability.dart';

/// Factory-Klasse für die Erstellung von Einheiten
/// 
/// Verwendet das Factory-Pattern, um die Erstellung von verschiedenen
/// Einheitentypen zu zentralisieren und zu vereinfachen.
class UnitFactory {
  /// Erstellt eine neue Einheit des angegebenen Typs an der angegebenen Position
  static Unit createUnit(UnitType type, Position position, {int currentTurn = 0, required String ownerID}) {
    switch (type) {
      case UnitType.settler:
        return Settler.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.farmer:
        return Farmer.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.lumberjack:
        return Lumberjack.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.miner:
        return Miner.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.commander:
        return Commander.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.knight:
        return Knight.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.soldierTroop:
        return SoldierTroop.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.archer:
        return Archer.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.architect:
        return Architect.create(position, creationTurn: currentTurn, ownerID: ownerID);
      case UnitType.virtualTower:
        // Virtual tower units should be created through DefensiveTower._createVirtualAttackUnit()
        throw UnsupportedError('Virtual tower units cannot be created directly through UnitFactory');
    }
  }
  
  /// Gibt die Kosten für eine Einheit in Nahrungspunkten zurück
  static int getUnitFoodCost(UnitType type) {
    switch (type) {
      case UnitType.settler:
        return 100;
      case UnitType.farmer:
        return 50;
      case UnitType.lumberjack:
        return 40;
      case UnitType.miner:
        return 60;
      case UnitType.commander:
        return 70;
      case UnitType.knight:
        return 150;
      case UnitType.soldierTroop:
        return 100;
      case UnitType.archer:
        return 120;
      case UnitType.architect:
        return 80;
      case UnitType.virtualTower:
        return 0; // Virtual towers have no food cost as they can't be trained
    }
  }
  
  /// Prüft, ob eine Einheit eine Kampfeinheit ist
  static bool isCombatUnit(UnitType type) {
    return [
      UnitType.commander,
      UnitType.knight,
      UnitType.soldierTroop,
      UnitType.archer
    ].contains(type);
  }
  
  /// Prüft, ob eine Einheit eine Zivileinheit ist
  static bool isCivilianUnit(UnitType type) {
    return [
      UnitType.settler,
      UnitType.farmer,
      UnitType.lumberjack,
      UnitType.miner
    ].contains(type);
  }
  
  /// Deserializes a unit from JSON
  static Unit fromJson(Map<String, dynamic> json) {
    final typeString = json['type'];
    final position = Position.fromJson(json['position']);
    
    // Find the proper unit type
    UnitType? unitType;
    for (final type in UnitType.values) {
      if (type.toString().split('.').last == typeString) {
        unitType = type;
        break;
      }
    }
    
    if (unitType == null) {
      throw Exception('Unknown unit type: $typeString');
    }
    
    // Handle virtual tower units specially
    if (unitType == UnitType.virtualTower) {
      final ownerID = json['ownerID'] as String? ?? 'human_player_1';
      // Import the VirtualUnit class from the proper location
      return VirtualUnit(
        id: json['id'],
        position: position,
        maxActions: json['maxActions'],
        actionsLeft: json['actionsLeft'],
        isSelected: json['isSelected'],
        combatCapability: CombatCapability(
          attackValue: json['attackValue'],
          defenseValue: json['defenseValue'],
          maxHealth: json['maxHealth'],
          currentHealth: json['currentHealth'],
        ),
        creationTurn: json['creationTurn'] ?? 0,
        hasBuiltSomething: json['hasBuiltSomething'] ?? false,
        ownerID: ownerID,
      );
    }
    
    // Create a new unit of the right type and then update its properties
    final ownerID = json['ownerID'] as String? ?? 'human_player_1'; // Fallback to first human player if missing
    final unit = createUnit(unitType, position, ownerID: ownerID);
    
    // Identify the correct unit type and update properties
    switch (unitType) {
      case UnitType.settler:
        return (unit as Settler).copyWith(
          id: json['id'],
          position: position,
          actionsLeft: json['actionsLeft'],
          isSelected: json['isSelected'],
        );
      case UnitType.farmer:
        return (unit as Farmer).copyWith(
          id: json['id'],
          position: position,
          actionsLeft: json['actionsLeft'],
          isSelected: json['isSelected'],
        );
      default:
        // For other types, use the base copyWith
        return unit.copyWith(
          id: json['id'],
          position: position,
          actionsLeft: json['actionsLeft'],
          isSelected: json['isSelected'],
        );
    }
  }
}
