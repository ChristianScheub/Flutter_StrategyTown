import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/services/controlService/control_service.dart';

/// Migration Helper für GameScreen
/// Diese Klasse hilft dabei, den bestehenden GameScreen schrittweise 
/// auf die Control Service Schicht umzustellen
class GameScreenMigrationHelper {
  final Ref _ref;
  
  GameScreenMigrationHelper(this._ref);
  
  /// Ersetzt alle direkten gameStateProvider.notifier Aufrufe
  GameController get gameController => _ref.read(gameControllerProvider);
  
  // === Ersetzungen für GameStateNotifier Calls ===
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).selectUnit(unitId)
  void selectUnit(String unitId) {
    gameController.selectUnit(unitId);
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).selectBuilding(buildingId)
  void selectBuilding(String buildingId) {
    gameController.selectBuilding(buildingId);
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).selectTile(position)
  void selectTile(Position position) {
    gameController.selectTile(position);
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).nextTurn()
  void nextTurn() {
    gameController.endTurn();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).foundCity()
  void foundCity() {
    gameController.foundCity();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).buildBuilding(position)
  void buildBuilding(Position position) {
    final gameState = gameController.currentGameState;
    if (gameState.buildingToBuild != null) {
      gameController.buildBuilding(gameState.buildingToBuild!, position);
    }
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).trainUnit(unitType)
  void trainUnit(UnitType unitType) {
    final gameState = gameController.currentGameState;
    if (gameState.selectedBuildingId != null) {
      gameController.trainUnit(unitType, gameState.selectedBuildingId!);
    }
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).harvestResource()
  void harvestResource() {
    gameController.harvestResource();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).clearSelection()
  void clearSelection() {
    gameController.clearSelection();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).upgradeBuilding()
  void upgradeBuilding() {
    gameController.upgradeBuilding();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).jumpToFirstCity()
  void jumpToFirstCity() {
    gameController.jumpToFirstCity();
  }
  
  /// Ersetzt: ref.read(gameStateProvider.notifier).jumpToEnemyHeadquarters()
  void jumpToEnemyHeadquarters() {
    gameController.jumpToEnemyHeadquarters();
  }
  
  // === Zusätzliche Helper Methoden ===
  
  /// Initialisiert ein Standard-Spiel wenn noch nicht geschehen
  void ensureGameInitialized() {
    final playerIds = gameController.getAllPlayerIds();
    if (playerIds.isEmpty) {
      final initService = _ref.read(initGameForGuiServiceProvider);
      initService.initSinglePlayerGame();
    }
  }
  
}

/// Provider für den Migration Helper
final gameScreenMigrationHelperProvider = Provider<GameScreenMigrationHelper>((ref) {
  return GameScreenMigrationHelper(ref);
});

