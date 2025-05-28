import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers/game_handlers.dart';
import 'handlers/unit_handlers.dart';
import 'handlers/building_handlers.dart';
import 'handlers/quick_build_handlers.dart';
import 'handlers/player_handlers.dart';
import 'handlers/map_handlers.dart';

/// Main API router that organizes all endpoints
class ApiRouter {
  final ProviderContainer container;
  late final GameHandlers _gameHandlers;
  late final UnitHandlers _unitHandlers;
  late final BuildingHandlers _buildingHandlers;
  late final QuickBuildHandlers _quickBuildHandlers;
  late final PlayerHandlers _playerHandlers;
  late final MapHandlers _mapHandlers;
  
  ApiRouter(this.container) {
    _gameHandlers = GameHandlers(container);
    _unitHandlers = UnitHandlers(container);
    _buildingHandlers = BuildingHandlers(container);
    _quickBuildHandlers = QuickBuildHandlers(container);
    _playerHandlers = PlayerHandlers(container);
    _mapHandlers = MapHandlers(container);
  }
  
  Router get router {
    final router = Router();
    
    // === Server Status ===
    router.get('/status', _gameHandlers.getStatus);

    // === Game Information ===
    router.get('/game-status', _gameHandlers.getGameStatus);
    router.get('/detailed-game-status', _gameHandlers.getDetailedGameStatus);
    router.get('/available-actions', _gameHandlers.getAvailableActions);
    
    // === Unit Management ===
    router.get('/units', _unitHandlers.listPlayerUnits);
    router.get('/units/<playerId>', (Request request, String playerId) => 
        _unitHandlers.getPlayerUnits(request, playerId));
    router.post('/units/select/<unitId>', (Request request, String unitId) => 
        _unitHandlers.selectUnit(request, unitId));
    router.post('/units/move/<unitId>/<x>/<y>', (Request request, String unitId, String x, String y) => 
        _unitHandlers.moveUnit(request, unitId, x, y));
    router.post('/units/attack/<unitId>/<targetX>/<targetY>', (Request request, String unitId, String targetX, String targetY) => 
        _unitHandlers.attack(request, unitId, targetX, targetY));
    router.post('/units/harvest', _unitHandlers.harvestResource);
    
    // === Building Management ===
    router.get('/buildings', _buildingHandlers.listPlayerBuildings);
    router.get('/buildings/<playerId>', (Request request, String playerId) => 
        _buildingHandlers.getPlayerBuildings(request, playerId));
    router.post('/buildings/select/<buildingId>', (Request request, String buildingId) => 
        _buildingHandlers.selectBuilding(request, buildingId));
    router.post('/buildings/upgrade', _buildingHandlers.upgradeBuilding);
    router.post('/buildings/build/<type>/<x>/<y>', (Request request, String type, String x, String y) => 
        _buildingHandlers.buildBuilding(request, type, x, y));
    router.post('/buildings/build-at-position/<x>/<y>', (Request request, String x, String y) => 
        _buildingHandlers.buildBuildingAtPosition(request, x, y));
    router.post('/buildings/build-with-unit/<unitId>/<typeStr>/<x>/<y>', (Request request, String unitId, String typeStr, String x, String y) => 
        _buildingHandlers.buildWithSpecificUnit(request, unitId, typeStr, x, y));
    router.post('/select-building-to-build/<buildingType>', (Request request, String buildingType) => 
        _buildingHandlers.selectBuildingToBuild(request, buildingType));
    
    // === Quick Build Actions ===
    router.post('/quick-build/farm/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildFarm(request, unitId));
    router.post('/quick-build/lumber-camp/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildLumberCamp(request, unitId));
    router.post('/quick-build/mine/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildMine(request, unitId));
    router.post('/quick-build/barracks/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildBarracks(request, unitId));
    router.post('/quick-build/defensive-tower/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildDefensiveTower(request, unitId));
    router.post('/quick-build/wall/<unitId>', (Request request, String unitId) => 
        _quickBuildHandlers.buildWall(request, unitId));
    
    // === Training Units ===
    router.post('/train-unit/<unitType>/<buildingId>', (Request request, String unitType, String buildingId) => 
        _unitHandlers.trainUnit(request, unitType, buildingId));
    router.post('/train-unit-generic/<unitType>', (Request request, String unitType) => 
        _unitHandlers.trainUnitGeneric(request, unitType));
    router.post('/select-unit-to-train/<unitType>', (Request request, String unitType) => 
        _unitHandlers.selectUnitToTrain(request, unitType));
    
    // === Map and Tile Information ===
    router.get('/tile-info/<x>/<y>', (Request request, String x, String y) => 
        _mapHandlers.getTileInfo(request, x, y));
    router.get('/tile-resources/<x>/<y>', (Request request, String x, String y) => 
        _mapHandlers.getTileResources(request, x, y));
    router.get('/area-map/<centerX>/<centerY>/<radius>', (Request request, String centerX, String centerY, String radius) => 
        _mapHandlers.getAreaMap(request, centerX, centerY, radius));
    router.post('/select-tile/<x>/<y>', (Request request, String x, String y) => 
        _mapHandlers.selectTile(request, x, y));
    
    // === Game Flow ===
    router.post('/end-turn', _gameHandlers.endTurn);
    router.post('/clear-selection', _gameHandlers.clearSelection);
    router.post('/found-city', _gameHandlers.foundCity);
    router.post('/start-new-game', _gameHandlers.startNewGame);
    router.post('/give-starting-units', _gameHandlers.giveStartingUnits);
    
    // === Camera Controls ===
    router.post('/jump-to-first-city', _gameHandlers.jumpToFirstCity);
    router.post('/jump-to-enemy-hq', _gameHandlers.jumpToEnemyHeadquarters);
    
    // === Player Management ===
    router.get('/players/all', _playerHandlers.listAllPlayers);
    router.get('/players/current', _playerHandlers.getCurrentPlayer);
    router.get('/player-statistics/<playerId>', (Request request, String playerId) => 
        _playerHandlers.getPlayerStatistics(request, playerId));
    router.get('/scoreboard', _playerHandlers.getScoreboard);
    router.post('/players/add-human/<name>', (Request request, String name) => 
        _playerHandlers.addHumanPlayer(request, name));
    router.post('/players/add-ai/<name>', (Request request, String name) => 
        _playerHandlers.addAIPlayer(request, name));
    router.delete('/players/remove/<playerId>', (Request request, String playerId) => 
        _playerHandlers.removePlayer(request, playerId));
    router.post('/switch-player', _playerHandlers.switchPlayer);
    router.post('/switch-to-player/<playerId>', (Request request, String playerId) => 
        _playerHandlers.switchToPlayer(request, playerId));

    return router;
  }
}
