import 'building.dart';
import '../map/position.dart';
import '../resource/resource.dart';
import 'package:uuid/uuid.dart';

class LumberCamp extends Building {
  final int woodPerTurn;

  LumberCamp({
    required String id,
    required Position position,
    int level = 1,
    required this.woodPerTurn,
    int? maxHealth,
    int? currentHealth,
    required String ownerID,
  }) : super(
          id: id,
          type: BuildingType.lumberCamp,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          ownerID: ownerID,
        );

  factory LumberCamp.create(Position position, {Map<ResourceType, int>? productionValues, required String ownerID}) {
    final wood = productionValues != null && productionValues.containsKey(ResourceType.wood)
        ? productionValues[ResourceType.wood]!
        : (baseProductionValues[BuildingType.lumberCamp]?[ResourceType.wood] ?? 12);
    return LumberCamp(
      id: const Uuid().v4(),
      position: position,
      woodPerTurn: wood,
      ownerID: ownerID,
    );
  }

  @override
  LumberCamp copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
    int? woodPerTurn,
  }) {
    return LumberCamp(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      woodPerTurn: woodPerTurn ?? this.woodPerTurn,
    );
  }

  @override
  LumberCamp applyUpgradeValues() {
    return copyWith(
      woodPerTurn: (woodPerTurn * 1.4).round(),
    );
  }

  @override
  Map<ResourceType, int> getProduction() {
    final bonus = 1.0 + (level - 1) * 0.2;
    return {ResourceType.wood: (woodPerTurn * bonus).round()};
  }

  @override
  List<Object?> get props => super.props..add(woodPerTurn);
}