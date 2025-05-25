import 'dart:io';
import 'package:game_backend_service/game_api_client.dart';

void main(List<String> args) async {
  print('Game API Client Example');
  print('======================');
  
  // Create API client
  final client = GameApiClient();
  
  try {
    // Check server status
    print('Checking server status...');
    final status = await client.getStatus();
    print('Server status: ${status['message']}');
    // Get game status
    print('Getting game status...');
    final gameStatus = await client.getGameStatus();
    print(gameStatus['gameStatus']);    
    // Start a new game
    print('Starting a new game...');
    final newGame = await client.startNewGame();
    print(newGame['message']);
    // Add players
    print('Adding players...');
    final addHuman = await client.addHumanPlayer('Player1');
    print(addHuman['message']);
    final addAI = await client.addAIPlayer('AI_Opponent');
    print(addAI['message']);
    
    // List all players
    print('Listing all players...');
    final allPlayers = await client.listAllPlayers();
    print(allPlayers['players']);
    
    // Get area map
    print('Getting area map...');
    final map = await client.getAreaMap(5, 5, 10);
    print(map['map']);
    
    // End turn
    print('Ending turn...');
    final endTurn = await client.endTurn();
    print(endTurn['message']);
    
    print('Example complete!');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
