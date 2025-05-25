# Game Backend Service

This directory contains a standalone backend API service for the Sim City-style game. It provides a REST API that allows controlling the game through HTTP requests.

## Features

- Exposes the game functionality through a REST API
- Runs independently from the Flutter app
- Can be accessed from any HTTP client

## Getting Started

### Prerequisites

- Dart SDK 3.0.0 or higher

### Running the server

1. Start the backend service:

```bash
cd backend_service
./run_server.sh
```

The server will start on port 8080 by default.

### Testing the API

You can use the included example client to test the API:

```bash
cd backend_service
./run_example.sh
```

Or use curl to test individual endpoints:

```bash
# Get game status
curl http://localhost:8080/api/game-status

# Start a new game
curl -X POST http://localhost:8080/api/start-new-game
```

## API Documentation

See the [backend_service/README.md](README.md) file for complete API documentation.

## Architecture

The backend service is completely independent from the Flutter app. It uses the `TerminalGameInterface` class to interact with the game, but runs in its own process. This means:

1. The Flutter app can run normally without the backend service
2. The backend service can be started separately when needed
3. Multiple clients can connect to the backend service to control the game

## Note

This backend service is meant for development and testing purposes. It can be used to:

- Test game functionality through HTTP requests
- Create custom clients for the game
- Integrate with external tools and systems

For production use, additional security measures should be implemented.
