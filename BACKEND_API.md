# Game Backend API Service

This project includes a standalone backend API service in the `backend_service` folder. This service provides a REST API for controlling the game through HTTP requests.

## Key Features

- **Independent Operation**: The backend service runs separately from the Flutter app
- **REST API**: Provides a complete HTTP API for all game functionality
- **Web Dashboard**: Includes a web interface for interacting with the game
- **Multiple Client Support**: Can be used from various clients and programming languages

## Getting Started

### Running the API Server

1. Navigate to the backend_service directory:
   ```
   cd backend_service
   ```

2. Run the start script:
   ```
   ./start_with_deps.sh
   ```

3. The server will start on port 8080 by default

### Using the API

- **Web Dashboard**: http://localhost:8080/dashboard
- **API Documentation**: See `backend_service/README.md` for full API documentation
- **API Base URL**: http://localhost:8080/api

## Architecture

The backend service is designed to be completely independent from the Flutter UI. It uses the existing `TerminalGameInterface` to interact with the game engine, but runs in a separate process.

This separation of concerns means:

1. The Flutter app works normally without requiring the backend
2. External tools and custom UIs can control the game via the API
3. The game state can be accessed and modified through HTTP requests

## Learn More

For more details, see:
- `backend_service/README.md` - Full API reference
- `backend_service/docs/integration_examples.md` - Examples of integrating with the API
