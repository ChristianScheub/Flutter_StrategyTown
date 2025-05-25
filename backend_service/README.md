# Game Backend Service

This is a standalone backend API service for the Sim City-style game. It provides RESTful endpoints to control the game using the existing Terminal Game Interface.

## Features

- Complete API for game control
- Independent from Flutter app
- RESTful API with JSON responses
- Allows multiple clients to connect

## Getting Started

### Prerequisites

- Dart SDK 3.0.0 or higher

### Installation

1. Navigate to the backend_service directory:
   ```
   cd backend_service
   ```

2. Install dependencies:
   ```
   dart pub get
   ```

3. Run the server:
   ```
   dart run bin/server.dart
   ```
   
   Alternatively, you can use the provided script that installs all dependencies:
   ```
   ./start_with_deps.sh
   ```

The server will start on port 8080 by default. You can change this by setting the PORT environment variable.

### Web Dashboard

The API comes with a built-in web dashboard for easy interaction:

1. Open your browser and navigate to:
   ```
   http://localhost:8080/dashboard
   ```

2. Use the dashboard to:
   - Check game status
   - Manage players
   - View the game map
   - Perform actions
   - Build structures
   - And more!

This makes it easy to interact with the game without writing code.

## API Documentation

### Game Status

- `GET /api/status` - Get server status
- `GET /api/game-status` - Get current game status
- `GET /api/detailed-game-status` - Get detailed game status
- `GET /api/available-actions` - Get available game actions

### Units

- `GET /api/units` - List current player's units
- `GET /api/units/:playerId` - Get units for specific player
- `POST /api/units/select/:unitId` - Select a unit
- `POST /api/units/move/:unitId/:x/:y` - Move unit to position
- `POST /api/units/attack/:unitId/:targetX/:targetY` - Attack target
- `POST /api/units/harvest` - Harvest resources with selected unit

### Buildings

- `GET /api/buildings` - List current player's buildings
- `GET /api/buildings/:playerId` - Get buildings for specific player
- `POST /api/buildings/select/:buildingId` - Select a building
- `POST /api/buildings/upgrade` - Upgrade selected building
- `POST /api/buildings/build/:type/:x/:y` - Build building at position
- `POST /api/buildings/build-at-position/:x/:y` - Build at current position

### Quick Build Actions

- `POST /api/quick-build/farm` - Build farm
- `POST /api/quick-build/lumber-camp` - Build lumber camp
- `POST /api/quick-build/mine` - Build mine
- `POST /api/quick-build/barracks` - Build barracks
- `POST /api/quick-build/defensive-tower` - Build defensive tower
- `POST /api/quick-build/wall` - Build wall

### Training Units

- `POST /api/train-unit/:unitType/:buildingId` - Train unit at building
- `POST /api/train-unit-generic/:unitType` - Train unit generically
- `POST /api/select-unit-to-train/:unitType` - Select unit type for training
- `POST /api/select-building-to-build/:buildingType` - Select building type for construction

### Map and Tile Information

- `GET /api/tile-info/:x/:y` - Get information about tile
- `GET /api/tile-resources/:x/:y` - Get resources on tile
- `GET /api/area-map/:centerX/:centerY/:radius` - Get map of an area
- `POST /api/select-tile/:x/:y` - Select tile at position

### Game Flow

- `POST /api/end-turn` - End current turn
- `POST /api/clear-selection` - Clear current selection
- `POST /api/found-city` - Found city with selected settler

### Camera Controls

- `POST /api/jump-to-first-city` - Jump camera to first city
- `POST /api/jump-to-enemy-hq` - Jump camera to enemy headquarters

### Game Management

- `POST /api/start-new-game` - Start a new game
- `POST /api/save-game/:name` - Save current game
- `POST /api/load-game/:key` - Load saved game

### Player Management

- `GET /api/players/all` - List all players
- `GET /api/players/current` - Get current player info
- `GET /api/player-statistics/:playerId` - Get player statistics
- `GET /api/scoreboard` - Get scoreboard with rankings
- `POST /api/players/add-human/:name` - Add human player
- `POST /api/players/add-ai/:name` - Add AI player
- `DELETE /api/players/remove/:playerId` - Remove player

### Multiplayer Controls

- `POST /api/switch-player` - Switch to next player
- `POST /api/switch-to-player/:playerId` - Switch to specific player

## Example Usage

Using curl to get game status:
```
curl http://localhost:8080/api/game-status
```

Starting a new game:
```
curl -X POST http://localhost:8080/api/start-new-game
```

Moving a unit:
```
curl -X POST http://localhost:8080/api/units/move/unit_123/10/15
```
