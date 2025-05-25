# Integrating with the Game Backend API

This document provides examples on how to integrate external clients with the Game Backend API.

## HTTP API

### Using cURL

```bash
# Check server status
curl http://localhost:8080/api/status

# Get game status
curl http://localhost:8080/api/game-status

# Start a new game
curl -X POST http://localhost:8080/api/start-new-game

# Add players
curl -X POST http://localhost:8080/api/players/add-human/Player1
curl -X POST http://localhost:8080/api/players/add-ai/AI_Player

# List all players
curl http://localhost:8080/api/players/all

# View map area
curl http://localhost:8080/api/area-map/10/10/5

# End turn
curl -X POST http://localhost:8080/api/end-turn
```

### Using JavaScript/Fetch API

```javascript
// Example of using the Game API from JavaScript/web applications

// Function to make API calls
async function callGameApi(endpoint, method = 'GET', data = null) {
  const options = {
    method: method,
    headers: {
      'Content-Type': 'application/json',
    }
  };
  
  if (data && (method === 'POST' || method === 'PUT')) {
    options.body = JSON.stringify(data);
  }
  
  const response = await fetch(`http://localhost:8080/api/${endpoint}`, options);
  const result = await response.json();
  
  if (!response.ok) {
    throw new Error(result.error || 'API call failed');
  }
  
  return result;
}

// Example usage
async function gameDemo() {
  try {
    // Get game status
    const status = await callGameApi('game-status');
    console.log('Game status:', status.gameStatus);
    
    // Start a new game
    const newGame = await callGameApi('start-new-game', 'POST');
    console.log('New game started:', newGame.message);
    
    // Add players
    await callGameApi('players/add-human/Player1', 'POST');
    await callGameApi('players/add-ai/Computer', 'POST');
    
    // Get list of players
    const players = await callGameApi('players/all');
    console.log('Players:', players.players);
    
    // End turn
    const turn = await callGameApi('end-turn', 'POST');
    console.log('Turn ended:', turn.message);
    
  } catch (error) {
    console.error('Game API error:', error);
  }
}

// Run the demo
gameDemo();
```

### Using Python/Requests

```python
import requests

# Base URL for the API
BASE_URL = 'http://localhost:8080/api'

def call_game_api(endpoint, method='GET', data=None):
    """Helper function to call the Game API"""
    url = f"{BASE_URL}/{endpoint}"
    
    if method == 'GET':
        response = requests.get(url)
    elif method == 'POST':
        response = requests.post(url, json=data)
    elif method == 'DELETE':
        response = requests.delete(url)
    else:
        raise ValueError(f"Unsupported HTTP method: {method}")
    
    # Check for errors
    response.raise_for_status()
    
    # Parse JSON response
    return response.json()

# Example usage
def game_demo():
    try:
        # Check server status
        status = call_game_api('status')
        print(f"Server status: {status['message']}")
        
        # Start new game
        new_game = call_game_api('start-new-game', method='POST')
        print(f"New game: {new_game['message']}")
        
        # Add players
        call_game_api('players/add-human/Player1', method='POST')
        call_game_api('players/add-ai/AI_Player', method='POST')
        
        # Get players
        players = call_game_api('players/all')
        print(f"Players: {players['players']}")
        
        # Get area map
        area_map = call_game_api('area-map/10/10/5')
        print("Map area:")
        print(area_map['map'])
        
        # End turn
        end_turn = call_game_api('end-turn', method='POST')
        print(f"End turn: {end_turn['message']}")
        
    except requests.exceptions.RequestException as e:
        print(f"API Error: {e}")

if __name__ == "__main__":
    game_demo()
```

## Using the Dart Client

For Dart applications, you can use the provided `GameApiClient` class:

```dart
import 'package:game_backend_service/game_api_client.dart';

Future<void> main() async {
  // Create client
  final client = GameApiClient();
  
  try {
    // Start a new game
    final newGame = await client.startNewGame();
    print('New game started: ${newGame['message']}');
    
    // Add players
    await client.addHumanPlayer('Player1');
    await client.addAIPlayer('Computer');
    
    // Get all players
    final players = await client.listAllPlayers();
    print('Players: ${players['players']}');
    
    // Get area map
    final map = await client.getAreaMap(10, 10, 5);
    print('Map:');
    print(map['map']);
    
    // End turn
    final endTurn = await client.endTurn();
    print('Turn ended: ${endTurn['message']}');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

## WebSockets (Future Enhancement)

WebSockets support will be added in a future release to allow real-time updates between the game and connected clients.
