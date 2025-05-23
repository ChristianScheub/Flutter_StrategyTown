import 'dart:math';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';
import 'package:flutter_sim_city/models/map/tile.dart';

class TileMap {
  final Map<String, Tile> _tiles = {};
  final Random _random = Random();
  
  // Cache for performance
  int _minX = 0;
  int _maxX = 0;
  int _minY = 0;
  int _maxY = 0;

  TileMap() {
    // Generate just the initial area needed for the start
    generateArea(-10, -10, 10, 10);
  }

  String _tileKey(Position position) => '${position.x},${position.y}';

  /// Checks if a position is valid in the current map context
  bool isValidPosition(Position position) {
    const maxSize = 1000;
    if (position.x.abs() > maxSize || position.y.abs() > maxSize) {
      return false;
    }
    return true;
  }

  Tile getTile(Position position) {
    final key = _tileKey(position);
    if (!_tiles.containsKey(key)) {
      // Generate a new tile
      _tiles[key] = _generateTile(position);
      
      // Update bounds
      _minX = min(_minX, position.x);
      _maxX = max(_maxX, position.x);
      _minY = min(_minY, position.y);
      _maxY = max(_maxY, position.y);
    }
    return _tiles[key]!;
  }

  void setTile(Tile tile) {
    _tiles[_tileKey(tile.position)] = tile;
  }

