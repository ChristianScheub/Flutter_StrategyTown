import 'package:equatable/equatable.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/buildings/barracks.dart';
import 'package:flutter_sim_city/models/buildings/city_center.dart';
import 'package:flutter_sim_city/models/buildings/defensive_tower.dart';
import 'package:flutter_sim_city/models/buildings/farm.dart';
import 'package:flutter_sim_city/models/buildings/lumber_camp.dart';
import 'package:flutter_sim_city/models/buildings/mine.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/models/buildings/warehouse.dart';
import 'package:flutter_sim_city/models/enemy_faction.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/resource/resources_collection.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/map/tile_map.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';
import 'package:flutter_sim_city/models/units/civilian/settler.dart';
import 'package:flutter_sim_city/models/game/player_manager.dart';
import 'package:flutter_sim_city/models/game/player.dart';

/// Main state class for the game, following equatable pattern
class GameState extends Equatable {
  final TileMap map;
  final List<Unit> units;
  final List<Building> buildings;
  final ResourcesCollection resources; // Legacy: kept for main player resources
  final Position cameraPosition;
  final int turn;
  final String? selectedUnitId;
  final String? selectedBuildingId;
  final Position? selectedTilePosition;
  final BuildingType? buildingToBuild;
  final UnitType? unitToTrain;
  final EnemyFaction? enemyFaction;
  final PlayerManager playerManager;
  final String currentPlayerId; // ADDED: Aktueller Spieler für Mehrspielerzüge

  const GameState({
    required this.map,
    required this.units,
    required this.buildings,
    required this.resources,
    required this.cameraPosition,
    required this.turn,
    this.selectedUnitId,
    this.selectedBuildingId,
    this.selectedTilePosition,
    this.buildingToBuild,
    this.unitToTrain,
    this.enemyFaction,
    required this.playerManager,
    this.currentPlayerId = '', // Leerer String als Default - wird erst beim Hinzufügen von Spielern gesetzt
  });

  factory GameState.initial() {
    final map = TileMap();
    final initialPosition = const Position(x: 0, y: 0);
    return GameState(
      map: map,
      units: [
        Settler.create(initialPosition, ownerID: 'player'),
      ],
      buildings: [],
      resources: ResourcesCollection.initial(),
      cameraPosition: initialPosition,
      turn: 1,
      enemyFaction: null,
      playerManager: PlayerManager.withDefaultPlayer(),
    );
  }

  /// Factory für ein leeres Spiel
  /// Wird für moderne Multiplayer-Initialisierung verwendet
  factory GameState.empty() {
    print('🚀 GameState.empty() called - creating truly empty game state');
    final map = TileMap();
    final initialPosition = const Position(x: 0, y: 0);
    
    // Erstelle einen komplett leeren PlayerManager ohne Default-Spieler
    final playerManager = PlayerManager.empty();
    
    return GameState(
      map: map,
      units: [],
      buildings: [],
      resources: ResourcesCollection.initial(), // Legacy-Ressourcen für UI-Kompatibilität
      cameraPosition: initialPosition,
      turn: 1,
      enemyFaction: null,
      playerManager: playerManager,
      currentPlayerId: '' // Wird beim Hinzufügen von Spielern gesetzt
    );
  }

  GameState copyWith({
    TileMap? map,
    List<Unit>? units,
    List<Building>? buildings,
    ResourcesCollection? resources,
    Position? cameraPosition,
    int? turn,
    String? selectedUnitId,
    String? selectedBuildingId,
    Position? selectedTilePosition,
    BuildingType? buildingToBuild,
    UnitType? unitToTrain,
    EnemyFaction? enemyFaction,
    PlayerManager? playerManager,
    String? currentPlayerId,
  }) {
    return GameState(
      map: map ?? this.map,
      units: units ?? this.units,
      buildings: buildings ?? this.buildings,
      resources: resources ?? this.resources,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      turn: turn ?? this.turn,
      selectedUnitId: selectedUnitId,
      selectedBuildingId: selectedBuildingId,
      selectedTilePosition: selectedTilePosition,
      buildingToBuild: buildingToBuild,
      unitToTrain: unitToTrain,
      enemyFaction: enemyFaction ?? this.enemyFaction,
      playerManager: playerManager ?? this.playerManager,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
    );
  }

