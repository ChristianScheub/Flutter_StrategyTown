import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/models/map/position.dart';
import 'package:game_core/src/services/game/game_state_notifier.dart';
import 'package:game_core/src/services/controlService/player_control_service.dart';
import 'package:game_core/src/services/controlService/game_action_service.dart';
import 'package:game_core/src/services/controlService/game_state_service.dart';

/// Hauptkontroller für das Spiel - Abstraktion zwischen UI und Spiel-Engine
/// Diese Schicht kann sowohl von der UI als auch von einem Tensorflow Modell verwendet werden
class GameController {
  final Ref _ref;
  late final PlayerControlService _playerControlService;
  late final GameActionService _gameActionService;
  late final GameStateService _gameStateService;
  
  GameController(this._ref) {
    _initializeServices();
  }
  
  void _initializeServices() {
    _playerControlService = PlayerControlService(_ref);
    _gameActionService = GameActionService(_ref);
    _gameStateService = GameStateService(_ref);
  }
  
  // === Game State Access ===
  GameState get currentGameState => _gameStateService.currentState;
  
  /// Prüft ob das Spiel läuft
  bool get isGameActive => _gameStateService.isGameActive;
  
  /// Aktuelle Rundenanzahl
  int get currentTurn => currentGameState.turn;
  
  // === ADDED: Mehrspielerzugriff ===
  
  /// Aktueller Spieler ID
  String get currentPlayerId => _gameStateService.currentPlayerId;
  
  /// Prüft ob der aktuelle Spieler ein Mensch ist
  bool get isCurrentPlayerHuman => _gameStateService.isCurrentPlayerHuman;
  
  /// Prüft ob der aktuelle Spieler KI ist
  bool get isCurrentPlayerAI => _gameStateService.isCurrentPlayerAI;
  
  /// Wechselt zum nächsten Spieler
  void switchToNextPlayer() => _gameStateService.switchToNextPlayer();
  
  /// Wechselt zu einem bestimmten Spieler
  void switchToPlayer(String playerId) => _gameStateService.switchToPlayer(playerId);
  
  /// Aktuelle Ressourcen des aktuellen Spielers
  Map<String, int> get currentPlayerResources => _gameStateService.getCurrentPlayerResources();
  
  /// Alle Einheiten des aktuellen Spielers
  List<Unit> get currentPlayerUnits => _gameStateService.getCurrentPlayerUnits();
  
  /// Alle Gebäude des aktuellen Spielers
  List<Building> get currentPlayerBuildings => _gameStateService.getCurrentPlayerBuildings();
  
  // === END Mehrspielerzugriff ===
  
  /// Aktuelle Ressourcen des Spielers (Legacy - nutzt aktuellen Spieler)
  Map<String, int> get playerResources => _gameStateService.getCurrentPlayerResources();
  
  /// Alle Einheiten des Spielers (Legacy - nutzt aktuellen Spieler)
  List<Unit> get playerUnits => _gameStateService.getCurrentPlayerUnits();
  
  /// Alle Gebäude des Spielers (Legacy - nutzt aktuellen Spieler)
  List<Building> get playerBuildings => _gameStateService.getCurrentPlayerBuildings();
  
  /// Feindliche Einheiten
  List<Unit> get enemyUnits => _gameStateService.getEnemyUnits();
  
  /// Feindliche Gebäude
  List<Building> get enemyBuildings => _gameStateService.getEnemyBuildings();
  
  // === Player Management ===
  /// Fügt einen menschlichen Spieler hinzu
  bool addHumanPlayer(String playerName, {String? playerId}) {
    return _playerControlService.addHumanPlayer(playerName, playerId: playerId);
  }
  
  /// Fügt einen KI-Spieler hinzu
  bool addAIPlayer(String playerName, {String? playerId}) {
    return _playerControlService.addAIPlayer(playerName, playerId: playerId);
  }
  
  /// Entfernt einen Spieler
  bool removePlayer(String playerId) {
    return _playerControlService.removePlayer(playerId);
  }
  
  /// Holt alle Spieler
  List<String> getAllPlayerIds() {
    return _playerControlService.getAllPlayerIds();
  }
  
