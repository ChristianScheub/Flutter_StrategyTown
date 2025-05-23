import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:uuid/uuid.dart';

class Farm extends Building {
  final int foodPerTurn;

  Farm({
    required String id,
    required Position position,
    int level = 1,
    required this.foodPerTurn,
    int? maxHealth,
    int? currentHealth,
  }) : super(
          id: id,
          type: BuildingType.farm,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
        );

  factory Farm.create(Position position, {Map<ResourceType, int>? productionValues}) {
    final food = productionValues != null && productionValues.containsKey(ResourceType.food)
        ? productionValues[ResourceType.food]!
        : (baseProductionValues[BuildingType.farm]?[ResourceType.food] ?? 10);
    return Farm(
      id: const Uuid().v4(),
      position: position,
      foodPerTurn: food,
    );
  }

  @override
  Farm copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    int? foodPerTurn,
  }) {
    return Farm(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      foodPerTurn: foodPerTurn ?? this.foodPerTurn,
    );
  }

  @override
  Farm applyUpgradeValues() {
    // Upgrade foodPerTurn zentralisiert
    return copyWith(
      foodPerTurn: (foodPerTurn * 1.4).round(),
    );
  }

  // ResourceProducer implementation
  @override
  Map<ResourceType, int> getProduction() {
    final bonus = 1.0 + (level - 1) * 0.2; // +20% pro Level
    return {ResourceType.food: (foodPerTurn * bonus).round()};
  }

  @override
  List<Object?> get props => [...super.props, foodPerTurn];
}