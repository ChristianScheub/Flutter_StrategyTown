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
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/resource/resources_collection.dart';
import 'package:flutter_sim_city/models/units/unit.dart';
import 'package:flutter_sim_city/models/units/unit_factory.dart';

/// Repräsentiert eine feindliche Fraktion im Spiel, die eigene Gebäude und Einheiten hat
class EnemyFaction extends Equatable {
  final String id;
  final String name;
  final List<Building> buildings;
  final List<Unit> units;
  final ResourcesCollection resources;
  final int aggressiveness; // 1-10, beeinflusst wie aggressiv die KI spielt
  final int expansionRate; // 1-10, wie schnell die Fraktion expandiert
  final Position? headquarters; // Position des Hauptquartiers (Stadt)
  final String? currentStrategy; // Aktuelle KI-Strategie

  const EnemyFaction({
    required this.id,
    required this.name,
    required this.buildings,
    required this.units,
    required this.resources,
    required this.aggressiveness,
    required this.expansionRate,
    this.headquarters,
    this.currentStrategy, // Neue Property für die Strategie
  });

  /// Erstellt eine neue feindliche Fraktion mit Standardwerten
  factory EnemyFaction.create(String name, Position cityPosition) {
    return EnemyFaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      buildings: [],
      units: [],
      resources: ResourcesCollection.initial().add(ResourceType.food, 200),
      aggressiveness: 5, // Standardwert für Aggressivität
      expansionRate: 5, // Standardwert für Expansionsrate
      headquarters: cityPosition,
      currentStrategy: 'recruit', // Startphase ist Rekrutierung
    );
  }

  /// Kopiert diese Fraktion mit aktualisierten Werten
  EnemyFaction copyWith({
    String? id,
    String? name,
    List<Building>? buildings,
    List<Unit>? units,
    ResourcesCollection? resources,
    int? aggressiveness,
    int? expansionRate,
    Position? headquarters,
    String? currentStrategy,
  }) {
    return EnemyFaction(
      id: id ?? this.id,
      name: name ?? this.name,
      buildings: buildings ?? this.buildings,
      units: units ?? this.units,
      resources: resources ?? this.resources,
      aggressiveness: aggressiveness ?? this.aggressiveness,
      expansionRate: expansionRate ?? this.expansionRate,
      headquarters: headquarters ?? this.headquarters,
      currentStrategy: currentStrategy ?? this.currentStrategy,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'buildings': buildings.map((building) => building.toJson()).toList(),
      'units': units.map((unit) => unit.toJson()).toList(),
      'resources': resources.toJson(),
      'aggressiveness': aggressiveness,
      'expansionRate': expansionRate,
      'headquarters': headquarters?.toJson(),
      'currentStrategy': currentStrategy,
    };
  }

  // For deserialization, we'll need to create a custom approach since we need to handle buildings and units
  static EnemyFaction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    return EnemyFaction(
      id: json['id'],
      name: json['name'],
      buildings: (json['buildings'] as List<dynamic>)
          .map((buildingJson) => _deserializeBuilding(buildingJson))
          .toList(),
      units: (json['units'] as List<dynamic>)
          .map((unitJson) => UnitFactory.fromJson(unitJson))
          .toList(),
      resources: ResourcesCollection.fromJson(json['resources']),
      aggressiveness: json['aggressiveness'],
      expansionRate: json['expansionRate'],
      headquarters: json['headquarters'] != null
          ? Position.fromJson(json['headquarters'])
          : null,
      currentStrategy: json['currentStrategy'],
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
        id,
        name,
        buildings,
        units,
        resources,
        aggressiveness,
        expansionRate,
        headquarters,
        currentStrategy,
      ];
}
