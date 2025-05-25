import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_core/game_core.dart';

/// Handles saving and loading game states using SharedPreferences
class SaveGameService {
  static const String _saveKeyPrefix = 'game_save_';
  static const String _saveListKey = 'game_save_list';
  
  /// Returns a list of all saved games with their metadata
  static Future<List<Map<String, dynamic>>> getSaveList() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saveListJson = prefs.getStringList(_saveListKey) ?? [];
    
    return saveListJson
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
  }
  
  /// Saves the current game state
  /// Returns true if successful, false otherwise
  static Future<bool> saveGame(GameState gameState, {String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate unique key and default name if none provided
      final timestamp = DateTime.now();
      final saveKey = '${_saveKeyPrefix}${timestamp.millisecondsSinceEpoch}';
      final saveName = name ?? 'Save ${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute}';
      
      // Convert gameState to JSON string
      final gameStateJson = gameState.toJson();
      final gameStateString = jsonEncode(gameStateJson);
      
      // Save the game state
      await prefs.setString(saveKey, gameStateString);
      
      // Create metadata for the save list
      final saveMetadata = {
        'key': saveKey,
        'name': saveName,
        'timestamp': timestamp.toIso8601String(),
      };
      
      // Update save list
      List<String> saveList = prefs.getStringList(_saveListKey) ?? [];
      saveList.add(jsonEncode(saveMetadata));
      await prefs.setStringList(_saveListKey, saveList);
      
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }
  
  /// Loads a game state by its key
  /// Returns the loaded GameState if successful, null otherwise
  static Future<GameState?> loadGame(String saveKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateString = prefs.getString(saveKey);
      
      if (gameStateString == null) return null;
      
      final Map<String, dynamic> gameStateJson = jsonDecode(gameStateString);
      return GameState.fromJson(gameStateJson);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }
  
  /// Deletes a saved game by its key
  /// Returns true if successful, false otherwise
  static Future<bool> deleteSave(String saveKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the game state
      await prefs.remove(saveKey);
      
      // Remove from save list
      List<String> saveList = prefs.getStringList(_saveListKey) ?? [];
      saveList = saveList.where((item) {
        final data = jsonDecode(item) as Map<String, dynamic>;
        return data['key'] != saveKey;
      }).toList();
      
      await prefs.setStringList(_saveListKey, saveList);
      return true;
    } catch (e) {
      print('Error deleting save: $e');
      return false;
    }
  }
}
