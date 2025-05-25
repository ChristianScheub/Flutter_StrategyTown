import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sim_city/services/game_service.dart';
import 'package:flutter_sim_city/services/controlService/game_controller.dart';
import 'package:flutter_sim_city/widgets/unified_action_panel.dart';
import 'package:flutter_sim_city/widgets/game_map.dart';
import 'package:flutter_sim_city/widgets/resource_panel.dart';
import 'package:flutter_sim_city/widgets/turn_info_panel.dart';
import 'package:flutter_sim_city/widgets/save_load_dialog.dart';
import 'package:flutter_sim_city/services/controlService/init_game_for_gui_service.dart';
import 'package:flutter_sim_city/services/controlService/game_screen_migration_helper.dart';

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
    // and initialize the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameMapControllerProvider.notifier).state = _gameMapController;
      
      // Stelle sicher, dass das Spiel initialisiert ist und ein Spieler existiert
      ref.read(gameScreenMigrationHelperProvider).ensureGameInitialized();
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

  // Show multiplayer setup dialog
  void _showMultiplayerSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => _MultiplayerSetupDialog(),
    );
  }

  // Show player management dialog
  void _showPlayerManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _PlayerManagementDialog(),
    );
  }

  // Quick switch to next player
  void _switchToNextPlayer() {
    ref.read(gameControllerProvider).switchToNextPlayer();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to player: ${ref.read(gameControllerProvider).currentPlayerId}'),
        duration: const Duration(seconds: 2),
      ),
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
                    final gameController = ref.read(gameControllerProvider);
                    switch (value) {
                      case 'save':
                        _showSaveDialog();
                        break;
                      case 'load':
                        _showLoadDialog();
                        break;
                      case 'autosave':
                        await gameController.saveGame(saveName: 'autosave');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Game autosaved')),
                          );
                        }
                        break;
                      case 'load_autosave':
                        final success = await gameController.loadGame('autosave');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Autosave loaded' : 'Failed to load autosave')),
                          );
                        }
                        break;
                      case 'multiplayer_setup':
                        _showMultiplayerSetupDialog();
                        break;
                      case 'player_management':
                        _showPlayerManagementDialog();
                        break;
                      case 'switch_player':
                        _switchToNextPlayer();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    // Wir brauchen gameState hier eigentlich nicht mehr, da wir immer im Mehrspielermodus sind
                    return [
                      const PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Save Game'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'load',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open),
                            SizedBox(width: 8),
                            Text('Load Game'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'autosave',
                        child: Row(
                          children: [
                            Icon(Icons.flash_on),
                            SizedBox(width: 8),
                            Text('Quick Save'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'load_autosave',
                        child: Row(
                          children: [
                            Icon(Icons.flash_auto),
                            SizedBox(width: 8),
                            Text('Load Last Autosave'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      
                      // Multiplayer options
                      const PopupMenuItem(
                        value: 'multiplayer_setup',
                        child: Row(
                          children: [
                            Icon(Icons.group_add),
                            SizedBox(width: 8),
                            Text('Setup Multiplayer'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'player_management',
                        child: Row(
                          children: [
                            Icon(Icons.manage_accounts),
                            SizedBox(width: 8),
                            Text('Manage Players'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'switch_player',
                        child: Row(
                          children: [
                            Icon(Icons.switch_account),
                            SizedBox(width: 8),
                            Text('Switch Player'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
                
                // Resources panel takes the remaining space
                Expanded(
                  child: ResourcePanel(
                    resources: gameState.getPlayerResources(gameState.currentPlayerId),
                    playerName: gameState.playerManager.getPlayer(gameState.currentPlayerId)?.name,
                    playerId: gameState.currentPlayerId,
                  ),
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
              onJumpToFirstSettler: () {
                ref.read(gameControllerProvider).jumpToFirstSettler();
              },
            ),
          ],
        ),
      ),
      // ADDED: Floating action button for multiplayer player switching
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final gameState = ref.watch(gameStateProvider);
          
          return FloatingActionButton.extended(
            onPressed: _switchToNextPlayer,
            backgroundColor: gameState.isCurrentPlayerHuman ? Colors.blue : Colors.red,
            icon: Icon(
              gameState.isCurrentPlayerHuman ? Icons.person : Icons.computer,
              color: Colors.white,
            ),
            label: Text(
              'Current: ${gameState.currentPlayerId}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }
}

// Multiplayer Setup Dialog
class _MultiplayerSetupDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MultiplayerSetupDialog> createState() => _MultiplayerSetupDialogState();
}

class _MultiplayerSetupDialogState extends ConsumerState<_MultiplayerSetupDialog> {
  final List<PlayerConfig> _playerConfigs = [
    PlayerConfig.human('Player 1'),
    PlayerConfig.human('Player 2'),
  ];

  void _addPlayer() {
    setState(() {
      _playerConfigs.add(PlayerConfig.human('Player ${_playerConfigs.length + 1}'));
    });
  }

  void _removePlayer(int index) {
    if (_playerConfigs.length > 2) {
      setState(() {
        _playerConfigs.removeAt(index);
      });
    }
  }

  void _togglePlayerType(int index) {
    setState(() {
      final config = _playerConfigs[index];
      _playerConfigs[index] = PlayerConfig(
        name: config.name,
        isAI: !config.isAI,
        playerId: config.playerId,
      );
    });
  }

  void _setupMultiplayerGame() async {
    final initService = ref.read(initGameForGuiServiceProvider);
    
    final success = await initService.initCustomGame(
      playerConfigs: _playerConfigs,
    );
    
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Multiplayer game started with ${_playerConfigs.length} players!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start multiplayer game'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup Multiplayer Game'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Configure players for the game:'),
            const SizedBox(height: 16),
            
            // Player list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _playerConfigs.length,
                itemBuilder: (context, index) {
                  final config = _playerConfigs[index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        config.isAI ? Icons.computer : Icons.person,
                        color: config.isAI ? Colors.red : Colors.blue,
                      ),
                      title: TextFormField(
                        initialValue: config.name,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Player name',
                        ),
                        onChanged: (value) {
                          _playerConfigs[index] = PlayerConfig(
                            name: value,
                            isAI: config.isAI,
                            playerId: config.playerId,
                          );
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: config.isAI,
                            onChanged: (_) => _togglePlayerType(index),
                          ),
                          if (_playerConfigs.length > 2)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removePlayer(index),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add player button
            if (_playerConfigs.length < 6)
              OutlinedButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.add),
                label: const Text('Add Player'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _setupMultiplayerGame,
          child: const Text('Start Game'),
        ),
      ],
    );
  }
}

// Player Management Dialog
class _PlayerManagementDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameController = ref.watch(gameControllerProvider);
    final gameState = ref.watch(gameStateProvider);
    final allPlayerIds = gameController.getAllPlayerIds();

    return AlertDialog(
      title: const Text('Player Management'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Current Game: Multiplayer'),
            const SizedBox(height: 16),
            
            // Current player info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gameState.isCurrentPlayerHuman 
                    ? Colors.blue.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: gameState.isCurrentPlayerHuman ? Colors.blue : Colors.red,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        gameState.isCurrentPlayerHuman ? Icons.person : Icons.computer,
                        color: gameState.isCurrentPlayerHuman ? Colors.blue : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Player: ${gameState.currentPlayerId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Units: ${gameController.currentPlayerUnits.length}'),
                      Text('Buildings: ${gameController.currentPlayerBuildings.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Player list
            const Text('All Players:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allPlayerIds.length,
                itemBuilder: (context, index) {
                  final playerId = allPlayerIds[index];
                  final isHuman = gameState.isHumanPlayer(playerId);
                  final isCurrent = playerId == gameState.currentPlayerId;
                  final player = gameState.playerManager.getPlayer(playerId);
                  
                  return Card(
                    color: isCurrent ? (isHuman ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1)) : null,
                    child: ListTile(
                      leading: Icon(
                        isHuman ? Icons.person : Icons.computer,
                        color: isHuman ? Colors.blue : Colors.red,
                      ),
                      title: Text(
                        player?.name ?? playerId,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${isHuman ? 'Human' : 'AI'} • Points: ${player?.points ?? 0}',
                      ),
                      trailing: isCurrent 
                          ? const Icon(Icons.star, color: Colors.amber)
                          : IconButton(
                              icon: const Icon(Icons.switch_account),
                              onPressed: () {
                                gameController.switchToPlayer(playerId);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Switched to $playerId')),
                                );
                              },
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (gameState.isMultiplayer)
          OutlinedButton.icon(
            onPressed: () {
              gameController.switchToNextPlayer();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to ${gameController.currentPlayerId}')),
              );
            },
            icon: const Icon(Icons.skip_next),
            label: const Text('Next Player'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}