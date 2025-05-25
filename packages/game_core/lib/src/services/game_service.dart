import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';
import 'package:game_core/src/services/game/specialized_building_service.dart';
import 'package:game_core/src/services/game/resource_service.dart';

// Re-export providers for backward compatibility
export 'package:game_core/src/services/game/game_state_notifier.dart';

/// Extended GameStateNotifier with specialized building and resource services
class GameService extends GameStateNotifier {
  GameService(Ref ref) : super(ref) {
    _initializeExtendedServices();
  }

  // Extended service instances
  late final SpecializedBuildingService _specializedBuildingService;
  late final ResourceService _resourceService;

  void _initializeExtendedServices() {
    _specializedBuildingService = SpecializedBuildingService(this);
    _resourceService = ResourceService(this);
  }

  // Specialized building methods
  void foundCity() => _specializedBuildingService.foundCity();
  void buildFarm() => _specializedBuildingService.buildFarm();
  void buildLumberCamp() => _specializedBuildingService.buildLumberCamp();
  void buildMine() => _specializedBuildingService.buildMine();
  void buildBarracks() => _specializedBuildingService.buildBarracks();
  void buildDefensiveTower() => _specializedBuildingService.buildDefensiveTower();
  void buildWall() => _specializedBuildingService.buildWall();

  // Resource management methods
  void harvestResource() => _resourceService.harvestResource();
  void upgradeBuilding() => _resourceService.upgradeBuilding();
  void repairWall() => _resourceService.repairWall();

  // Helper methods for backward compatibility
  Position? getFirstCityPosition() {
    // Find all city centers directly
    final cityCenters = state.buildings.where(
      (building) => building.type == BuildingType.cityCenter
    ).toList();
    
    if (cityCenters.isNotEmpty) {
      return cityCenters.first.position;
    }
    
    return null;
  }
}

// Provider for the enhanced GameService
final gameServiceProvider = StateNotifierProvider<GameService, GameState>(
  (ref) => GameService(ref),
);