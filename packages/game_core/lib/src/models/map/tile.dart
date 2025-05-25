import 'package:equatable/equatable.dart';
import 'position.dart';
import '../resource/resource.dart';

enum TileType {
  grass,
  water,
  mountain,
  forest,
}

class Tile extends Equatable {
  final Position position;
  final TileType type;
  final ResourceType? resourceType;
  final int resourceAmount;
  final bool hasBuilding;
  final bool isSelected;

  const Tile({
    required this.position,
    required this.type,
    this.resourceType,
    this.resourceAmount = 0,
    this.hasBuilding = false,
    this.isSelected = false,
  });

  Tile copyWith({
    Position? position,
    TileType? type,
    ResourceType? resourceType,
    int? resourceAmount,
    bool? hasBuilding,
    bool? isSelected,
  }) {
    return Tile(
      position: position ?? this.position,
      type: type ?? this.type,
      resourceType: resourceType ?? this.resourceType,
      resourceAmount: resourceAmount ?? this.resourceAmount,
      hasBuilding: hasBuilding ?? this.hasBuilding,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  bool get isWalkable => type != TileType.water && (type != TileType.mountain || resourceType == ResourceType.iron);
  
  bool get canBuildOn => 
      type == TileType.grass && 
      !hasBuilding && 
      resourceType == null;
      
  // Special checks for specific building types
  bool canBuildFarm() => 
      type == TileType.grass && 
      !hasBuilding;
      
  bool canBuildLumberCamp() => 
      type == TileType.forest && 
      !hasBuilding;
      
  bool canBuildMine() => 
      (resourceType == ResourceType.stone || resourceType == ResourceType.iron) && 
      !hasBuilding;

  // Hinweis: Alle UI- und Theme-bezogenen Methoden/Properties müssen ins Frontend verschoben werden!
  /* Color get color {
    switch (type) {
      case TileType.grass:
        return AppTheme.grassColor;
      case TileType.water:
        return AppTheme.waterColor;
      case TileType.mountain:
        return AppTheme.mountainColor;
      case TileType.forest:
        return const Color(0xFF2E7D32);
    }
  }

  String get icon {
    if (resourceType != null) {
      return Resource.resourceIcons[resourceType] ?? '';
    }
    
    switch (type) {
      case TileType.grass:
        return '';
      case TileType.water:
        return '💧';
      case TileType.mountain:
        return '⛰️';
      case TileType.forest:
        return '🌲';
    }
  } */

  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'position': position.toJson(),
      'type': type.toString().split('.').last,
      'resourceType': resourceType?.toString().split('.').last,
      'resourceAmount': resourceAmount,
      'hasBuilding': hasBuilding,
      'isSelected': isSelected,
    };
  }
  
  factory Tile.fromJson(Map<String, dynamic> json) {
    // Parse resource type if provided
    ResourceType? resourceType;
    if (json['resourceType'] != null) {
      final resourceTypeString = json['resourceType'] as String;
      for (final type in ResourceType.values) {
        if (type.toString().split('.').last == resourceTypeString) {
          resourceType = type;
          break;
        }
      }
    }
    
    return Tile(
      position: Position.fromJson(json['position']),
      type: TileType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
      ),
      resourceType: resourceType,
      resourceAmount: json['resourceAmount'],
      hasBuilding: json['hasBuilding'],
      isSelected: json['isSelected'],
    );
  }

  @override
  List<Object?> get props => [
    position, 
    type, 
    resourceType, 
    resourceAmount, 
    hasBuilding,
    isSelected,
  ];
}