import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/services/game/base_game_service.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';

class MovementService extends BaseGameService {
  MovementService(GameStateNotifier notifier) : super(notifier);

  void moveSelectedUnit(Position newPosition) {
    final unit = selectedUnit;
    if (unit == null || !unit.canAct) return;

    final tile = state.map.getTile(newPosition);
    if (!tile.isWalkable) return;

    // Calculate movement cost (Manhattan distance)
    final distance = unit.position.manhattanDistance(newPosition);
    
    // Check if unit has enough action points
    if (distance > unit.actionsLeft) return;

    final newUnits = state.units.map((u) {
      if (u.id == unit.id) {
        return u.copyWith(
          position: newPosition,
          actionsLeft: u.actionsLeft - distance
        );
      }
      return u;
    }).toList();

    updateState(state.copyWith(units: newUnits));
  }
}
