import 'building.dart';
import '../map/position.dart';
import '../resource/resource.dart';
import 'package:uuid/uuid.dart';

class Mine extends Building {
  final int stonePerTurn;
  final int ironPerTurn;

  Mine({
    required String id,
    required Position position,
    int level = 1,
    required this.stonePerTurn,
    required this.ironPerTurn,
    int? maxHealth,
    int? currentHealth,
    required String ownerID,
  }) : super(
          id: id,
          type: BuildingType.mine,
          position: position,
          level: level,
          maxHealth: maxHealth,
          currentHealth: currentHealth,
          ownerID: ownerID,
        );

  factory Mine.create(Position position, {Map<ResourceType, int>? productionValues, bool isIronMine = false, required String ownerID}) {
    final defaultStone = baseProductionValues[BuildingType.mine]?[ResourceType.stone] ?? 8;
    final defaultIron = baseProductionValues[BuildingType.mine]?[ResourceType.iron] ?? 3;
    final stone = productionValues != null && productionValues.containsKey(ResourceType.stone)
        ? productionValues[ResourceType.stone]!
        : (isIronMine ? 3 : defaultStone);
    final iron = productionValues != null && productionValues.containsKey(ResourceType.iron)
        ? productionValues[ResourceType.iron]!
        : (isIronMine ? defaultIron : 3);
    return Mine(
      id: const Uuid().v4(),
      position: position,
      stonePerTurn: stone,
      ironPerTurn: iron,
      ownerID: ownerID,
    );
  }

  @override
  Mine copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
    int? stonePerTurn,
    int? ironPerTurn,
  }) {
    return Mine(
      id: id ?? this.id,
      position: position ?? this.position,
      level: level ?? this.level,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      ownerID: ownerID ?? this.ownerID,
      stonePerTurn: stonePerTurn ?? this.stonePerTurn,
      ironPerTurn: ironPerTurn ?? this.ironPerTurn,
    );
  }

  @override
  Mine upgrade() {
    return copyWith(
      level: level + 1,
      stonePerTurn: (stonePerTurn * 1.4).round(),
      ironPerTurn: (ironPerTurn * 1.4).round(),
    );
  }

  @override
  Mine applyUpgradeValues() {
    return copyWith(
      stonePerTurn: (stonePerTurn * 1.4).round(),
      ironPerTurn: (ironPerTurn * 1.4).round(),
    );
  }

  @override
  Map<ResourceType, int> getProduction() {
    final bonus = 1.0 + (level - 1) * 0.2;
    return {
      ResourceType.stone: (stonePerTurn * bonus).round(),
      ResourceType.iron: (ironPerTurn * bonus).round(),
    };
  }

  @override
  List<Object?> get props => super.props..addAll([stonePerTurn, ironPerTurn]);
}