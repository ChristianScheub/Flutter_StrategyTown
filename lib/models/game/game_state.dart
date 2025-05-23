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

/// Main state class for the game, following equatable pattern
class GameState extends Equatable {
  final TileMap map;
  final List<Unit> units;
  final List<Building> buildings;
  final ResourcesCollection resources;
  final Position cameraPosition;
  final int turn;
  final String? selectedUnitId;
  final String? selectedBuildingId;
  final Position? selectedTilePosition;
  final BuildingType? buildingToBuild;
  final UnitType? unitToTrain;
  final EnemyFaction? enemyFaction; // Feindliche Fraktion
  final int playerPoints;
  final int aiPoints;

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
    this.playerPoints = 0,
    this.aiPoints = 0,
  });

  factory GameState.initial() {
    final map = TileMap();
    final initialPosition = const Position(x: 0, y: 0);
    return GameState(
      map: map,
      units: [
        Settler.create(initialPosition),
      ],
      buildings: [],
      resources: ResourcesCollection.initial(),
      cameraPosition: initialPosition,
      turn: 1,
      enemyFaction: null, // Will be created by AIService on first turn
      playerPoints: 0,
      aiPoints: 0,
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
    int? playerPoints,
    int? aiPoints,
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
      playerPoints: playerPoints ?? this.playerPoints,
      aiPoints: aiPoints ?? this.aiPoints,
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
    // Process end of turn effects
    final newResources = _collectResources();
    final newUnits = _resetUnitActions();
    
    return copyWith(
      resources: newResources,
      units: newUnits,
      turn: turn + 1,
      selectedUnitId: null,
      selectedBuildingId: null,
      selectedTilePosition: null,
      buildingToBuild: null,
      unitToTrain: null,
    );
  }

  // Collect resources from buildings
  ResourcesCollection _collectResources() {
    var newResources = resources;
    
    for (final building in buildings) {
      if (building is Farm) {
        newResources = newResources.add(ResourceType.food, building.foodPerTurn);
      } else if (building is Mine) {
        newResources = newResources.add(ResourceType.stone, building.stonePerTurn);
        newResources = newResources.add(ResourceType.iron, building.ironPerTurn);
      } else if (building is LumberCamp) {
        newResources = newResources.add(ResourceType.wood, building.woodPerTurn);
      }
    }
    
    return newResources;
  }

  // Reset unit actions for new turn
  List<Unit> _resetUnitActions() {
    return units.map((unit) => unit.resetActions()).toList();
  }

  // Helper to create the right building type
  Building createBuilding(BuildingType type, Position position) {
    switch (type) {
      case BuildingType.cityCenter:
        return CityCenter.create(position);
      case BuildingType.farm:
        return Farm.create(position);
      case BuildingType.mine:
        return Mine.create(position);
      case BuildingType.lumberCamp:
        return LumberCamp.create(position);
      case BuildingType.warehouse:
        return Warehouse.create(position);
      case BuildingType.barracks:
        return Barracks.create(position);
      case BuildingType.defensiveTower:
        return DefensiveTower.create(position);
      case BuildingType.wall:
        return Wall.create(position);
    }
  }

  // Helper to create the right unit type using the UnitFactory
  Unit createUnit(UnitType type, Position position) {
    return UnitFactory.createUnit(type, position);
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
      'playerPoints': playerPoints,
      'aiPoints': aiPoints,
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
      enemyFaction: EnemyFaction.fromJson(json['enemyFaction']),
      playerPoints: json['playerPoints'] ?? 0,
      aiPoints: json['aiPoints'] ?? 0,
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
    
    // Create the specific building type based on the type
    switch (buildingType) {
      case BuildingType.cityCenter:
        return CityCenter.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.farm:
        return Farm.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.mine:
        return Mine.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.lumberCamp:
        return LumberCamp.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.warehouse:
        return Warehouse.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.barracks:
        return Barracks.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.defensiveTower:
        return DefensiveTower.create(position)
            .copyWith(id: id, level: level);
      case BuildingType.wall:
        return Wall.create(position)
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
    playerPoints,
    aiPoints,
  ];
}