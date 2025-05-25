import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

class BuildingWidget extends StatelessWidget {
  final Building building;
  final bool isSelected;
  final double size;
  final bool isEnemy; // Kennzeichnet, ob es ein feindliches Gebäude ist

  const BuildingWidget({
    super.key,
    required this.building,
    required this.isSelected,
    required this.size,
    this.isEnemy = false, // Standardmäßig ist ein Gebäude kein feindliches Gebäude
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: isEnemy
            ? Border.all(color: Colors.red, width: 2.0) // Feindliche Gebäude haben einen roten Rand
            : (isSelected ? Border.all(color: Colors.yellow, width: 3.0) : null),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                color: _getBuildingColor(),
                borderRadius: BorderRadius.circular(size * 0.15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      building.emoji,
                      style: TextStyle(
                        fontSize: size * 0.4,
                      ),
                    ),
                    Text(
                      'Lvl ${building.level}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
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
            ),
          ),
        ],
      ),
    );
  }

  Color _getBuildingColor() {
    Color baseColor;
    
    switch (building.type) {
      case BuildingType.cityCenter:
        baseColor = const Color(0xFF5D4037);
      case BuildingType.farm:
        baseColor = const Color(0xFF8BC34A);
      case BuildingType.mine:
        baseColor = const Color(0xFF607D8B);
      case BuildingType.lumberCamp:
        baseColor = const Color(0xFF795548);
      case BuildingType.warehouse:
        baseColor = const Color(0xFF9E9E9E);
      case BuildingType.barracks:
        baseColor = const Color(0xFFBDB76B); // gold-ish for barracks
      case BuildingType.defensiveTower:
        baseColor = const Color(0xFF4A148C); // deep purple for defensive tower
      case BuildingType.wall:
        baseColor = const Color(0xFF424242); // dark grey for wall
    }
    
    // Make enemy buildings darker to distinguish them
    if (isEnemy) {
      return HSLColor.fromColor(baseColor)
          .withLightness((HSLColor.fromColor(baseColor).lightness - 0.2).clamp(0.0, 1.0))
          .withSaturation((HSLColor.fromColor(baseColor).saturation - 0.1).clamp(0.0, 1.0))
          .toColor();
    }
    
    return baseColor;
  }
}