  // Get units at position
  List<Unit> getUnitsAt(Position position) {
    return units.where((unit) => unit.position == position).toList();
  }

  // Get buildings at position
  Building? getBuildingAt(Position position) {
    final buildingsAtPosition = buildings.where(
      (building) => building.position == position
    ).toList();
    
    return buildingsAtPosition.isNotEmpty ? buildingsAtPosition.first : null;
  }

  // Get units by ownerID
  List<Unit> getUnitsByOwner(String ownerID) {
    return units.where((unit) => unit.ownerID == ownerID).toList();
  }

  // Get buildings by ownerID
  List<Building> getBuildingsByOwner(String ownerID) {
    return buildings.where((building) => building.ownerID == ownerID).toList();
  }

  // Player management methods using PlayerManager
  List<String> getAllPlayerIDs() => playerManager.playerIds;
  bool hasPlayer(String playerID) => playerManager.hasPlayer(playerID);
  bool isAIPlayer(String playerID) => playerManager.isAIPlayer(playerID);
  bool isHumanPlayer(String playerID) => playerManager.isHumanPlayer(playerID);
  List<String> getHumanPlayers() => playerManager.humanPlayers.map((p) => p.id).toList();
  List<String> getAIPlayers() => playerManager.aiPlayers.map((p) => p.id).toList();
  int get playerCount => playerManager.playerCount;
  int get humanPlayerCount => playerManager.humanPlayerCount;
  int get aiPlayerCount => playerManager.aiPlayerCount;
  /// Always returns true as the game now only uses multiplayer mode
  bool get isMultiplayer => true;
  
  // ADDED: Mehrspielerzug-Management
  /// Wechselt zum nächsten Spieler
  GameState switchToNextPlayer() {
    final playerIds = playerManager.activePlayers.map((p) => p.id).toList();
    if (playerIds.isEmpty) return this;
    
    // Wenn kein aktueller Spieler gesetzt ist oder der aktuelle Spieler nicht mehr existiert,
    // setze den ersten Spieler als aktuell
    if (currentPlayerId.isEmpty || !playerIds.contains(currentPlayerId)) {
      return copyWith(currentPlayerId: playerIds[0]);
    }
    
    final currentIndex = playerIds.indexOf(currentPlayerId);
    final nextIndex = (currentIndex + 1) % playerIds.length;
    
    return copyWith(currentPlayerId: playerIds[nextIndex]);
  }
  
  /// Wechselt zu einem bestimmten Spieler
  GameState switchToPlayer(String playerId) {
    // Prüfe ob der Spieler existiert
    if (playerId.isEmpty || !hasPlayer(playerId)) {
      print('Warnung: Versuch, zu ungültigem Spieler "$playerId" zu wechseln');
      return this;
    }
    return copyWith(currentPlayerId: playerId);
  }
  
  /// Prüft ob der aktuelle Spieler ein Mensch ist
  bool get isCurrentPlayerHuman => currentPlayerId.isNotEmpty && isHumanPlayer(currentPlayerId);
  
  /// Prüft ob der aktuelle Spieler KI ist
  bool get isCurrentPlayerAI => currentPlayerId.isNotEmpty && isAIPlayer(currentPlayerId);
  
  /// Holt den aktuellen Spieler
  Player? get currentPlayer => currentPlayerId.isNotEmpty ? playerManager.getPlayer(currentPlayerId) : null;
  
  /// Holt Einheiten des aktuellen Spielers
  List<Unit> get currentPlayerUnits => currentPlayerId.isNotEmpty ? getUnitsByOwner(currentPlayerId) : [];
  
