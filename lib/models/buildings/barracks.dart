import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/building_abilities.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:uuid/uuid.dart';

class Barracks extends Building implements UnitTrainer, DefensiveStructure {
  // Lookup table for unit base costs
  final Map<UnitType, Map<ResourceType, int>> _unitTypeCosts = {
    UnitType.archer: {
      ResourceType.food: 120,
      ResourceType.iron: 20,
    },
    UnitType.soldierTroop: {
      ResourceType.food: 100,
      ResourceType.iron: 30,
    },
    UnitType.knight: {
      ResourceType.food: 150,
      ResourceType.iron: 50,
    },
  };
  
  Barracks({
    required String id,
    required Position position,
    int level = 1,
    int? maxHealth,
    int? currentHealth,
    required String ownerID,
  })
       : super(
         id: id,
         type: BuildingType.barracks,
         position: position,
         level: level,
         maxHealth: maxHealth,
         currentHealth: currentHealth,
         ownerID: ownerID,
       );

  factory Barracks.create(Position position, {required String ownerID}) {
    return Barracks(
      id: const Uuid().v4(),
      position: position,
      ownerID: ownerID,
    );
  }

  @override
  Barracks applyUpgradeValues() {
    // Beispiel: keine spezifischen Werte, aber hier könnte man z.B. Kapazität erhöhen
    return this;
  }

  @override
  Barracks copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
  }) {
    return Barracks(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
    );
  }

  Map<ResourceType, int> getUnitCosts(UnitType unitType) {
    if (!canTrainUnit(unitType)) return {};
    
    // Get the training costs with level discount applied
    return getTrainingCost(unitType);
  }
  
  // Für Abwärtskompatibilität
  int getUnitCost(UnitType unitType) {
    if (!canTrainUnit(unitType)) return 0;
    
    // Get the training costs with level discount applied
    final costs = getTrainingCost(unitType);
    
    // Return the food cost if it exists, otherwise 0
    return costs[ResourceType.food] ?? 0;
  }

  // UnitTrainer implementation
  @override
  bool canTrainUnit(UnitType unitType) {
    return trainableUnits.contains(unitType);
  }

  @override
  Map<ResourceType, int> getTrainingCost(UnitType unitType) {
    if (!canTrainUnit(unitType)) return {};
    
    // Hole die Basiskosten für den Einheitentyp
    final baseCosts = _unitTypeCosts[unitType] ?? {
      ResourceType.food: UnitFactory.getUnitFoodCost(unitType),
      ResourceType.iron: unitType == UnitType.knight ? 50 : (unitType == UnitType.soldierTroop ? 30 : 20),
    };
    
    // Apply level discount
    final discount = 1.0 - ((level - 1) * 0.1); // 10% discount per level
    return baseCosts.map((type, cost) =>
      MapEntry(type, (cost * discount).round())
    );
  }

  @override
  List<UnitType> get trainableUnits => [
    UnitType.archer,
    UnitType.soldierTroop,
    if (level >= 3) UnitType.knight, // Unlock knight at level 3
  ];

  // DefensiveStructure implementation
  @override
  int get defenseBonus => 2 * level; // +2 defense per level

  @override
  int get garrisonCapacity => 3 + level; // 3 base + 1 per level

  @override
  int get attackRange => 0; // Barracks can't attack

  @override
  int get attackValue => 0; // Barracks can't attack

  @override
  List<Object?> get props => [...super.props];
}
