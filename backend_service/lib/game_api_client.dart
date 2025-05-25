import 'dart:convert';
import 'package:http/http.dart' as http;

/// A client for the Game Backend API
class GameApiClient {
  final String baseUrl;

  GameApiClient({this.baseUrl = 'http://localhost:8080/api'});

  /// Makes a GET request to the API
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
    return _processResponse(response);
  }

  /// Makes a POST request to the API
  Future<Map<String, dynamic>> post(String endpoint, [Map<String, dynamic>? data]) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: data != null ? json.encode(data) : null,
    );
    return _processResponse(response);
  }

  /// Makes a DELETE request to the API
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl/$endpoint'));
    return _processResponse(response);
  }

  /// Process the HTTP response and handle errors
  Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Explicitly cast the decoded JSON to Map<String, dynamic>
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final error = json.decode(response.body) as Map<String, dynamic>; // Also cast the error body
      throw ApiException(
        // Explicitly cast error['error'] to String, or provide a default if it might be null
        message: (error['error'] as String?) ?? 'Unknown error',
        statusCode: response.statusCode,
      );
    }
  }

  // === Game Information ===
  Future<Map<String, dynamic>> getStatus() => get('status');
  Future<Map<String, dynamic>> getGameStatus() => get('game-status');
  Future<Map<String, dynamic>> getDetailedGameStatus() => get('detailed-game-status');
  Future<Map<String, dynamic>> getAvailableActions() => get('available-actions');

  // === Unit Management ===
  Future<Map<String, dynamic>> listPlayerUnits() => get('units');
  Future<Map<String, dynamic>> getPlayerUnits(String playerId) => get('units/$playerId');
  Future<Map<String, dynamic>> selectUnit(String unitId) => post('units/select/$unitId');
  Future<Map<String, dynamic>> moveUnit(String unitId, int x, int y) =>
      post('units/move/$unitId/$x/$y');
  Future<Map<String, dynamic>> attack(String unitId, int targetX, int targetY) =>
      post('units/attack/$unitId/$targetX/$targetY');
  Future<Map<String, dynamic>> harvestResource() => post('units/harvest');

  // === Building Management ===
  Future<Map<String, dynamic>> listPlayerBuildings() => get('buildings');
  Future<Map<String, dynamic>> getPlayerBuildings(String playerId) => get('buildings/$playerId');
  Future<Map<String, dynamic>> selectBuilding(String buildingId) =>
      post('buildings/select/$buildingId');
  Future<Map<String, dynamic>> upgradeBuilding() => post('buildings/upgrade');
  Future<Map<String, dynamic>> buildBuilding(String type, int x, int y) =>
      post('buildings/build/$type/$x/$y');
  Future<Map<String, dynamic>> buildBuildingAtPosition(int x, int y) =>
      post('buildings/build-at-position/$x/$y');

  // === Quick Build Actions ===
  Future<Map<String, dynamic>> buildFarm() => post('quick-build/farm');
  Future<Map<String, dynamic>> buildLumberCamp() => post('quick-build/lumber-camp');
  Future<Map<String, dynamic>> buildMine() => post('quick-build/mine');
  Future<Map<String, dynamic>> buildBarracks() => post('quick-build/barracks');
  Future<Map<String, dynamic>> buildDefensiveTower() => post('quick-build/defensive-tower');
  Future<Map<String, dynamic>> buildWall() => post('quick-build/wall');

  // === Training Units ===
  Future<Map<String, dynamic>> trainUnit(String unitType, String buildingId) =>
      post('train-unit/$unitType/$buildingId');
  Future<Map<String, dynamic>> trainUnitGeneric(String unitType) =>
      post('train-unit-generic/$unitType');
  Future<Map<String, dynamic>> selectUnitToTrain(String unitType) =>
      post('select-unit-to-train/$unitType');
  Future<Map<String, dynamic>> selectBuildingToBuild(String buildingType) =>
      post('select-building-to-build/$buildingType');

  // === Map and Tile Information ===
  Future<Map<String, dynamic>> getTileInfo(int x, int y) => get('tile-info/$x/$y');
  Future<Map<String, dynamic>> getTileResources(int x, int y) => get('tile-resources/$x/$y');
  Future<Map<String, dynamic>> getAreaMap(int centerX, int centerY, int radius) =>
      get('area-map/$centerX/$centerY/$radius');
  Future<Map<String, dynamic>> selectTile(int x, int y) => post('select-tile/$x/$y');

  // === Game Flow ===
  Future<Map<String, dynamic>> endTurn() => post('end-turn');
  Future<Map<String, dynamic>> clearSelection() => post('clear-selection');
  Future<Map<String, dynamic>> foundCity() => post('found-city');

  // === Camera Controls ===
  Future<Map<String, dynamic>> jumpToFirstCity() => post('jump-to-first-city');
  Future<Map<String, dynamic>> jumpToEnemyHeadquarters() => post('jump-to-enemy-hq');

  // === Game Management ===
  Future<Map<String, dynamic>> startNewGame() => post('start-new-game');
  Future<Map<String, dynamic>> saveGame(String name) => post('save-game/$name');
  Future<Map<String, dynamic>> loadGame(String key) => post('load-game/$key');

  // === Player Management ===
  Future<Map<String, dynamic>> listAllPlayers() => get('players/all');
  Future<Map<String, dynamic>> getCurrentPlayer() => get('players/current');
  Future<Map<String, dynamic>> getPlayerStatistics(String playerId) =>
      get('player-statistics/$playerId');
  Future<Map<String, dynamic>> getScoreboard() => get('scoreboard');
  Future<Map<String, dynamic>> addHumanPlayer(String name) => post('players/add-human/$name');
  Future<Map<String, dynamic>> addAIPlayer(String name) => post('players/add-ai/$name');
  Future<Map<String, dynamic>> removePlayer(String playerId) => delete('players/remove/$playerId');

  // === Multiplayer Controls ===
  Future<Map<String, dynamic>> switchPlayer() => post('switch-player');
  Future<Map<String, dynamic>> switchToPlayer(String playerId) => post('switch-to-player/$playerId');
}

/// Exception thrown when API calls fail
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}