import 'package:flutter/material.dart';
import 'package:flutter_sim_city/models/map/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile tile;
  final double size;
  final bool isValidMoveTarget; // Neue Eigenschaft hinzugefügt

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
        color: tile.color,
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
            if (tile.icon.isNotEmpty)
              Text(
                tile.icon,
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
}