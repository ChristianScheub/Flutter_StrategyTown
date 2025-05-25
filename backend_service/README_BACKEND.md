# Backend Multiplayer Service

## Overview

The `backend_service` component provides robust backend infrastructure for our strategy simulation game, enabling multiplayer functionality, game state persistence, and remote game management. This service bridges the gap between different client instances, allowing players to engage in shared game worlds while maintaining game state consistency.

Built using Dart and the Shelf framework, this backend service exposes a RESTful API that the Flutter frontend can consume for multiplayer sessions. It integrates tightly with the `game_core` library to ensure that game rules and mechanics remain consistent between local and remote play.

## Key Features

- **RESTful Game API** - Comprehensive endpoints for game state manipulation
- **Multiplayer Session Management** - Creation and coordination of multiplayer games
- **Game State Synchronization** - Efficient state updates between clients
- **Authentication & Authorization** - Secure access to game resources
- **Game Persistence** - Save and restore functionality for multiplayer games
- **Admin Dashboard** - Browser-based monitoring and management interface
- **WebSocket Support** - Real-time updates for active games
- **Logging & Analytics** - Comprehensive game session logging

## Architecture

The backend service follows a clean architecture with clear separation of concerns:

### Directory Structure

```
backend_service/
├── bin/                   # Server entry points
│   └── server.dart        # Main server application
├── lib/                   # Core library code
│   ├── game_api_service.dart  # API route definitions
│   └── http_utils.dart    # HTTP utilities
├── docs/                  # Documentation
│   └── integration_examples.md # Client integration examples
├── example/               # Example code
│   └── client_example.dart # Demo API client
├── public/                # Static files
│   └── dashboard.html     # Admin dashboard
└── scripts/               # Utility scripts
    ├── run_server.sh      # Start server script
    └── start_with_deps.sh # Full stack startup script
```

### Technical Architecture

The backend implements a layered architecture:

1. **API Layer** - RESTful endpoints and request handling
2. **Service Layer** - Business logic and game operations
3. **Domain Layer** - Game state and rules (via game_core)
4. **Persistence Layer** - State storage and retrieval

#### API Layer

The API layer is built with the Dart Shelf framework and exposes RESTful endpoints for:

- Game session management (`/api/games`)
- Player actions (`/api/games/{gameId}/actions`)
- Game state queries (`/api/games/{gameId}/state`)
- Authentication (`/api/auth`)
- Administrative functions (`/api/admin`)

Each endpoint follows RESTful principles with appropriate HTTP methods:
- GET for retrieval
- POST for creation
- PUT for updates
- DELETE for removal

#### Service Layer

The service layer contains the core business logic:

- **GameService** - Manages game sessions
- **ActionService** - Processes player actions
- **AuthService** - Handles authentication
- **PersistenceService** - Manages game state storage

This layer translates API requests into operations on the domain model.

#### Domain Layer

The domain layer leverages the game_core library to:

- Validate game actions
- Apply game rules
- Update game state
- Calculate outcomes

By using the shared game_core, we ensure consistent behavior between frontend and backend.

#### Persistence Layer

Game state is persisted through:

- In-memory cache for active games
- File-based storage for saved games
- Optional database integration for production environments

### Request Flow Diagram

```
Client Request → API Endpoint → Service Layer → Domain Logic → Response
     ↑                                  ↓
     └──────── State Updates ───────────┘
```

### Multiplayer Architecture

The multiplayer system uses a hybrid of:

1. **HTTP REST API** - For discrete actions and state queries
2. **WebSockets** - For real-time updates and notifications
3. **Polling** - As a fallback for environments without WebSocket support

This provides flexibility while maintaining responsiveness.

## API Documentation

The backend provides a comprehensive API for game interaction. Key endpoints include:

### Game Management

```
GET    /api/games               # List available games
POST   /api/games               # Create new game
GET    /api/games/{id}          # Get game details
DELETE /api/games/{id}          # Delete game
```

### Game Actions

```
POST   /api/games/{id}/actions/move      # Move a unit
POST   /api/games/{id}/actions/build     # Build structure
POST   /api/games/{id}/actions/end-turn  # End current turn
```

### Player Management

```
GET    /api/games/{id}/players           # List players
POST   /api/games/{id}/players           # Add player
DELETE /api/games/{id}/players/{playerId} # Remove player
```

### Game State

```
GET    /api/games/{id}/state             # Full game state
GET    /api/games/{id}/state/resources   # Resource status
GET    /api/games/{id}/state/map         # Map data
```

For complete API documentation, please refer to the `BACKEND_API.md` file in the project root.

## Setup and Deployment

### Prerequisites

- Dart SDK 2.17.0 or higher
- Dependencies as listed in pubspec.yaml

### Local Development

```bash
# Navigate to backend directory
cd backend_service

# Get dependencies
dart pub get

# Run the server locally
./run_server.sh
```

By default, the server runs on port 8080 and accepts connections from localhost.

### Configuration

The server can be configured through environment variables:

- `PORT` - Server port (default: 8080)
- `HOST` - Bind address (default: localhost)
- `STORAGE_PATH` - Path for saved games
- `LOG_LEVEL` - Logging verbosity

### Docker Deployment

A Dockerfile is provided for containerized deployment:

```bash
# Build the Docker image
docker build -t game-backend .

# Run the container
docker run -p 8080:8080 game-backend
```

## Testing

The backend includes comprehensive tests:

```bash
# Run unit tests
dart test

# Run integration tests
dart test integration_test
```

## Monitoring

The backend includes a simple web dashboard for monitoring:

1. Start the server
2. Navigate to http://localhost:8080/dashboard.html
3. View active games, player counts, and server metrics

## Security Considerations

- Authentication via API keys for production use
- Input validation on all endpoints
- Rate limiting to prevent abuse
- CORS configuration for frontend access

## License

This backend service is part of the main project and shares the same license.
- `start_with_deps.sh` - Script to start server with dependencies

## Getting Started
1. Install dependencies (if any):
   ```sh
   # Add dependency installation steps here if needed
   ```
2. Run the server:
   ```sh
   ./run_server.sh
   ```

## Notes
- See `docs/integration_examples.md` for API usage examples.
- See `BACKEND_API.md` in the root for API documentation.
