import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;
  final bool isValidMoveTarget;

  const TileWidget({
    super.key,
    required this.tile,
    required this.size,
    this.isValidMoveTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Get color based on the tile type
        color: _getTileColor(tile.type),
        border: Border.all(
          color: tile.isSelected 
              ? Colors.yellow 
              : isValidMoveTarget
                  ? Colors.green  // Grüne Umrandung für gültige Bewegungsziele
                  : Colors.black,
          width: tile.isSelected 
              ? 3.0 
              : isValidMoveTarget ? 2.0 : 1.0,  // Dickere Umrandung für gültige Bewegungsziele
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display appropriate icon based on tile type and resources
            Text(
              _getTileIcon(),
              style: TextStyle(
                fontSize: size * 0.4,
              ),
            ),
            if (tile.resourceAmount > 0)
              Text(
                '${tile.resourceAmount}',
                style: TextStyle(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to determine the tile's icon based on type and resources
  String _getTileIcon() {
    // First check if there's a resource on this tile
    if (tile.resourceType != null) {
      switch (tile.resourceType) {
        case ResourceType.wood:
          return '🌳';
        case ResourceType.stone:
          return '🪨';
        case ResourceType.iron:
          return '⛏️';
        case ResourceType.food:
          return '🌾';
        default:
          break;
      }
    }
    
    // If no resource or resource doesn't have a specific icon, use tile type
    switch (tile.type) {
      case TileType.grass:
        return '🟩'; // Green square or could be empty
      case TileType.forest:
        return '🌲';
      case TileType.water:
        return '🌊';
      case TileType.mountain:
        return '⛰️';
      default:
        return '';  // Default: no icon
    }
  }
  
  // Helper method to determine the tile's color based on its type
  Color _getTileColor(TileType type) {
    switch (type) {
      case TileType.grass:
        return Colors.green[300]!;
      case TileType.forest:
        return Colors.green[800]!;
      case TileType.water:
        return Colors.blue[400]!;
      case TileType.mountain:
        return Colors.grey[600]!;
      default:
        return Colors.white;
    }
  }
}