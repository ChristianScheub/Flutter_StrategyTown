import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/services/game_service.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';
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
                      ref.read(gameControllerProvider).selectTile(position);
                    },
                    onUnitTap: (unitId) {
                      ref.read(gameControllerProvider).selectUnit(unitId);
                    },
                    onBuildingTap: (buildingId) {
                      ref.read(gameControllerProvider).selectBuilding(buildingId);
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
                        ref.read(gameControllerProvider).endTurn();
                      },
                      onJumpToFirstCity: () {
                        ref.read(gameControllerProvider).jumpToFirstCity();
                      },
                      onJumpToEnemyHQ: gameState.enemyFaction?.headquarters != null 
                        ? () {
                          ref.read(gameControllerProvider).jumpToEnemyHeadquarters();
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
                ref.read(gameControllerProvider).foundCity();
              },
              onBuildingSelect: (buildingType) {
                ref.read(gameControllerProvider)
                  .selectBuildingToBuild(buildingType);
              },
              onUnitSelect: (unitType) {
                ref.read(gameControllerProvider)
                  .selectUnitToTrain(unitType);
              },
              onBuild: (position) {
                ref.read(gameControllerProvider).buildBuildingAtPosition(position);
              },
              onTrain: (unitType) {
                ref.read(gameControllerProvider).trainUnitGeneric(unitType);
              },
              onHarvest: () {
                ref.read(gameControllerProvider).harvestResource();
              },
              onClearSelection: () {
                ref.read(gameControllerProvider).clearSelection();
              },
              onBuildFarm: () {
                ref.read(gameControllerProvider).buildFarm();
              },
              onBuildLumberCamp: () {
                ref.read(gameControllerProvider).buildLumberCamp();
              },
              onBuildMine: () {
                ref.read(gameControllerProvider).buildMine();
              },
              onBuildBarracks: () {
                ref.read(gameControllerProvider).buildBarracks();
              },
              onBuildDefensiveTower: () {
                ref.read(gameControllerProvider).buildDefensiveTower();
              },
              onBuildWall: () {
                ref.read(gameControllerProvider).buildWall();
              },
              onUpgradeBuilding: () {
                ref.read(gameControllerProvider).upgradeBuilding();
              },
            ),
          ],
        ),
      ),
    );
  }
}