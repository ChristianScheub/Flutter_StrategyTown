import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/services/game/base_game_service.dart';
import 'package:flutter_sim_city/services/game/game_state_notifier.dart';
import 'package:flutter_sim_city/widgets/game_map.dart';

class CameraService extends BaseGameService {
  final Ref _ref;

  CameraService(GameStateNotifier notifier, this._ref) : super(notifier);

  void moveCamera(Position newPosition) {
    updateState(state.copyWith(cameraPosition: newPosition));
  }

  Position? getFirstCityPosition() {
    final cityCenters = state.buildings.where(
      (building) => building.type == BuildingType.cityCenter
    ).toList();
    
    print('Gefundene Städte: ${cityCenters.length}');
    if (cityCenters.isNotEmpty) {
      final firstCityPos = cityCenters.first.position;
      print('Erste Stadt Position: (${firstCityPos.x}, ${firstCityPos.y})');
      return firstCityPos;
    }
    
    print('Keine Städte gefunden!');
    return null;
  }

  void jumpToFirstCity() {
    final firstCityPosition = getFirstCityPosition();
    if (firstCityPosition == null) return;
    
    moveCamera(firstCityPosition);
    
    final cityCenters = state.buildings.where(
      (building) => building.type == BuildingType.cityCenter
    ).toList();
    
    if (cityCenters.isNotEmpty) {
      _selectBuilding(cityCenters.first.id);
      _jumpCameraToPosition(firstCityPosition);
      print('Stadt ausgewählt! ID: ${cityCenters.first.id}, Position: (${firstCityPosition.x}, ${firstCityPosition.y})');
    }
  }

  void jumpToEnemyHeadquarters() {
    if (state.enemyFaction?.headquarters == null) return;
    
    final headquartersPosition = state.enemyFaction!.headquarters!;
    moveCamera(headquartersPosition);
    _jumpCameraToPosition(headquartersPosition);
    print('GameMap controller used to jump to enemy headquarters position: (${headquartersPosition.x}, ${headquartersPosition.y})');
  }

  void _selectBuilding(String buildingId) {
    updateState(state.copyWith(
      selectedUnitId: null,
      selectedBuildingId: buildingId,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    ));
  }

  void _jumpCameraToPosition(Position position) {
    final controller = _ref.read(gameMapControllerProvider);
    if (controller?.jumpToPosition != null) {
      controller!.jumpToPosition!(position);
    } else {
      print('GameMap controller not initialized or jumpToPosition is null');
    }
  }
}
