import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

class ActionPanel extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onFoundCity;
  final Function(BuildingType) onBuildingSelect;
  final Function(UnitType) onUnitSelect;
  final Function(Position) onBuild;
  final Function(UnitType) onTrain;
  final VoidCallback onHarvest;
  final VoidCallback onClearSelection;
  final VoidCallback onBuildFarm;
  final VoidCallback onBuildLumberCamp;
  final VoidCallback onBuildMine;
  final VoidCallback onBuildBarracks;
  final VoidCallback onBuildDefensiveTower;  // New callback
  final VoidCallback onBuildWall;            // New callback
  final VoidCallback onUpgradeBuilding;
  final VoidCallback onJumpToFirstSettler;   // New callback for settler navigation

  const ActionPanel({
    super.key,
    required this.gameState,
    required this.onFoundCity,
    required this.onBuildingSelect,
    required this.onUnitSelect,
    required this.onBuild,
    required this.onTrain,
    required this.onHarvest,
    required this.onClearSelection,
    required this.onBuildFarm,
    required this.onBuildLumberCamp,
    required this.onBuildMine,
    required this.onBuildBarracks,
    required this.onBuildDefensiveTower,  // New callback
    required this.onBuildWall,            // New callback  
    required this.onUpgradeBuilding,
    required this.onJumpToFirstSettler,   // New callback for settler navigation
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getActionPanelTitle(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (gameState.selectedUnitId != null ||
                  gameState.selectedBuildingId != null ||
                  gameState.selectedTilePosition != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClearSelection,
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildActionContent(context),
        ],
      ),
    );
  }

  String _getActionPanelTitle() {
    if (gameState.selectedUnitId != null) {
      final unit = gameState.selectedUnit!;
      return 'Selected: ${unit.displayName} (Actions: ${unit.actionsLeft}/${unit.maxActions})';
    } else if (gameState.selectedBuildingId != null) {
      final building = gameState.selectedBuilding!;
      return 'Selected: ${building.displayName} (Level ${building.level})';
    } else if (gameState.selectedTilePosition != null) {
      final tile = gameState.selectedTile!;
      return 'Selected Tile: (${tile.position.x}, ${tile.position.y})';
    } else if (gameState.buildingToBuild != null) {
      switch (gameState.buildingToBuild!) {
        case BuildingType.cityCenter:
          return 'Building: City Center';
        case BuildingType.farm:
          return 'Building: Farm';
        case BuildingType.mine:
          return 'Building: Mine';
        case BuildingType.lumberCamp:
          return 'Building: Lumber Camp';
        case BuildingType.warehouse:
          return 'Building: Warehouse';
        case BuildingType.barracks:
          return 'Building: Barracks';
        case BuildingType.defensiveTower:
          return 'Building: Defensive Tower';
        case BuildingType.wall:
          return 'Building: Wall';
      }
    } else {
      return 'Actions';
    }
  }

  Widget _buildActionContent(BuildContext context) {
    if (gameState.selectedUnitId != null) {
      return _buildUnitActions(context);
    } else if (gameState.selectedBuildingId != null) {
      return _buildBuildingActions(context);
    } else if (gameState.selectedTilePosition != null) {
      return _buildTileActions(context);
    } else if (gameState.buildingToBuild != null) {
      return _buildBuildingPlacementInfo(context);
    } else {
      return _buildGeneralActions(context);
    }
  }

  Widget _buildUnitActions(BuildContext context) {
    final unit = gameState.selectedUnit!;
    final actions = <Widget>[];

    // Display combat stats if the unit is a combat unit
    if (unit.isCombatUnit) {
      actions.add(
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Combat Stats', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text('HP: ${unit.currentHealth}/${unit.maxHealth}'),
                    const SizedBox(width: 12),
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text('ATK: ${unit.attackValue}'),
                    const SizedBox(width: 12),
                    Icon(Icons.shield, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text('DEF: ${unit.defenseValue}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Settler action - found city
    if (unit is SettlerCapable) {
      final settlerUnit = unit as SettlerCapable;
      if (settlerUnit.canFoundCity()) {
        actions.add(
          ElevatedButton.icon(
            onPressed: onFoundCity,
            icon: const Text('🏛️'),
            label: const Text('Found City (kostenlos)'),
          ),
        );
      }
    }
    
    // Farmer action - build farm on grass
    if (unit is BuilderUnit && unit.type == UnitType.farmer) {
      final builderUnit = unit as BuilderUnit;
      // Check if the tile under the unit is suitable for a farm
      final farmTile = gameState.map.getTile(unit.position);
      if (builderUnit.canBuild(BuildingType.farm, farmTile)) {
        final farmCost = baseBuildingCosts[BuildingType.farm] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(farmCost);
        
        // Build cost display in a consistent format
        final costText = farmCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildFarm : null,
            icon: const Text('🌾'),
            label: Text('Build Farm\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }
    }
    
    // Lumberjack action - build lumber camp in forests
    if (unit is BuilderUnit && unit.type == UnitType.lumberjack) {
      final builderUnit = unit as BuilderUnit;
      // Check if the tile under the unit is suitable for a lumber camp
      final lumberTile = gameState.map.getTile(unit.position);
      if (builderUnit.canBuild(BuildingType.lumberCamp, lumberTile)) {
        final lumberCampCost = baseBuildingCosts[BuildingType.lumberCamp] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(lumberCampCost);
        
        // Build cost display in a consistent format
        final costText = lumberCampCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildLumberCamp : null,
            icon: const Text('🪓'),
            label: Text('Build Lumber Camp\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }
    }
    
    // Miner action - build mine on stone/iron resources
    if (unit is BuilderUnit && unit.type == UnitType.miner) {
      final builderUnit = unit as BuilderUnit;
      // Check if the tile under the unit is suitable for a mine
      final mineTile = gameState.map.getTile(unit.position);
      if (builderUnit.canBuild(BuildingType.mine, mineTile)) {
        final mineCost = baseBuildingCosts[BuildingType.mine] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(mineCost);
        
        // Build cost display in a consistent format
        final costText = mineCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildMine : null,
            icon: const Text('⛏️'),
            label: Text('Build Mine\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }
    }
    
    // Commander action - build barracks
    if (unit is BuilderUnit && unit.type == UnitType.commander) {
      final builderUnit = unit as BuilderUnit;
      // Check if the tile under the unit is suitable for barracks
      final tile = gameState.map.getTile(unit.position);
      if (builderUnit.canBuild(BuildingType.barracks, tile)) {
        final barracksCost = baseBuildingCosts[BuildingType.barracks] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(barracksCost);
        
        // Build cost display in a consistent format
        final costText = barracksCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildBarracks : null,
            icon: const Text('🏰'),
            label: Text('Build Barracks\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }
    }

    // Architect action - build defensive structures
    if (unit is BuilderUnit && unit.type == UnitType.architect) {
      final builderUnit = unit as BuilderUnit;
      final tile = gameState.map.getTile(unit.position);

      // Defensive Tower
      if (builderUnit.canBuild(BuildingType.defensiveTower, tile)) {
        final towerCost = baseBuildingCosts[BuildingType.defensiveTower] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(towerCost);
        
        final costText = towerCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildDefensiveTower : null,
            icon: const Text('🗼'),
            label: Text('Build Tower\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }

      // Wall
      if (builderUnit.canBuild(BuildingType.wall, tile)) {
        final wallCost = baseBuildingCosts[BuildingType.wall] ?? {};
        final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(wallCost);
        
        final costText = wallCost.entries.map((e) => 
          '${e.value} ${_getResourceEmoji(e.key)}'
        ).join(' ');
        
        actions.add(
          ElevatedButton.icon(
            onPressed: hasEnoughResources ? onBuildWall : null,
            icon: const Text('🧱'),
            label: Text('Build Wall\n($costText)', textAlign: TextAlign.center),
          ),
        );
      }
    }

    // Resource harvesting (only available for HarvesterUnit)
    final tile = gameState.map.getTile(unit.position);
    if (tile.resourceType != null && 
        tile.resourceAmount > 0 && 
        unit.canAct &&
        unit is HarvesterUnit) {
      final harvesterUnit = unit as HarvesterUnit;
      final resourceType = tile.resourceType!;
      
      // Check if the unit can harvest this resource type
      if (harvesterUnit.canHarvest(resourceType, tile)) {
        final resourceEmoji = _getResourceEmoji(resourceType);
        final harvestAmount = harvesterUnit.getHarvestAmount(resourceType);
        
        actions.add(
          ElevatedButton.icon(
            onPressed: onHarvest,
            icon: const Text('🧰'),
            label: Text('Harvest ${_getResourceName(resourceType)} $resourceEmoji (${harvestAmount} units)'),
          ),
        );
      }
    }

    if (actions.isEmpty) {
      actions.add(
        const Text('No actions available for this unit'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions,
    );
  }

  Widget _buildBuildingActions(BuildContext context) {
    final building = gameState.selectedBuilding!;
    
    if (building.type == BuildingType.cityCenter) {
      final cityCenter = building as CityCenter;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building level and upgrade option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'City Center Level: ${building.level}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _buildUpgradeButton(context, building),
            ],
          ),
          const SizedBox(height: 12),
          _buildBuildingProductionInfo(context, building),
          const SizedBox(height: 12),
          Text(
            'Train Civilian Units:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              UnitType.settler,
              UnitType.farmer,
              UnitType.lumberjack,
              UnitType.miner,
              UnitType.commander,
              UnitType.architect,
            ].map((unitType) {
              // Get the cost for this unit type
              final unitCost = cityCenter.getUnitCost(unitType);
              final hasEnoughFood = gameState.getPlayerResources(gameState.currentPlayerId).hasEnough(ResourceType.food, unitCost);
              
              return ElevatedButton.icon(
                onPressed: hasEnoughFood ? () => onTrain(unitType) : null,
                icon: Text(_getUnitEmoji(unitType)),
                label: Text(
                  '${_getUnitName(unitType)}\n($unitCost 🌾)',
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else if (building.type == BuildingType.barracks) {
      final barracks = building as Barracks;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building level and upgrade option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Barracks Level: ${building.level}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _buildUpgradeButton(context, building),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Train Military Units:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: barracks.trainableUnits.map((unitType) {
              // Get costs
              final costs = barracks.getUnitCosts(unitType);
              final foodCost = costs[ResourceType.food] ?? 0;
              final ironCost = costs[ResourceType.iron] ?? 0;
              
              // Check if player has enough resources
              final playerResources = gameState.getPlayerResources(gameState.currentPlayerId);
              final hasEnoughFood = playerResources.hasEnough(ResourceType.food, foodCost);
              final hasEnoughIron = playerResources.hasEnough(ResourceType.iron, ironCost);
              final hasResources = hasEnoughFood && hasEnoughIron;
              
              return ElevatedButton.icon(
                onPressed: hasResources ? () => onTrain(unitType) : null,
                icon: Text(_getUnitEmoji(unitType)),
                label: Text(
                  '${_getUnitName(unitType)}\n(${foodCost} 🌾, ${ironCost} ⛏️)',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      );
    } else {
      // Für andere Gebäude nur den Level und die Produktionsdaten anzeigen
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Building Level: ${building.level}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _buildUpgradeButton(context, building),
            ],
          ),
          const SizedBox(height: 12),
          _buildBuildingProductionInfo(context, building),
        ],
      );
    }
  }

  Widget _buildTileActions(BuildContext context) {
    final tile = gameState.selectedTile!;
    final position = gameState.selectedTilePosition!;
    
    // Check if there's an enemy unit at this position
    final enemyUnit = _getEnemyUnitAt(position);
    if (enemyUnit != null) {
      // Show enemy unit details along with owner information
      final owner = gameState.playerManager.getPlayer(enemyUnit.ownerID)?.name ?? 'Unknown';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnemyUnitDetails(enemyUnit),
          Text(
            'Owner: $owner',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    
    if (tile.resourceType != null && tile.resourceAmount > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource: ${_getResourceName(tile.resourceType!)}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            'Amount: ${tile.resourceAmount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a unit and move it here to harvest',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      );
    } else if (tile.canBuildOn) {
      // Zeige nur eine Informationsmeldung an, keine Gebäudeoptionen
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Buildable Terrain',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Move a specialist unit here to build:',
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Text(
        'Terrain: ${tile.type.toString().split('.').last}',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
  }

  Widget _buildBuildingPlacementInfo(BuildContext context) {
    final buildingType = gameState.buildingToBuild!;
    final costs = baseBuildingCosts[buildingType] ?? {};
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Select a tile to build a ${_getBuildingName(buildingType)}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Cost:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: costs.entries.map((entry) {
            final hasResource = gameState.getPlayerResources(gameState.currentPlayerId).hasEnough(entry.key, entry.value);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasResource
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasResource
                      ? Colors.green.withOpacity(0.6)
                      : Colors.red.withOpacity(0.6),
                ),
              ),
              child: Text(
                '${_getResourceEmoji(entry.key)} ${entry.value}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (gameState.selectedTilePosition != null)
          ElevatedButton.icon(
            onPressed: gameState.selectedTile!.canBuildOn 
                ? () => onBuild(gameState.selectedTilePosition!)
                : null,
            icon: Text(_getBuildingEmoji(buildingType)),
            label: const Text('Build Here'),
          ),
      ],
    );
  }

  Widget _buildGeneralActions(BuildContext context) {
    final currentPlayerId = gameState.currentPlayerId;
    final hasNoCities = !_playerHasCities(currentPlayerId);
    final hasSettlers = _playerHasSettlers(currentPlayerId);
    
    // Show "Jump to Settler" button if player has settlers but no cities
    if (hasNoCities && hasSettlers) {
      return Column(
        children: [
          ElevatedButton.icon(
            onPressed: onJumpToFirstSettler,
            icon: const Text('🧭'),
            label: const Text('Jump to Settler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have no cities. Use your settler to found a city!',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      );
    }
    
    // Default message when nothing is selected
    return const Text(
      'Select a unit, building, or tile to perform actions.',
      textAlign: TextAlign.center,
    );
  }

  bool _playerHasCities(String playerId) {
    return gameState.buildings.any(
      (building) => building.type == BuildingType.cityCenter && building.ownerID == playerId
    );
  }

  bool _playerHasSettlers(String playerId) {
    return gameState.units.any(
      (unit) => unit.ownerID == playerId && unit is SettlerCapable
    );
  }

  // Erstellt einen Upgrade-Button mit den notwendigen Kosteninformationen
  Widget _buildUpgradeButton(BuildContext context, Building building) {
    // Upgrade-Kosten berechnen
    final upgradeCost = building.getUpgradeCost();
    
    // Prüfen, ob genügend Ressourcen vorhanden sind
    final hasEnoughResources = gameState.getPlayerResources(gameState.currentPlayerId).hasEnoughMultiple(upgradeCost);
    
    // Zeige Upgrade-Kosten als Text
    final costText = upgradeCost.entries.map((e) => 
      '${e.value} ${_getResourceEmoji(e.key)}'
    ).join(' ');
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasEnoughResources 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasEnoughResources
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.error.withOpacity(0.1),
        ),
        onPressed: hasEnoughResources ? onUpgradeBuilding : null,
        icon: const Text('⬆️'),
        label: Text(
          'Upgrade to Level ${building.level + 1}\n($costText)',
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  // Zeigt Produktionsinformationen für verschiedene Gebäudetypen an
  Widget _buildBuildingProductionInfo(BuildContext context, Building building) {
    // Je nach Gebäudetyp unterschiedliche Informationen anzeigen
    if (building is CityCenter) {
      final cityCenter = building;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next upgrade: -10% training costs',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is Farm) {
      final nextFoodProduction = (building.foodPerTurn * 1.4).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('${_getResourceEmoji(ResourceType.food)} Food: '),
              Text('${building.foodPerTurn} / turn', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Next upgrade: +40% production (${nextFoodProduction} / turn)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is Mine) {
      final nextStoneProduction = (building.stonePerTurn * 1.4).round();
      final nextIronProduction = (building.ironPerTurn * 1.4).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('${_getResourceEmoji(ResourceType.stone)} Stone: '),
              Text('${building.stonePerTurn} / turn', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              Text('${_getResourceEmoji(ResourceType.iron)} Iron: '),
              Text('${building.ironPerTurn} / turn', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Next upgrade: +40% production',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '• Stone: ${nextStoneProduction} / turn',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '• Iron: ${nextIronProduction} / turn',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is LumberCamp) {
      final nextWoodProduction = (building.woodPerTurn * 1.4).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Production:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('${_getResourceEmoji(ResourceType.wood)} Wood: '),
              Text('${building.woodPerTurn} / turn', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Next upgrade: +40% production (${nextWoodProduction} / turn)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is Warehouse) {
      final warehouse = building;
      final baseStorage = warehouse.baseStorage;
      final nextStorageValue = (baseStorage * 1.4).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Capacity:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('+$baseStorage Storage capacity', 
            style: const TextStyle(fontWeight: FontWeight.w500)),
          const Divider(height: 16),
          Text(
            'Next upgrade: +40% capacity (+$nextStorageValue)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is DefensiveTower) {
      final defensiveTower = building;
      final nextAttackValue = (defensiveTower.attackValue * 1.2).round();
      final nextHealth = (building.maxHealth * 1.3).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Combat Stats:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text('⚔️ Attack: '),
              Text('${defensiveTower.attackValue}', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              const Text('❤️ Health: '),
              Text('${building.currentHealth}/${building.maxHealth}', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Row(
            children: [
              const Text('🎯 Range: '),
              Text('${defensiveTower.attackRange}', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Next upgrade:',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '• Attack: $nextAttackValue (+20%)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            '• Health: $nextHealth (+30%)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else if (building is Wall) {
      final nextHealth = (building.maxHealth * 1.4).round();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Defense Stats:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text('❤️ Health: '),
              Text('${building.currentHealth}/${building.maxHealth}', 
                style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 16),
          Text(
            'Next upgrade: +40% health ($nextHealth)',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      );
    } else {
      return const Text('Building has no resource production.');
    }
  }

  String _getResourceName(ResourceType type) {
    switch (type) {
      case ResourceType.wood:
        return 'Wood';
      case ResourceType.stone:
        return 'Stone';
      case ResourceType.iron:
        return 'Iron';
      case ResourceType.food:
        return 'Food';
    }
  }

  String _getResourceEmoji(ResourceType type) {
    return Resource.resourceIcons[type] ?? '';
  }

  String _getUnitName(UnitType type) {
    switch (type) {
      case UnitType.settler:
        return 'Settler';
      case UnitType.farmer:
        return 'Farmer';
      case UnitType.lumberjack:
        return 'Lumberjack';
      case UnitType.miner:
        return 'Miner';
      case UnitType.commander:
        return 'Commander';
      case UnitType.knight:
        return 'Knight';
      case UnitType.soldierTroop:
        return 'Soldier Troop';
      case UnitType.archer:
        return 'Archer';
      case UnitType.architect:
        return 'Architect';
      case UnitType.virtualTower:
        return 'Virtual Tower';
    }
  }

  String _getUnitEmoji(UnitType type) {
    switch (type) {
      case UnitType.settler:
        return '👨‍🌾';
      case UnitType.farmer:
        return '🌾';
      case UnitType.lumberjack:
        return '🪓';
      case UnitType.miner:
        return '⛏️';
      case UnitType.commander:
        return '⚔️';
      case UnitType.knight:
        return '🗡️';
      case UnitType.soldierTroop:
        return '👥';
      case UnitType.archer:
        return '🏹';
      case UnitType.architect:
        return '👷';
      case UnitType.virtualTower:
        return '🗼';
    }
  }

  String _getBuildingName(BuildingType type) {
    switch (type) {
      case BuildingType.cityCenter:
        return 'City Center';
      case BuildingType.farm:
        return 'Farm';
      case BuildingType.lumberCamp:
        return 'Lumber Camp';
      case BuildingType.mine:
        return 'Mine'; 
      case BuildingType.barracks:
        return 'Barracks';
      case BuildingType.defensiveTower:
        return 'Defensive Tower';
      case BuildingType.wall:
        return 'Wall';
      case BuildingType.warehouse:
        return 'Warehouse';
    }
  }

  String _getBuildingEmoji(BuildingType type) {
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

  // Get enemy unit at position
  Unit? _getEnemyUnitAt(Position position) {
    if (gameState.enemyFaction == null || gameState.enemyFaction!.units.isEmpty) {
      return null;
    }
    
    // Find any enemy unit at the selected position
    final unitsAtPosition = gameState.enemyFaction!.units
        .where((unit) => unit.position == position)
        .toList();
    
    if (unitsAtPosition.isNotEmpty) {
      return unitsAtPosition.first;
    }
    
    return null;
  }
  
  // Build enemy unit details when a tile with enemy unit is selected
  Widget _buildEnemyUnitDetails(Unit enemyUnit) {
    final isCombat = enemyUnit is CombatCapable;
    
    return Card(
      color: Colors.red.shade100,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with enemy indicator
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'ENEMY UNIT: ${enemyUnit.type.toString().split('.').last.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(),
            
            // Unit emoji and basic stats
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    enemyUnit.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Health
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text('Health: ${enemyUnit.currentHealth}/${enemyUnit.maxHealth}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Combat stats if applicable
                      if (isCombat) ...[
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text('Attack: ${(enemyUnit as CombatCapable).attackValue}'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.security, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text('Defense: ${(enemyUnit as CombatCapable).defenseValue}'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Abilities section
            const SizedBox(height: 12),
            const Text(
              'Unit Abilities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (enemyUnit is CombatCapable)
                  _buildAbilityChip(Icons.shield, 'Combat', Colors.red),
                if (enemyUnit is BuilderUnit)
                  _buildAbilityChip(Icons.build, 'Builder', Colors.amber),
                if (enemyUnit is HarvesterUnit)
                  _buildAbilityChip(Icons.eco, 'Harvester', Colors.green),
                if (enemyUnit is SettlerCapable)
                  _buildAbilityChip(Icons.home, 'Settler', Colors.blue),
              ],
            ),
            
            const SizedBox(height: 12),
            const Text(
              'Strategy Tip: Use combat units to attack this enemy or defensive towers to protect your territory.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbilityChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
    );
  }
}
