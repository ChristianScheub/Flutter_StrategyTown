import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sim_city/models/game/game_state.dart';

/// Service to handle saving and loading game states
class SaveGameService {
  static const String _lastSaveKey = 'last_save';
  static const String _saveListKey = 'save_list';

  /// Save a game with the given name
  /// If no name is provided, it will be saved as "Save [timestamp]"
  static Future<bool> saveGame(GameState gameState, {String? name}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final saveName = name ?? 'Save ${DateTime.now().toString().split('.').first}';
      final saveKey = 'save_$timestamp';
      
      // Convert gameState to JSON
      final gameStateJson = gameState.toJson();
      final jsonString = jsonEncode(gameStateJson);
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(saveKey, jsonString);
      
      // Update last save key
      await prefs.setString(_lastSaveKey, saveKey);
      
      // Update save list
      final saveList = prefs.getStringList(_saveListKey) ?? <String>[];
      saveList.add('$saveKey|$saveName');
      await prefs.setStringList(_saveListKey, saveList);
      
      return true;
    } catch (e) {
      print('Error saving game: $e');
      return false;
    }
  }

  /// Load a saved game by key
  static Future<GameState?> loadGame(String saveKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(saveKey);
      
      if (jsonString == null) {
        return null;
      }
      
      final gameStateJson = jsonDecode(jsonString);
      return GameState.fromJson(gameStateJson);
    } catch (e) {
      print('Error loading game: $e');
      return null;
    }
  }

  /// Load the last saved game
  static Future<GameState?> loadLastSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaveKey = prefs.getString(_lastSaveKey);
      
      if (lastSaveKey == null) {
        return null;
      }
      
      return loadGame(lastSaveKey);
    } catch (e) {
      print('Error loading last save: $e');
      return null;
    }
  }

  /// Get a list of all saved games
  static Future<List<SavedGame>> getSaveList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveList = prefs.getStringList(_saveListKey) ?? <String>[];
      
      return saveList.map((saveString) {
        final parts = saveString.split('|');
        return SavedGame(
          key: parts[0],
          name: parts.length > 1 ? parts[1] : 'Unnamed Save',
        );
      }).toList();
    } catch (e) {
      print('Error getting save list: $e');
      return [];
    }
  }

  /// Delete a saved game
  static Future<bool> deleteSave(String saveKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove the save data
      await prefs.remove(saveKey);
      
      // Update save list
      final saveList = prefs.getStringList(_saveListKey) ?? <String>[];
      final updatedList = saveList.where((save) => !save.startsWith('$saveKey|')).toList();
      await prefs.setStringList(_saveListKey, updatedList);
      
      // If this was the last save, clear the last save key
      if (prefs.getString(_lastSaveKey) == saveKey) {
        await prefs.remove(_lastSaveKey);
      }
      
      return true;
    } catch (e) {
      print('Error deleting save: $e');
      return false;
    }
  }
  
  /// Export a save to a file (useful for sharing saves)
  static Future<String?> exportSave(String saveKey) async {
    if (kIsWeb) {
      // Web doesn't support file export the same way
      return null;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(saveKey);
      
      if (jsonString == null) {
        return null;
      }
      
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/flutter_sim_city_save.json';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return filePath;
    } catch (e) {
      print('Error exporting save: $e');
      return null;
    }
  }
  
  /// Import a save from a file
  static Future<bool> importSave(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      
      // Verify this is a valid save file
      final gameStateJson = jsonDecode(jsonString);
      GameState.fromJson(gameStateJson); // This will throw if the format is invalid
      
      // Save to shared preferences
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final saveName = 'Imported Save ${DateTime.now().toString().split('.').first}';
      final saveKey = 'save_$timestamp';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(saveKey, jsonString);
      
      // Update save list
      final saveList = prefs.getStringList(_saveListKey) ?? <String>[];
      saveList.add('$saveKey|$saveName');
      await prefs.setStringList(_saveListKey, saveList);
      
      return true;
    } catch (e) {
      print('Error importing save: $e');
      return false;
    }
  }
}

class SavedGame {
  final String key;
  final String name;
  
  SavedGame({required this.key, required this.name});
}
