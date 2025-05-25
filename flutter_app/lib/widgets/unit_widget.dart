import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

class UnitWidget extends StatelessWidget {
  final Unit unit;
  final double size;
  final bool isEnemy; // Kennzeichnet, ob es eine feindliche Einheit ist

  const UnitWidget({
    super.key,
    required this.unit,
    required this.size,
    this.isEnemy = false, // Standardmäßig ist eine Einheit keine feindliche Einheit
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the unit with a tooltip that shows details
    return Tooltip(
      message: _getUnitTooltipText(),
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.transparent,
              // Feindliche Einheiten haben einen roten Rahmen statt einen gelben Auswahlrahmen
              border: isEnemy 
                  ? Border.all(color: Colors.red, width: 2.0)
                  : (unit.isSelected ? Border.all(color: Colors.yellow, width: 3.0) : null),
              borderRadius: BorderRadius.circular(size * 0.5),
            ),
      child: Stack(
        children: [
          // Unit emoji
          Center(
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                color: _getUnitColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  unit.emoji,
                  style: TextStyle(
                    fontSize: size * 0.4,
                  ),
                ),
              ),
            ),
          ),
          
          // Actions indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Text(
                '${unit.actionsLeft}',
                style: TextStyle(
                  color: unit.actionsLeft > 0 ? Colors.white : Colors.red,
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Gesundheitsanzeige für alle Einheiten (nicht nur Kampfeinheiten)
          // Gesundheitsbalken
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: unit.currentHealth / unit.maxHealth,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getHealthColor(unit.currentHealth, unit.maxHealth),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          // Kampfsymbol (nur für Kampfeinheiten)
          if (unit is CombatCapable)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(size * 0.15),
                ),
                child: Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: size * 0.25,
                ),
              ),
            ),
          
          // Numerische Gesundheitsanzeige für alle Einheiten
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Text(
                '${unit.currentHealth}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Display builder capability icon if applicable
          if (unit is BuilderUnit)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(size * 0.15),
                ),
                child: Icon(
                  Icons.build,
                  color: Colors.white,
                  size: size * 0.25,
                ),
              ),
            ),
          
          // Display harvester capability icon if applicable
          if (unit is HarvesterUnit)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(size * 0.15),
                ),
                child: Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: size * 0.25,
                ),
              ),
            ),
        ],
      ),
    )
    ],
      ),
    );
  }

  Color _getHealthColor(int current, int max) {
    final percentage = current / max;
    if (percentage > 0.7) {
      return Colors.green;
    } else if (percentage > 0.3) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  String _getUnitTooltipText() {
    String tooltip = '${unit.type.toString().split('.').last.toUpperCase()}\n';
    tooltip += '${isEnemy ? "⚔️ ENEMY UNIT" : "👑 YOUR UNIT"}\n';
    tooltip += '❤️ Health: ${unit.currentHealth}/${unit.maxHealth}\n';
    tooltip += '🏃 Actions: ${unit.actionsLeft}/${unit.maxActions}\n';
    
    // Add combat values if applicable
    if (unit is CombatCapable) {
      final combatUnit = unit as CombatCapable;
      tooltip += '⚔️ Attack: ${combatUnit.attackValue}\n';
      tooltip += '🛡️ Defense: ${combatUnit.defenseValue}\n';
    }
    
    // Add additional abilities info
    List<String> abilities = [];
    if (unit is BuilderUnit) abilities.add('Builder');
    if (unit is HarvesterUnit) abilities.add('Harvester');
    if (unit is SettlerCapable) abilities.add('Settler');
    if (unit is CombatCapable) abilities.add('Combat');
    
    if (abilities.isNotEmpty) {
      tooltip += '⭐ Abilities: ${abilities.join(', ')}';
    }
    
    return tooltip;
  }
  
  Color _getUnitColor() {
    // Feindliche Einheiten haben dunklere, intensivere Farben
    if (isEnemy) {
      switch (unit.type) {
        case UnitType.settler:
          return Colors.purple.withOpacity(0.9);
        case UnitType.farmer:
          return Colors.green.withOpacity(0.9);
        case UnitType.lumberjack:
          return Colors.orange.withOpacity(0.9);
        case UnitType.miner:
          return Colors.blue.withOpacity(0.9);
        case UnitType.commander:
          return Colors.red.withOpacity(0.9);
        case UnitType.knight:
          return Colors.indigo.withOpacity(0.9);
        case UnitType.soldierTroop:
          return Colors.brown.withOpacity(0.9);
        case UnitType.archer:
          return Colors.teal.withOpacity(0.9);
        case UnitType.architect:
          return Colors.grey.withOpacity(0.9);
        case UnitType.virtualTower:
          return Colors.cyan.withOpacity(0.9);
      }
    } else {
    switch (unit.type) {
      case UnitType.settler:
        return Colors.purple.withOpacity(0.7);
      case UnitType.farmer:
        return Colors.green.withOpacity(0.7);
      case UnitType.lumberjack:
        return Colors.orange.withOpacity(0.7);
      case UnitType.miner:
        return Colors.blue.withOpacity(0.7);
      case UnitType.commander:
        return Colors.red.withOpacity(0.7);
      case UnitType.knight:
        return Colors.indigo.withOpacity(0.7);
      case UnitType.soldierTroop:
        return Colors.brown.withOpacity(0.7);
      case UnitType.archer:
        return Colors.teal.withOpacity(0.7);
      case UnitType.architect:
        return Colors.grey.withOpacity(0.7);
      case UnitType.virtualTower:
        return Colors.cyan.withOpacity(0.7);
    }
    }
  }
}