  void generateArea(int minX, int minY, int maxX, int maxY) {
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final position = Position(x: x, y: y);
        getTile(position);
      }
    }
  }

  Tile _generateTile(Position position) {
    // Enhanced procedural generation
    final perlin = _simplifiedNoise(position.x, position.y);
    
    TileType type;
    ResourceType? resourceType;
    int resourceAmount = 0;
    
    // Generate feature seeds based on position chunks
    // This ensures features appear in specific areas of the map consistently
    final chunkX = (position.x / 15).floor();
    final chunkY = (position.y / 15).floor();
    
    // Use chunk as seed for random features
    final chunkSeed = chunkX * 1000 + chunkY;
    final featureRandom = Random(chunkSeed);
    
    // Create water bodies (lakes)
    if (featureRandom.nextInt(100) < 15) {  // 15% chance for a lake
      final lakeX = chunkX * 15 + featureRandom.nextInt(15);
      final lakeY = chunkY * 15 + featureRandom.nextInt(15);
      final lakeSize = featureRandom.nextInt(5) + 3;  // 3-7 tiles wide
      
      // Lakes are circular
      if (_isPartOfFeature(position.x, position.y, lakeX, lakeY, lakeSize)) {
        return Tile(
          position: position,
          type: TileType.water,
        );
      }
    }
    
    // Create rivers (more linear water features)
    final riverSeed = position.x * position.y % 100;
    if (riverSeed < 3) { // 3% chance for a river
      // Either horizontal or vertical river
      if (position.x % 50 == 0 || position.y % 40 == 0) {
        // Add some meandering by checking nearby positions
        final riverWiggle = _random.nextInt(3) - 1;
        if (position.x % 50 == 0 && (position.y + riverWiggle) % 3 == 0) {
          return Tile(
            position: position,
            type: TileType.water,
          );
        }
        if (position.y % 40 == 0 && (position.x + riverWiggle) % 3 == 0) {
          return Tile(
            position: position,
            type: TileType.water,
          );
        }
      }
    }
    
    // Create mountain ranges
    if (featureRandom.nextInt(100) < 10) {  // 10% chance for a mountain range
      final mountainX = chunkX * 15 + featureRandom.nextInt(15);
      final mountainY = chunkY * 15 + featureRandom.nextInt(15);
      final rangeSize = featureRandom.nextInt(4) + 2;  // 2-5 tiles wide
      
      if (_isPartOfFeature(position.x, position.y, mountainX, mountainY, rangeSize)) {
        // Mountain range with potential resources
        if (featureRandom.nextDouble() < 0.4) {
          resourceType = ResourceType.iron;
          resourceAmount = _random.nextInt(30) + 20;
        }
        return Tile(
          position: position,
          type: TileType.mountain,
          resourceType: resourceType,
          resourceAmount: resourceAmount,
        );
      }
    }
    
    // Create forest clusters
    if (featureRandom.nextInt(100) < 25) {  // 25% chance for a forest cluster
      final forestX = chunkX * 15 + featureRandom.nextInt(15);
      final forestY = chunkY * 15 + featureRandom.nextInt(15);
      final forestSize = featureRandom.nextInt(6) + 4;  // 4-9 tiles wide
      
      if (_isPartOfFeature(position.x, position.y, forestX, forestY, forestSize)) {
        // Dense forest with potential wood resources
        if (featureRandom.nextDouble() < 0.7) {
          resourceType = ResourceType.wood;
          resourceAmount = _random.nextInt(40) + 10;
        }
        return Tile(
          position: position,
          type: TileType.forest,
          resourceType: resourceType,
          resourceAmount: resourceAmount,
        );
      }
    }
    
    // Base terrain using perlin noise
    if (perlin < 0.25) {
      type = TileType.water;
    } else if (perlin > 0.85) {
      type = TileType.mountain;
      
      // Mountains have a chance of iron
      if (_random.nextDouble() < 0.3) {
        resourceType = ResourceType.iron;
        resourceAmount = _random.nextInt(30) + 20;
      }
    } else if (perlin > 0.65 && perlin <= 0.85) {
      type = TileType.forest;
      
      // Forests have wood resources
      if (_random.nextDouble() < 0.7) {
        resourceType = ResourceType.wood;
        resourceAmount = _random.nextInt(40) + 10;
      }
    } else {
      type = TileType.grass;
      
      // Grass has a chance of food or stone
      if (_random.nextDouble() < 0.15) {
        // Slightly higher chance for stone to ensure mines can be built
        resourceType = _random.nextDouble() > 0.4
            ? ResourceType.stone 
            : ResourceType.food;
        resourceAmount = _random.nextInt(20) + 10;
      }
    }
    
    return Tile(
      position: position,
      type: type,
      resourceType: resourceType,
      resourceAmount: resourceAmount,
    );
  }

  // Determine if the position is part of a feature based on a seed point
  bool _isPartOfFeature(int x, int y, int seedX, int seedY, int size) {
    final distance = sqrt(pow(x - seedX, 2) + pow(y - seedY, 2));
    return distance <= size;
  }
  
  double _simplifiedNoise(int x, int y) {
    // More varied noise function combining multiple frequencies
    double value = sin(x * 0.1) * cos(y * 0.1);  // Base frequency
    value += sin(x * 0.05) * cos(y * 0.05) * 0.5;  // Lower frequency
    value += sin(x * 0.2) * cos(y * 0.2) * 0.25;   // Higher frequency
    
    // Add some randomness based on position
    final hash = (x * 13 + y * 7) % 100;
    value += _random.nextDouble() * 0.2 * (hash / 100);
    
    return (value + 1.2) / 2.4;  // Normalize to 0-1 range
  }

  List<Tile> getVisibleTiles(Position center, int radius) {
    final List<Tile> visibleTiles = [];
    for (int y = center.y - radius; y <= center.y + radius; y++) {
      for (int x = center.x - radius; x <= center.x + radius; x++) {
        visibleTiles.add(getTile(Position(x: x, y: y)));
      }
    }
    return visibleTiles;
  }

  List<Tile> getAllTiles() {
    return _tiles.values.toList();
  }

  int get minX => _minX;
  int get maxX => _maxX;
  int get minY => _minY;
  int get maxY => _maxY;

  // This method is called when the camera moves to load new areas
  void ensureAreaExists(int minX, int minY, int maxX, int maxY) {
    // Expand the area slightly to preload
    const buffer = 5;
    
    // Check if we need to generate new areas
    if (minX < _minX || maxX > _maxX || minY < _minY || maxY > _maxY) {
      // Expand the area to be generated
      minX = minX - buffer < _minX ? minX - buffer : _minX;
      maxX = maxX + buffer > _maxX ? maxX + buffer : _maxX;
      minY = minY - buffer < _minY ? minY - buffer : _minY;
      maxY = maxY + buffer > _maxY ? maxY + buffer : _maxY;
      
      // Generate the expanded area
      generateArea(minX, minY, maxX, maxY);
    }
  }

  // Serialization methods
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> tilesJson = {};
    _tiles.forEach((key, tile) {
      tilesJson[key] = tile.toJson();
    });
    
    return {
      'tiles': tilesJson,
      'minX': _minX,
      'maxX': _maxX,
      'minY': _minY,
      'maxY': _maxY,
    };
  }
  
  factory TileMap.fromJson(Map<String, dynamic> json) {
    final map = TileMap();
    
    // Clear default generated tiles
    map._tiles.clear();
    
    // Restore bounds
    map._minX = json['minX'];
    map._maxX = json['maxX'];
    map._minY = json['minY'];
    map._maxY = json['maxY'];
    
    // Restore tiles
    final tilesJson = json['tiles'] as Map<String, dynamic>;
    tilesJson.forEach((key, tileJson) {
      map._tiles[key] = Tile.fromJson(tileJson);
    });
    
    return map;
  }
}