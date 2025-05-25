import 'package:game_core/src/models/map/tile.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/units/capabilities/unit_capability.dart';

class HarvestingCapability extends UnitCapability {
  final Map<ResourceType, int> harvestEfficiency;
  final Map<ResourceType, int> actionCosts;

  const HarvestingCapability({
    required this.harvestEfficiency,
    required this.actionCosts,
  });

  bool canHarvest(ResourceType type, Tile? tile) {
    return harvestEfficiency.containsKey(type);
  }

  int getHarvestAmount(ResourceType type) {
    return harvestEfficiency[type] ?? 0;
  }

  int getHarvestActionCost(ResourceType type) {
    return actionCosts[type] ?? 1;
  }

  @override
  HarvestingCapability copyWith({
    Map<ResourceType, int>? harvestEfficiency,
    Map<ResourceType, int>? actionCosts,
  }) {
    return HarvestingCapability(
      harvestEfficiency: harvestEfficiency ?? Map.from(this.harvestEfficiency),
      actionCosts: actionCosts ?? Map.from(this.actionCosts),
    );
  }

  @override
  List<Object?> get props => [harvestEfficiency, actionCosts];
}