  /// Holt Gebäude des aktuellen Spielers
  List<Building> get currentPlayerBuildings => currentPlayerId.isNotEmpty ? getBuildingsByOwner(currentPlayerId) : [];
  
  /// Holt Ressourcen des aktuellen Spielers
  ResourcesCollection get currentPlayerResources => 
      currentPlayerId.isNotEmpty ? getPlayerResources(currentPlayerId) : ResourcesCollection.initial();

  // Get selected unit
  Unit? get selectedUnit {
    if (selectedUnitId == null) return null;
    try {
      return units.firstWhere(
        (unit) => unit.id == selectedUnitId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get selected building
  Building? get selectedBuilding {
    if (selectedBuildingId == null) return null;
    try {
      return buildings.firstWhere(
        (building) => building.id == selectedBuildingId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get selected tile
  Tile? get selectedTile {
    if (selectedTilePosition == null) return null;
    return map.getTile(selectedTilePosition!);
  }

  // Check if a position is valid for movement
  bool isValidMovePosition(Position position) {
    final tile = map.getTile(position);
    if (!tile.isWalkable) return false;
    
    // Check if unit can move there based on actionsLeft
    final unit = selectedUnit;
    if (unit == null) return false;
    
    // Wenn die Einheit auf ihrer eigenen Position ist, ist dies gültig
    if (unit.position == position) return true;
    
    // Check if position is within movement range (based on actionsLeft)
    final distance = unit.position.manhattanDistance(position);
    return distance > 0 && distance <= unit.actionsLeft;
  }

  // Gibt alle gültigen Bewegungspositionen für die ausgewählte Einheit zurück
  List<Position> getValidMovePositions() {
    final unit = selectedUnit;
    if (unit == null || !unit.canAct) return [];
    
    final validPositions = <Position>[];
    final range = unit.actionsLeft;
    
    // Überprüfe alle Positionen im Umkreis der Reichweite
    for (int dx = -range; dx <= range; dx++) {
      for (int dy = -range; dy <= range; dy++) {
        // Überspringen, wenn die Manhattan-Distanz außerhalb der Reichweite liegt
        if (dx.abs() + dy.abs() > range) continue;
        
        final newPosition = Position(x: unit.position.x + dx, y: unit.position.y + dy);
        
        // Überspringe die aktuelle Position der Einheit
        if (newPosition == unit.position) continue;
        
        final tile = map.getTile(newPosition);
        if (tile.isWalkable) {
          validPositions.add(newPosition);
        }
      }
    }
    
    return validPositions;
  }

  // Next turn
  GameState nextTurn() {
    // Process end of turn effects for each player
    GameState newState = this;

    // Collect resources for all players
    for (final playerID in playerManager.playerIds) {
      final currentPlayerResources = getPlayerResources(playerID);
      final newPlayerResources = collectResourcesForPlayer(playerID, currentPlayerResources);
      newState = newState.updatePlayerResources(playerID, newPlayerResources);
    }

    // Reset unit actions
    final newUnits = _resetUnitActions();

    return newState.copyWith(
      units: newUnits,
      turn: turn + 1,
      selectedUnitId: null,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
      // Remove automatic player switching
      // currentPlayerId: _nextPlayerId(),
    );
  }

  // Collect resources for a specific player
  ResourcesCollection collectResourcesForPlayer(String playerID, ResourcesCollection currentResources) {
    var newResources = currentResources;
    
    for (final building in buildings) {
      if (building.ownerID == playerID) {
        if (building is Farm) {
          newResources = newResources.add(ResourceType.food, building.foodPerTurn);
        } else if (building is Mine) {
          newResources = newResources.add(ResourceType.stone, building.stonePerTurn);
          newResources = newResources.add(ResourceType.iron, building.ironPerTurn);
        } else if (building is LumberCamp) {
          newResources = newResources.add(ResourceType.wood, building.woodPerTurn);
        }
      }
    }
    
    return newResources;
  }

  // Reset unit actions for new turn
  List<Unit> _resetUnitActions() {
    return units.map((unit) => unit.resetActions()).toList();
  }

  // Helper to create the right building type
  Building createBuilding(BuildingType type, Position position, {required String ownerID}) {
    switch (type) {
      case BuildingType.cityCenter:
        return CityCenter.create(position, ownerID: ownerID);
      case BuildingType.farm:
        return Farm.create(position, ownerID: ownerID);
      case BuildingType.mine:
        return Mine.create(position, ownerID: ownerID);
      case BuildingType.lumberCamp:
        return LumberCamp.create(position, ownerID: ownerID);
      case BuildingType.warehouse:
        return Warehouse.create(position, ownerID: ownerID);
      case BuildingType.barracks:
        return Barracks.create(position, ownerID: ownerID);
      case BuildingType.defensiveTower:
        return DefensiveTower.create(position, ownerID: ownerID);
      case BuildingType.wall:
        return Wall.create(position, ownerID: ownerID);
    }
  }

  // Helper to create the right unit type using the UnitFactory
  Unit createUnit(UnitType type, Position position, {required String ownerID}) {
    return UnitFactory.createUnit(type, position, ownerID: ownerID);
  }

  // Player management methods that modify state
  GameState addPlayer(String playerID, String playerName) {
    try {
      final updatedPlayerManager = playerManager.addHumanPlayer(
        id: playerID,
        name: playerName,
      );
      return copyWith(playerManager: updatedPlayerManager);
    } catch (e) {
      return this; // Player already exists
    }
  }
  
  GameState removePlayer(String playerID) {
    final updatedPlayerManager = playerManager.removePlayer(playerID);
    
    // Remove all units and buildings owned by this player
    final remainingUnits = units.where((unit) => unit.ownerID != playerID).toList();
    final remainingBuildings = buildings.where((building) => building.ownerID != playerID).toList();
    
    return copyWith(
      playerManager: updatedPlayerManager,
      units: remainingUnits,
      buildings: remainingBuildings,
    );
  }
  
  GameState addAIPlayer(String aiID, String aiName) {
    try {
      final updatedPlayerManager = playerManager.addAIPlayer(
        id: aiID,
        name: aiName,
      );
      return copyWith(playerManager: updatedPlayerManager);
    } catch (e) {
      return this; // Player already exists
    }
  }

  GameState addMultipleAIPlayers(int count, {String namePrefix = 'AI Player'}) {
    final updatedPlayerManager = playerManager.addMultipleAIPlayers(count, namePrefix: namePrefix);
    return copyWith(playerManager: updatedPlayerManager);
  }
  
  // Get resources for a specific player
  ResourcesCollection getPlayerResources(String playerID) {
    final player = playerManager.getPlayer(playerID);
    return player?.resources ?? ResourcesCollection.initial();
  }
  
  // Update player resources
  GameState updatePlayerResources(String playerID, ResourcesCollection newResources) {
    try {
      final updatedPlayerManager = playerManager.updatePlayerResources(playerID, newResources);
      
      // Also update legacy resources if it's the main player
      final updatedLegacyResources = playerID == 'player' ? newResources : resources;
      
      return copyWith(
        playerManager: updatedPlayerManager,
        resources: updatedLegacyResources,
      );
    } catch (e) {
      return this; // Player not found
    }
  }
  
  // Check if player owns any units
  bool playerHasUnits(String playerID) {
    return units.any((unit) => unit.ownerID == playerID);
  }
  
  // Check if player owns any buildings
  bool playerHasBuildings(String playerID) {
    return buildings.any((building) => building.ownerID == playerID);
  }
  
  // Check if player is still active (has units or buildings)
  bool isPlayerActive(String playerID) {
    return playerHasUnits(playerID) || playerHasBuildings(playerID);
  }
  
  // Get all active players (those with units or buildings)
  List<String> getActivePlayers() {
    return playerManager.playerIds.where((playerID) => isPlayerActive(playerID)).toList();
  }
  
  // Remove inactive players (no units or buildings)
  GameState removeInactivePlayers() {
    final inactivePlayers = playerManager.playerIds
        .where((playerID) => !isPlayerActive(playerID))
        .toList();
    
    GameState newState = this;
    for (final playerID in inactivePlayers) {
      newState = newState.removePlayer(playerID);
    }
    
    return newState;
  }
  
  // Get player statistics
  Map<String, Map<String, dynamic>> getPlayerStatistics() {
    final baseStats = playerManager.getPlayerStatistics();
    
    // Add game-specific statistics
    for (final playerID in playerManager.playerIds) {
      baseStats[playerID] = {
        ...baseStats[playerID]!,
        'units': getUnitsByOwner(playerID).length,
        'buildings': getBuildingsByOwner(playerID).length,
        'settlements': getBuildingsByOwner(playerID)
            .where((building) => building.type == BuildingType.cityCenter)
            .length,
      };
    }
    
    return baseStats;
  }

  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'map': map.toJson(),
      'units': units.map((unit) => unit.toJson()).toList(),
      'buildings': buildings.map((building) => building.toJson()).toList(),
      'resources': resources.toJson(),
      'cameraPosition': cameraPosition.toJson(),
      'turn': turn,
      'enemyFaction': enemyFaction?.toJson(),
      'playerManager': playerManager.toJson(),
      'currentPlayerId': currentPlayerId,
    };
  }
  
  // Deserialization from JSON
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      map: TileMap.fromJson(json['map']),
      units: (json['units'] as List<dynamic>)
          .map((unitJson) => UnitFactory.fromJson(unitJson))
          .toList(),
      buildings: (json['buildings'] as List<dynamic>)
          .map((buildingJson) => _deserializeBuilding(buildingJson))
          .toList(),
      resources: ResourcesCollection.fromJson(json['resources']),
      cameraPosition: Position.fromJson(json['cameraPosition']),
      turn: json['turn'],
      enemyFaction: json['enemyFaction'] != null ? EnemyFaction.fromJson(json['enemyFaction']) : null,
      playerManager: json['playerManager'] != null 
          ? PlayerManager.fromJson(json['playerManager'])
          : PlayerManager.withDefaultPlayer(),
      currentPlayerId: json['currentPlayerId'] ?? 'player',
    );
  }

  // Helper for deserializing buildings
  static Building _deserializeBuilding(Map<String, dynamic> json) {
    final typeString = json['type'];
    BuildingType? buildingType;
    
    for (final type in BuildingType.values) {
      if (type.toString().split('.').last == typeString) {
        buildingType = type;
        break;
      }
    }
    
    if (buildingType == null) {
      throw Exception('Unknown building type: $typeString');
    }
    
    final position = Position.fromJson(json['position']);
    final id = json['id'];
    final level = json['level'] ?? 1;
    final ownerID = json['ownerID'] ?? 'player'; // Fallback für alte Speicherstände
    
    // Create the specific building type based on the type
    switch (buildingType) {
      case BuildingType.cityCenter:
        return CityCenter.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.farm:
        return Farm.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.mine:
        return Mine.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.lumberCamp:
        return LumberCamp.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.warehouse:
        return Warehouse.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.barracks:
        return Barracks.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.defensiveTower:
        return DefensiveTower.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
      case BuildingType.wall:
        return Wall.create(position, ownerID: ownerID)
            .copyWith(id: id, level: level);
    }
  }

  @override
  List<Object?> get props => [
    map,
    units,
    buildings,
    resources,
    cameraPosition,
    turn,
    selectedUnitId,
    selectedBuildingId,
    selectedTilePosition,
    buildingToBuild,
    unitToTrain,
    enemyFaction,
    playerManager,
    currentPlayerId, // ADDED: Aktueller Spieler
  ];
}