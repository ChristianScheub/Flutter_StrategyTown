# Backend Game Service

## Overview

The `backend_service` component provides a robust server infrastructure for our strategy simulation game, enabling multiplayer functionality, game state management, and remote game operations. This service acts as a bridge between client instances, allowing players to interact with shared game worlds while maintaining consistent game state.

Developed using Dart and the Shelf framework, this backend exposes a RESTful API that can be consumed by any client, including our Flutter frontend. It integrates seamlessly with the `game_core` library to ensure game rules and mechanics remain consistent between local and networked play.

## Features

- **RESTful API** - Comprehensive endpoints for all game operations
- **Game State Management** - Centralized handling of game state
- **Player Management** - Addition and removal of human and AI players
- **Unit & Building Control** - Commands for creating and managing game entities
- **Resource Management** - Tracking and allocation of in-game resources
- **Map Generation** - Dynamic terrain and resource distribution
- **Turn-Based System** - Structured gameplay progression
- **Admin Dashboard** - Browser-based monitoring and control interface
- **Real-time Updates** - Immediate state reflection across clients
- **Cross-Platform Compatibility** - Works with web, mobile, and desktop clients

## Architecture

### System Architecture
The backend follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                     │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                        HTTP/REST API                        │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                       API Router Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Game Routes │  │ Unit Routes │  │ Other Domain Routes │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                      Handler Layer                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │GameHandlers │  │UnitHandlers │  │ Other Domain Handlers│  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Terminal Game Interface                │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │Game Models  │  │Game State   │  │   Game Controller   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Layer Descriptions

#### API Layer
- **Router (`api_router.dart`)**: Maps HTTP endpoints to appropriate handlers
- **Request/Response Handling**: Processes incoming requests and formats responses
- **Input Validation**: Ensures request data is valid before processing
- **Error Handling**: Provides consistent error responses

#### Handler Layer
- **Game Handlers**: Manage game flow and state operations
- **Unit Handlers**: Process unit-related commands
- **Building Handlers**: Handle building creation and management
- **Player Handlers**: Manage player creation and selection
- **Map Handlers**: Process map-related queries

#### Service Layer
- **Terminal Game Interface**: Provides a unified interface to the game core
- **API Responses**: Standardizes response formats
- **Service Providers**: Leverage Riverpod for dependency injection

#### Domain Layer (game_core)
- **Game Models**: Define entities like units, buildings, and resources
- **Game State**: Maintains the current state of the game
- **Game Controller**: Executes game logic and rule enforcement

### Component Interaction

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│  Client  │  HTTP   │   API    │ Method  │ Handler  │ Method  │ Terminal │
│ Request  ├────────►│  Router  ├────────►│  Layer   ├────────►│   Game   │
└──────────┘         └──────────┘         └────┬─────┘         │ Interface│
                                               │               └────┬─────┘
┌──────────┐         ┌──────────┐         ┌────▼─────┐         ┌────▼─────┐
│  Client  │◄────────┤ Response │◄────────┤  Result  │◄────────┤   Game   │
│ Response │  HTTP   │ Formatter│ Data    │ Processor│ Game    │Controller │
└──────────┘         └──────────┘         └──────────┘ State   └──────────┘
```

### Directory Structure
```
backend_service/
├── bin/                   # Server entry points
│   └── server.dart        # Main server application
├── lib/                   # Core library code
│   ├── game_api_service.dart  # Main API service
│   └── api/               # API components
│       ├── api_router.dart    # Route definitions
│       ├── api_responses.dart # Response utilities
│       └── handlers/      # Request handlers by domain
├── public/                # Static files
│   └── dashboard.html     # Admin dashboard
└── scripts/               # Utility scripts
```

## API Endpoints

The backend service exposes the following RESTful endpoints:

### Game Management
- `GET /api/new-game` - Create a new game instance
- `GET /api/reset-game` - Reset the current game to initial state
- `GET /api/game-state` - Get the current game state
- `GET /api/end-turn` - End the current player's turn

### Player Management
- `GET /api/add-human-player` - Add a human player to the game
- `GET /api/add-ai-player` - Add an AI player to the game
- `GET /api/current-player` - Get the current active player's ID
- `GET /api/list-players` - List all players in the game

### Unit Management
- `GET /api/list-player-units` - Get list of current player's units (returns structured JSON with unit IDs, positions, and types)
- `GET /api/get-player-units` - Get detailed information about player units (backward compatibility endpoint)
- `POST /api/move-unit` - Move a unit to a new position
- `POST /api/attack` - Command a unit to attack a target
- `POST /api/create-unit` - Create a new unit for a player
- `POST /api/give-starting-units` - Initialize a player with starting units

### Map Management
- `GET /api/map-state` - Get the current map configuration
- `GET /api/terrain-at` - Get terrain information at a specific position

## Available Scripts

### Development Scripts
- `run_server.sh`: Starts the game backend server
  ```bash
  ./run_server.sh
  ```

- `start_with_deps.sh`: Starts the server with all dependencies
  ```bash
  ./start_with_deps.sh
  ```

### Running in Production
For production deployment, we recommend using Docker:
```bash
# Build the Docker image
docker build -t game-backend .

# Run the container
docker run -p 8081:8081 game-backend
```

## Libraries Used

### Core Dependencies
- **Shelf**: HTTP server framework for Dart
  - `shelf`: Base server functionality
  - `shelf_router`: Route handling and URL mapping
  - `shelf_static`: Static file serving

### State Management
- **Riverpod**: Dependency injection and state management
  - Used for providing game services and maintaining state

### Game Engine
- **game_core**: Custom game logic and state management library
  - Handles game rules, mechanics, and entity management
  - Shared between frontend and backend for consistency

### Utilities
- **path**: File path manipulation
- **http**: HTTP client for testing
- **logging**: Structured logging capabilities
- **json_serializable**: JSON serialization/deserialization

## Getting Started

1. Ensure you have Dart SDK 2.17.0 or later installed
2. Navigate to the backend_service directory
3. Run the server:
   ```bash
   ./run_server.sh
   ```
4. The server will start on port 8081 by default
5. Access the dashboard at http://localhost:8081/dashboard
6. Use API endpoints at http://localhost:8081/api/

For API documentation, see the `docs/integration_examples.md` file for usage examples.
