import 'package:equatable/equatable.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/buildings/barracks.dart';
import 'package:flutter_sim_city/models/buildings/city_center.dart';
import 'package:flutter_sim_city/models/buildings/defensive_tower.dart';
import 'package:flutter_sim_city/models/buildings/farm.dart';
import 'package:flutter_sim_city/models/buildings/lumber_camp.dart';
import 'package:flutter_sim_city/models/buildings/mine.dart';
import 'package:flutter_sim_city/models/buildings/wall.dart';
import 'package:flutter_sim_city/models/buildings/warehouse.dart';

enum BuildingType {
  cityCenter,
  farm,
  mine,
  lumberCamp,
  warehouse,
  barracks,
  defensiveTower,
  wall,
}

/// Basis Baukosten für alle Gebäude
const Map<BuildingType, Map<ResourceType, int>> baseBuildingCosts = {
  BuildingType.cityCenter: {
    ResourceType.wood: 100,
    ResourceType.stone: 100,
    ResourceType.food: 50,
  },
  BuildingType.farm: {
    ResourceType.wood: 30,
    ResourceType.stone: 10,
  },
  BuildingType.mine: {
    ResourceType.wood: 40,
  },
  BuildingType.lumberCamp: {
    ResourceType.stone: 30,
  },
  BuildingType.warehouse: {
    ResourceType.wood: 50,
    ResourceType.stone: 50,
    ResourceType.iron: 20,
  },
  BuildingType.barracks: {
    ResourceType.wood: 80,
    ResourceType.stone: 60,
    ResourceType.iron: 40,
  },
  BuildingType.defensiveTower: {
    ResourceType.stone: 60,
    ResourceType.wood: 30,
    ResourceType.iron: 20,
  },
  BuildingType.wall: {
    ResourceType.stone: 40,
    ResourceType.wood: 10,
  },
};

/// Basis-Upgrade-Faktoren für alle Gebäude
const Map<BuildingType, double> baseUpgradeFactors = {
  BuildingType.cityCenter: 1.5,
  BuildingType.farm: 1.3,
  BuildingType.mine: 1.3,
  BuildingType.lumberCamp: 1.3,
  BuildingType.warehouse: 1.4,
  BuildingType.barracks: 1.4,
  BuildingType.defensiveTower: 1.4,
  BuildingType.wall: 1.3,
};

/// Zentrale Produktionswerte für Gebäude
const Map<BuildingType, Map<ResourceType, int>> baseProductionValues = {
  BuildingType.farm: {ResourceType.food: 10},
  BuildingType.lumberCamp: {ResourceType.wood: 12},
  BuildingType.mine: {ResourceType.stone: 8, ResourceType.iron: 3},
  // Weitere Gebäude nach Bedarf
};

/// Abstract base class for all buildings
abstract class Building extends Equatable {
  final String id;
  final BuildingType type;
  final Position position;
  final int level;
  final int maxHealth;
  final int currentHealth;
  final String ownerID; // Owner of the building (player or AI identifier)

  Building({
    required this.id,
    required this.type,
    required this.position,
    this.level = 1,
    int? maxHealth,
    int? currentHealth,
    required this.ownerID,
  }) : 
    maxHealth = maxHealth ?? _getBaseHealth(type),
    currentHealth = currentHealth ?? maxHealth ?? _getBaseHealth(type);

  /// Base health values for different building types
  static int _getBaseHealth(BuildingType type) {
    switch (type) {
      case BuildingType.cityCenter:
        return 200;
      case BuildingType.defensiveTower:
      case BuildingType.wall:
        return 150;
      case BuildingType.barracks:
        return 120;
      default:
        return 100;
    }
  }

  /// Abstract copyWith method that must be implemented by subclasses
  Building copyWith({
    String? id,
    BuildingType? type,
    Position? position,
    int? level,
    int? maxHealth,
    int? currentHealth,
    String? ownerID,
  });

  /// Gibt die Produktionswerte des Gebäudes zurück (Standard: keine Produktion)
  Map<ResourceType, int> getProduction() {
    return baseProductionValues[type] ?? {};
  }

  /// Template-Methode für Upgrade: ruft spezifische Upgrades der Subklasse ab
  Building upgrade() {
    final upgraded = copyWith(
      level: level + 1,
      maxHealth: (maxHealth * 1.2).round(),
    );
    return upgraded.applyUpgradeValues();
  }

  /// Kann von Subklassen überschrieben werden, um spezifische Werte zu upgraden
  Building applyUpgradeValues() {
    // Default: keine weiteren Upgrades
    return this;
  }

  /// Calculate upgrade costs based on base costs and level
  Map<ResourceType, int> getUpgradeCost() {
    final baseCosts = baseBuildingCosts[type] ?? {};
    final upgradeFactor = baseUpgradeFactors[type] ?? 1.3;
    
    return baseCosts.map((type, cost) {
      final levelFactor = upgradeFactor * (1 + (level - 1) * 0.2); // Additional 20% per level
      return MapEntry(type, (cost * levelFactor).round());
    });
  }

  /// Check if building can be repaired
  bool get needsRepair => currentHealth < maxHealth;

  /// Calculate repair costs
  Map<ResourceType, int> getRepairCost() {
    final baseCosts = baseBuildingCosts[type] ?? {};
    final damageFraction = (maxHealth - currentHealth) / maxHealth;
    
    return baseCosts.map((type, cost) =>
      MapEntry(type, (cost * damageFraction * 0.5).round()) // 50% of proportional base cost
    );
  }

  /// Get building range (for military buildings)
  int get range {
    switch (type) {
      case BuildingType.defensiveTower:
        return 3;
      case BuildingType.cityCenter:
      case BuildingType.barracks:
        return 2;
      default:
        return 1;
    }
  }

  String get name => type.toString().split('.').last;

  String get displayName {
    final rawName = name;
    final result = rawName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return '${result[0].toUpperCase()}${result.substring(1)}';
  }

  String get emoji {
    switch (type) {
      case BuildingType.cityCenter:
        return '🏛️';
      case BuildingType.farm:
        return '🌾';
      case BuildingType.mine:
        return '⛏️';
      case BuildingType.lumberCamp:
        return '🪓';
      case BuildingType.warehouse:
        return '🏭';
      case BuildingType.barracks:
        return '🏰';
      case BuildingType.defensiveTower:
        return '🗼';
      case BuildingType.wall:
        return '🧱';
    }
  }

  /// Factory method to create a building of a specific type
  static Building create(BuildingType type, Position position, {Map<ResourceType, int>? productionValues, required String ownerID}) {
    switch (type) {
      case BuildingType.cityCenter:
        return CityCenter.create(position, ownerID: ownerID);
      case BuildingType.farm:
        return Farm.create(position, productionValues: productionValues, ownerID: ownerID);
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

  /// Checks if a position is within the minimum safe distance from enemy cities
  bool isWithinSafeDistance(Position targetPos, List<Building> enemyBuildings) {
    const int minSafeDistance = 5;
    
    for (final building in enemyBuildings) {
      if (building.type == BuildingType.cityCenter) {
        if (targetPos.manhattanDistance(building.position) < minSafeDistance) {
          return false;
        }
      }
    }
    return true;
  }

  // Base serialization method for buildings
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'position': position.toJson(),
      'level': level,
      'ownerID': ownerID,
    };
  }
  
  // Each subclass will implement its specific fromJson factory

  @override
  List<Object?> get props => [id, type, position, level, maxHealth, currentHealth, ownerID];
}