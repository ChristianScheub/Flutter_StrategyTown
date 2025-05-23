import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/units/capabilities/unit_capability.dart';

class BuildingCapability extends UnitCapability {
  final List<BuildingType> buildableTypes;
  final Map<BuildingType, int> actionCosts;

  const BuildingCapability({
    required this.buildableTypes,
    required this.actionCosts,
  });

  bool canBuild(BuildingType type, Tile? tile) {
    return buildableTypes.contains(type);
  }

  int getBuildActionCost(BuildingType type) {
    return actionCosts[type] ?? 2;
  }

  @override
  BuildingCapability copyWith({
    List<BuildingType>? buildableTypes,
    Map<BuildingType, int>? actionCosts,
  }) {
    return BuildingCapability(
      buildableTypes: buildableTypes ?? List.from(this.buildableTypes),
      actionCosts: actionCosts ?? Map.from(this.actionCosts),
    );
  }

  @override
  List<Object?> get props => [buildableTypes, actionCosts];
}
