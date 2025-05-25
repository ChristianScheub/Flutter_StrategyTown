import 'package:game_core/src/models/combat/combat_helper.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/units/unit_abilities.dart';
import 'package:game_core/src/services/game/base_game_service.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';

class CombatService extends BaseGameService {
  CombatService(GameStateNotifier notifier) : super(notifier);

  void attackEnemyTarget(Position targetPosition) {
    final unit = selectedUnit;
    
    if (unit == null || !(unit is CombatCapable) || !unit.canAct) {
      return;
    }
    
    if (!CombatHelper.canAttackEnemyAt(state, unit, targetPosition)) {
      return;
    }
    
    final updatedState = CombatHelper.attackEnemyAt(state, unit, targetPosition);
    updateState(updatedState);
  }
}
