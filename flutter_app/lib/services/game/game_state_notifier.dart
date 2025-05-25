import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../save_game_service.dart';
import '../../widgets/game_map.dart';

// Provider for the GameMapController
final gameMapControllerProvider = StateProvider<GameMapController?>((ref) {
  return null;
});

// No local GameStateNotifier, using the shared one from game_core
