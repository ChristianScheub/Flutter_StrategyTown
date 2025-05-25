# Game Core Library

## Overview

The `game_core` library is the central component of our strategy simulation game, providing the fundamental game engine, simulation mechanics, and domain models. This package acts as the heart of the game, handling everything from map generation and unit management to resource calculations and AI behavior.

This library has been designed to be platform-agnostic, allowing it to be used across different frontends (Flutter UI, command-line interfaces, or even potential future web interfaces) while maintaining the same consistent game logic.

## Key Features

- **Procedural Map Generation** - Dynamic terrain generation with intelligent resource distribution
- **Turn-Based Simulation Engine** - Complete rule processing and state management
- **Unit Management System** - Comprehensive unit types with unique capabilities
- **Building & Construction System** - Various building types with production chains
- **Resource Management** - Economic system with multiple resource types
- **AI Player Logic** - Smart computer opponents with strategic decision making
- **Multiplayer Support** - Core mechanics for multiplayer game sessions
- **Save/Load System** - Game state serialization and persistence

## Architecture

The `game_core` library follows a carefully designed architecture with clear separation of concerns. Below is a technical breakdown of the key components:

### Domain Models

The domain layer contains the core entities of the game:

```
lib/src/models/
├── buildings/          # Building entities (farms, mines, etc.)
├── enemy_faction/      # AI faction models
├── game/               # Game state and player management
├── map/                # Terrain, tile system and position management
├── resource/           # Resource types and collection management
└── units/              # Unit implementations with specialized abilities
    ├── civilian/       # Non-combat units
    ├── military/       # Combat-focused units
    └── capabilities/   # Unit capability traits
```

### Services Layer

The services layer handles game logic and manipulations of the domain models:

```
lib/src/services/
├── ai/                 # AI decision making and behavior
├── controlService/     # Game flow control and command handling
├── game/               # Core game state management
│   ├── building_service.dart
│   ├── camera_service.dart
│   ├── game_state_notifier.dart
│   ├── selection_service.dart
│   ├── specialized_building_service.dart
│   ├── turn_service.dart
│   └── unit_service.dart
├── save_game/          # Game state persistence
└── score/              # Scoring and progression systems
```

### Core Architecture

#### State Management Flow

The game core uses a unidirectional data flow pattern:

1. **Game State** - The central `GameState` class is an immutable representation of the complete game state
2. **Actions** - Actions are dispatched through services (e.g., `UnitService.moveUnit()`)
3. **State Notifier** - The `GameStateNotifier` processes these actions
4. **Immutable Updates** - New state is created through immutable operations via `copyWith()`
5. **State Propagation** - Updated state flows to listeners (UI, AI, etc.)

This approach ensures predictable state transitions and makes the game logic easily testable.

#### Dependency Injection

The library uses Riverpod for dependency injection, which provides:

- Lazy initialization of services
- Scoped providers for different game sessions
- Observable state for reactive updates
- Testability through provider overrides

#### Entity Component System (Partial)

Units and buildings implement a form of component-based design through:

- **Base Classes** - Generic functionality in base classes (`Unit`, `Building`)
- **Capabilities** - Discrete behaviors through composition (`CombatCapability`, `BuildingCapability`)
- **Interfaces** - Behavioral contracts via interfaces (`BuilderUnit`, `SettlerCapable`)

This allows for flexible unit designs without deep inheritance hierarchies.

### Technical Decisions

1. **Immutability** - All state changes produce new objects for predictable state management
2. **Extension Methods** - Used for enhancing base classes without modifying them
3. **Factory Pattern** - `UnitFactory` and `BuildingFactory` centralize entity creation
4. **Strategy Pattern** - Different behaviors encapsulated in capability classes
5. **Value Objects** - Simple value objects like `Position` for cleaner domain model
6. **Separation of Concerns** - Clear boundaries between map generation, unit management, etc.

## Usage Examples

### Initialize Game State

```dart
import 'package:game_core/game_core.dart';

// Create an initial game state
final gameStateNotifier = GameStateNotifier(ref);

// Initialize with custom settings
final initService = InitGameForGuiService(ref);
final success = initService.initMultiPlayerGame(
  playerNames: ["Player 1", "Player 2"],
  includeAI: true,
);
```

### Perform Game Actions

```dart
// Move a unit
ref.read(gameControllerProvider).moveUnit(unitId, newPosition);

// Build a structure
ref.read(gameControllerProvider).buildBuilding(buildingType, position);

// End the current turn
ref.read(gameControllerProvider).endTurn();
```

### Access Game State

```dart
// Access the current game state
final gameState = ref.watch(gameStateProvider);

// Get all units for the current player
final playerUnits = gameState.currentPlayerUnits;

// Get resources for a specific player
final resources = gameState.getPlayerResources(playerId);
```

## Integration With Frontend

The `game_core` library exposes several Riverpod providers that can be consumed by UI layers:

- `gameStateProvider` - The current game state
- `gameControllerProvider` - Methods to interact with the game
- `gameMapControllerProvider` - Camera and map-specific controls

These providers create a clean API boundary between the game logic and UI layers.

## Development Guidelines

When contributing to the `game_core` library:

1. Maintain immutability of state objects
2. Document public APIs thoroughly
3. Add unit tests for new functionality
4. Follow the existing architectural patterns
5. Avoid UI-specific code in this package

## Testing

The library has a comprehensive test suite to ensure game mechanics work correctly:

```bash
cd packages/game_core
flutter test
```

## License

This package is part of the main project and shares the same license.

## Usage
Add this package as a dependency in your `pubspec.yaml`:
```yaml
dependencies:
  game_core:
    path: ../packages/game_core
```

## Development
- Update or add new models/services in the appropriate subfolders.
- Run tests as needed (add test instructions if available).
