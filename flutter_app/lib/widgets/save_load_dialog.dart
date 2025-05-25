import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';
import '../services/save_game_service.dart'; // Add this import

// Define a local SavedGameInfo class to work with save game data
class SavedGameInfo {
  final String key;
  final String name;
  final DateTime timestamp;
  
  SavedGameInfo({
    required this.key, 
    required this.name, 
    required this.timestamp
  });
}

class SaveLoadDialog extends ConsumerStatefulWidget {
  final bool isSaving;
  
  const SaveLoadDialog({
    super.key,
    this.isSaving = true, // true for save dialog, false for load dialog
  });

  @override
  ConsumerState<SaveLoadDialog> createState() => _SaveLoadDialogState();
}

class _SaveLoadDialogState extends ConsumerState<SaveLoadDialog> {
  final TextEditingController _saveNameController = TextEditingController();
  List<SavedGameInfo> _savedGames = [];
  bool _isLoading = true;
  String? _selectedSaveKey;
  
  @override
  void initState() {
    super.initState();
    _loadSaveList();
  }
  
  @override
  void dispose() {
    _saveNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSaveList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final savedGamesData = await SaveGameService.getSaveList();
      
      // Convert the response to our local SavedGameInfo type
      final processedGames = savedGamesData.map((gameData) => 
        SavedGameInfo(
          key: gameData['key'] ?? '',
          name: gameData['name'] ?? 'Unnamed Save',
          timestamp: DateTime.tryParse(gameData['timestamp'] ?? '') ?? DateTime.now(),
        )
      ).toList();
      
      setState(() {
        _savedGames = processedGames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _savedGames = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading saves: $e')),
        );
      }
    }
  }
  
  Future<void> _saveGame() async {
    final gameState = ref.read(gameServiceProvider);
    final success = await SaveGameService.saveGame(
      gameState,
      name: _saveNameController.text.isNotEmpty 
          ? _saveNameController.text 
          : null,
    );
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game saved successfully')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save game')),
        );
      }
    }
  }
  
  Future<void> _loadGame() async {
    if (_selectedSaveKey == null) return;
    
    final gameState = await SaveGameService.loadGame(_selectedSaveKey!);
    
    if (gameState != null) {
      // Update the game state
      ref.read(gameServiceProvider.notifier).loadGameState(gameState);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game loaded successfully')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load game')),
        );
      }
    }
  }
  
  Future<void> _deleteSave(String saveKey, String saveName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$saveName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await SaveGameService.deleteSave(saveKey);
      
      if (success) {
        _loadSaveList();
        if (_selectedSaveKey == saveKey) {
          _selectedSaveKey = null;
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSaving ? 'Save Game' : 'Load Game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Save game name input (only for saving)
            if (widget.isSaving) ...[
              TextField(
                controller: _saveNameController,
                decoration: const InputDecoration(
                  labelText: 'Save Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Save list
            const Text(
              'Saved Games',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _savedGames.isEmpty
                      ? const Center(
                          child: Text('No saved games found'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _savedGames.length,
                          itemBuilder: (context, index) {
                            final save = _savedGames[index];
                            final isSelected = _selectedSaveKey == save.key;
                            
                            return ListTile(
                              title: Text(save.name),
                              subtitle: Text(
                                '${save.timestamp.day}/${save.timestamp.month}/${save.timestamp.year} '
                                '${save.timestamp.hour}:${save.timestamp.minute.toString().padLeft(2, '0')}'
                              ),
                              selected: isSelected,
                              tileColor: isSelected 
                                  ? Theme.of(context).colorScheme.primaryContainer 
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedSaveKey = save.key;
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteSave(save.key, save.name),
                              ),
                            );
                          },
                        ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.isSaving
                      ? _saveGame
                      : (_selectedSaveKey != null ? _loadGame : null),
                  child: Text(widget.isSaving ? 'Save' : 'Load'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
