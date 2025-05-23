import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/services/game_service.dart';
import 'package:flutter_sim_city/widgets/unified_action_panel.dart';
import 'package:flutter_sim_city/widgets/game_map.dart';
import 'package:flutter_sim_city/widgets/resource_panel.dart';
import 'package:flutter_sim_city/widgets/turn_info_panel.dart';
import 'package:flutter_sim_city/widgets/save_load_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Create a controller
  final GameMapController _gameMapController = GameMapController();
  
  @override
  void initState() {
    super.initState();
    
    // Schedule a callback after the first frame to provide the controller to the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameMapControllerProvider.notifier).state = _gameMapController;
    });
  }
  
  @override
  void dispose() {
    // Clean up the provider
    ref.read(gameMapControllerProvider.notifier).state = null;
    super.dispose();
  }

  // Show the save dialog
  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => const SaveLoadDialog(isSaving: true),
    );
  }
  
  // Show the load dialog
  void _showLoadDialog() {
    showDialog(
      context: context,
      builder: (context) => const SaveLoadDialog(isSaving: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Resources and Menu
            Row(
              children: [
                // Game menu button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu),
                  onSelected: (value) async {
                    switch (value) {
                      case 'save':
                        _showSaveDialog();
                        break;
                      case 'load':
                        _showLoadDialog();
                        break;
              
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'save',
                      child: Text('Save Game'),
                    ),
                    const PopupMenuItem(
                      value: 'load',
                      child: Text('Load Game'),
                    ),
                    const PopupMenuItem(
                      value: 'autosave',
                      child: Text('Quick Save'),
                    ),
                    const PopupMenuItem(
                      value: 'load_autosave',
                      child: Text('Load Last Autosave'),
                    ),
                  ],
                ),
                
                // Resources panel takes the remaining space
                Expanded(
                  child: ResourcePanel(resources: gameState.resources),
                ),
              ],
            ),
            
            // Game area (map)
            Expanded(
              child: Stack(
                children: [
                  // Game map
                  GameMap(
                    controller: _gameMapController, // Pass the controller to access GameMap methods
                    map: gameState.map,
                    units: gameState.units,
                    buildings: gameState.buildings,
                    cameraPosition: gameState.cameraPosition,
                    selectedUnitId: gameState.selectedUnitId,
                    selectedBuildingId: gameState.selectedBuildingId,
                    selectedTilePosition: gameState.selectedTilePosition,
                    // Wenn eine Einheit ausgewählt ist, übergebe die gültigen Bewegungspositionen
                    validMovePositions: gameState.selectedUnitId != null 
                        ? gameState.getValidMovePositions()
                        : [],
                    onTileTap: (position) {
                      ref.read(gameStateProvider.notifier).selectTile(position);
                    },
                    onUnitTap: (unitId) {
                      ref.read(gameStateProvider.notifier).selectUnit(unitId);
                    },
                    onBuildingTap: (buildingId) {
                      ref.read(gameStateProvider.notifier).selectBuilding(buildingId);
                    },
                    // Pass enemy units and buildings if enemy faction exists
                    enemyUnits: gameState.enemyFaction?.units,
                    enemyBuildings: gameState.enemyFaction?.buildings,
                  ),
                  
                  // Turn information overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: TurnInfoPanel(
                      gameState: gameState, // Übergebe den gesamten GameState
                      turn: gameState.turn, 
                      onNextTurn: () async {
                        ref.read(gameStateProvider.notifier).nextTurn();
                      },
                      onJumpToFirstCity: () {
                        ref.read(gameStateProvider.notifier).jumpToFirstCity();
                      },
                      onJumpToEnemyHQ: gameState.enemyFaction?.headquarters != null 
                        ? () {
                          ref.read(gameStateProvider.notifier).jumpToEnemyHeadquarters();
                        } 
                        : null,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom action panel
            ActionPanel(
              gameState: gameState,
              onFoundCity: () {
                ref.read(gameStateProvider.notifier).foundCity();
              },
              onBuildingSelect: (buildingType) {
                ref.read(gameStateProvider.notifier)
                  .selectBuildingToBuild(buildingType);
              },
              onUnitSelect: (unitType) {
                ref.read(gameStateProvider.notifier)
                  .selectUnitToTrain(unitType);
              },
              onBuild: (position) {
                ref.read(gameStateProvider.notifier).buildBuilding(position);
              },
              onTrain: (unitType) {
                ref.read(gameStateProvider.notifier).trainUnit(unitType);
              },
              onHarvest: () {
                ref.read(gameStateProvider.notifier).harvestResource();
              },
              onClearSelection: () {
                ref.read(gameStateProvider.notifier).clearSelection();
              },
              onBuildFarm: () {
                ref.read(gameStateProvider.notifier).buildFarm();
              },
              onBuildLumberCamp: () {
                ref.read(gameStateProvider.notifier).buildLumberCamp();
              },
              onBuildMine: () {
                ref.read(gameStateProvider.notifier).buildMine();
              },
              onBuildBarracks: () {
                ref.read(gameStateProvider.notifier).buildBarracks();
              },
              onBuildDefensiveTower: () {
                ref.read(gameStateProvider.notifier).buildDefensiveTower();
              },
              onBuildWall: () {
                ref.read(gameStateProvider.notifier).buildWall();
              },
              onUpgradeBuilding: () {
                ref.read(gameStateProvider.notifier).upgradeBuilding();
              },
            ),
          ],
        ),
      ),
    );
  }
}