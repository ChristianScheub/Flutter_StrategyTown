import 'building.dart';
import 'building_abilities.dart';
import '../map/position.dart';
import '../resource/resource.dart';
import '../units/unit.dart';
import 'package:uuid/uuid.dart';

class CityCenter extends Building implements UnitTrainer {
  final Map<UnitType, int> unitCosts;

  CityCenter({
    required String id,
    required Position position,
    int level = 1,
    required this.unitCosts,
    int? maxHealth,
    int? currentHealth,
    required String ownerID,
  }) : super(
          id: id,
          type: BuildingType.cityCenter,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          ownerID: ownerID,
        );

  factory CityCenter.create(Position position, {required String ownerID}) {
    return CityCenter(
      id: const Uuid().v4(),
      position: position,
      unitCosts: const {
        UnitType.settler: 100,
        UnitType.farmer: 50,
        UnitType.lumberjack: 40,
        UnitType.miner: 60,
        UnitType.commander: 70,
        UnitType.architect: 55,
      },
      ownerID: ownerID,
    );
  }

  @override
  CityCenter copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
    Map<UnitType, int>? unitCosts,
  }) {
    return CityCenter(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      unitCosts: unitCosts ?? this.unitCosts,
    );
  }

  // UnitTrainer implementation
  @override
  bool canTrainUnit(UnitType unitType) {
    return trainableUnits.contains(unitType);
  }

  @override
  Map<ResourceType, int> getTrainingCost(UnitType unitType) {
    if (!canTrainUnit(unitType)) return {};

    // Konvertiere die Kosten in ein ResourceType-Map
    return {ResourceType.food: unitCosts[unitType] ?? 0};
  }

  // Hilfsmethode, die direkt den Nahrungspreis zurückgibt
  int getUnitCost(UnitType unitType) {
    // Get the training costs with level discount applied
    final costs = getTrainingCost(unitType);
    
    // Return the food cost if it exists, otherwise 0
    return costs[ResourceType.food] ?? 0;
  }

  @override
  List<UnitType> get trainableUnits => [
        UnitType.settler,
        UnitType.farmer,
        UnitType.lumberjack,
        UnitType.miner,
        UnitType.commander,
        UnitType.architect,
      ];

  @override
  List<Object?> get props => super.props..add(unitCosts);

  @override
  CityCenter applyUpgradeValues() {
    // Reduziert die Kosten für Einheiten um 10% pro Upgrade
    final Map<UnitType, int> newUnitCosts = {};
    for (var entry in unitCosts.entries) {
      newUnitCosts[entry.key] = (entry.value * 0.9).round();
    }
    return copyWith(
      unitCosts: newUnitCosts,
    );
  }
}