  // === Game Actions ===
  /// Wählt eine Einheit aus
  void selectUnit(String unitId) {
    _gameActionService.selectUnit(unitId);
  }
  
  /// Wählt ein Gebäude aus
  void selectBuilding(String buildingId) {
    _gameActionService.selectBuilding(buildingId);
  }
  
  /// Wählt eine Kachel aus
  void selectTile(Position position) {
    _gameActionService.selectTile(position);
  }
  
  /// Hebt die Auswahl auf
  void clearSelection() {
    _gameActionService.clearSelection();
  }
  
  /// Bewegt eine Einheit zu einer Position
  bool moveUnit(String unitId, Position targetPosition) {
    return _gameActionService.moveUnit(unitId, targetPosition);
  }
  
  /// Baut ein Gebäude
  bool buildBuilding(BuildingType buildingType, Position position) {
    return _gameActionService.buildBuilding(buildingType, position);
  }
  
  /// Baut ein Gebäude an der Position (verwendet das aktuell ausgewählte Gebäude)
  bool buildBuildingAtPosition(Position position) {
    _ref.read(gameStateProvider.notifier).buildBuilding(position);
    return true;
  }
  
  /// Trainiert eine Einheit
  bool trainUnit(UnitType unitType, String buildingId) {
    return _gameActionService.trainUnit(unitType, buildingId);
  }
  
  /// Allgemeine Trainings-Methode für UI
  bool trainUnitGeneric(UnitType unitType) {
    _ref.read(gameStateProvider.notifier).trainUnit(unitType);
    return true;
  }
  
  /// Greift ein Ziel an
  bool attackTarget(String attackerUnitId, Position targetPosition) {
    return _gameActionService.attackTarget(attackerUnitId, targetPosition);
  }
  
  /// Gründet eine Stadt
  bool foundCity() {
    return _gameActionService.foundCity();
  }
  
  /// Erntet Ressourcen
  bool harvestResource() {
    return _gameActionService.harvestResource();
  }
  
  /// Verbessert ein Gebäude
  bool upgradeBuilding() {
    return _gameActionService.upgradeBuilding();
  }
  
  /// Beendet den aktuellen Zug
  void endTurn() {
    _gameActionService.endTurn();
  }
  
  /// Springt zur ersten Stadt
  void jumpToFirstCity() {
    _gameActionService.jumpToFirstCity();
  }
  
  /// Springt zum feindlichen Hauptquartier
  void jumpToEnemyHeadquarters() {
    _gameActionService.jumpToEnemyHeadquarters();
  }
  
  /// Springt zum ersten Siedler
  void jumpToFirstSettler() {
    _gameActionService.jumpToFirstSettler();
  }
  
  // === Building Actions ===
  /// Wählt ein Gebäude zum Bauen aus
  void selectBuildingToBuild(BuildingType buildingType) {
    _ref.read(gameStateProvider.notifier).selectBuildingToBuild(buildingType);
  }
  
  /// Wählt eine Einheit zum Trainieren aus
  void selectUnitToTrain(UnitType unitType) {
    _ref.read(gameStateProvider.notifier).selectUnitToTrain(unitType);
  }
  
  /// Baut spezifische Gebäudetypen
  bool buildFarm() {
    _ref.read(gameStateProvider.notifier).buildFarm();
    return true;
  }
  
  bool buildLumberCamp() {
    _ref.read(gameStateProvider.notifier).buildLumberCamp();
    return true;
  }
  
  bool buildMine() {
    _ref.read(gameStateProvider.notifier).buildMine();
    return true;
  }
  
  bool buildBarracks() {
    _ref.read(gameStateProvider.notifier).buildBarracks();
    return true;
  }
  
  bool buildDefensiveTower() {
    _ref.read(gameStateProvider.notifier).buildDefensiveTower();
    return true;
  }
  
  bool buildWall() {
    _ref.read(gameStateProvider.notifier).buildWall();
    return true;
  }
  
  // === Game Management ===
  /// Startet ein neues Spiel
  void startNewGame() {
    _gameStateService.startNewGame();
  }
}

/// Provider für den GameController
final gameControllerProvider = Provider<GameController>((ref) {
  return GameController(ref);
});
