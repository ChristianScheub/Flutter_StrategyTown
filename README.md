# Strategy Simulation Game Project

A comprehensive turn-based strategy simulation game built with Flutter, featuring modular architecture, multiplayer capabilities, and an AI opponent system.

## Project Overview

This repository contains a sophisticated Flutter-based strategy simulation game with a modular architecture:

- `flutter_app/` - The main Flutter frontend application providing the game UI
- `backend_service/` - Multiplayer backend server with REST API support
- `packages/game_core/` - Core game engine with shared logic, models, and simulation mechanics

## Architecture Highlights

The project uses a modern, modular architecture that separates concerns across multiple layers:

- **Presentation Layer** - Flutter UI components in `flutter_app/`
- **Game Logic Layer** - Core simulation mechanics in `packages/game_core/`
- **Backend Services** - Multiplayer and persistence in `backend_service/`
- **Data Layer** - Shared models and data structures throughout

### Key Architectural Patterns

1. **Modular Monolith** - Organized as separate modules that can evolve independently
2. **Event-Driven** - State updates propagate through Riverpod providers
3. **Domain-Driven Design** - Game entities and models follow DDD principles
4. **Repository Pattern** - Clean separation between data sources and business logic
5. **Provider-Based State Management** - Using Riverpod for reactive state management

## Directory Structure
- `flutter_app/` - Flutter UI application
- `backend_service/` - Backend server for multiplayer support
- `packages/game_core/` - Core game engine library
- `assets/` - Shared images and static assets
- `BACKEND_API.md` - Backend API documentation
- `REFACTORING_SUMMARY.md` - Notes on project refactoring

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://your-repository-url.git
   cd project-directory
   ```

2. Install dependencies for all modules:
   ```bash
   # Core library
   cd packages/game_core
   flutter pub get
   
   # Flutter app
   cd ../../flutter_app
   flutter pub get
   
   # Backend (if needed)
   cd ../backend_service
   dart pub get
   ```

3. Start the backend server (for multiplayer):
   ```bash
   cd backend_service
   ./run_server.sh
   ```

4. Launch the Flutter app:
   ```bash
   cd ../flutter_app
   flutter run
   ```

See individual READMEs in each directory for more detailed instructions and information.

## Development Guidelines

- Keep code organized in the appropriate modules
- Use Riverpod for state management
- Follow the established architectural patterns
- Write tests for critical functionality
- Update documentation when making significant changes

# Flutter Simulation Game

A strategy simulation game built with Flutter, featuring a robust object-oriented architecture.

## Description

This project is a turn-based simulation game inspired by classics like Civilization. Players can build cities, manage resources, train units, and develop their empire.

## Architecture

The project uses a well-structured object-oriented architecture with interfaces and the following key elements:

### Interfaces

Unit abilities are defined through interfaces:

- **BuilderUnit** - For units that can build structures
- **CombatCapable** - For units with combat abilities
- **HarvesterUnit** - For units that gather resources
- **SettlerCapable** - For units that can found cities

### Base Classes

Units are organized into a class hierarchy:

- **Unit** - Base class for all units
  - **CivilianUnit** - Non-combat units (extends Unit)
  - **MilitaryUnit** - Combat units (extends Unit, implements CombatCapable)

### Design Patterns

The project implements several design patterns:

- **Factory Pattern** - UnitFactory creates different types of units
- **Strategy Pattern** - Different unit behaviors are encapsulated in interfaces
- **State Pattern** - GameState manages the overall game state

## Key Features

- **Resource Management** - Collect and manage wood, food, stone, and iron
- **City Building** - Found cities and construct buildings
- **Unit Training** - Train different types of units with unique abilities
- **Turn-Based Gameplay** - Plan your moves carefully in a turn-based system

## Game Units

### Civilian Units
- **Settler** - Founds new cities
- **Farmer** - Builds farms and harvests food
- **Lumberjack** - Builds lumber camps and harvests wood
- **Miner** - Builds mines and harvests stone/iron

### Military Units
- **Commander** - Can build barracks and lead other units
- **Knight** - Powerful cavalry unit with high attack
- **Archer** - Ranged unit with special attack capabilities
- **Soldier Troop** - Basic combat unit with defensive bonuses

## Building Types
- **City Center** - Trains civilian units
- **Farm** - Produces food
- **Lumber Camp** - Produces wood
- **Mine** - Produces stone or iron
- **Barracks** - Trains military units

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── unit_abilities.dart   # Interface definitions
│   ├── unit_base_classes.dart # Base class definitions
│   ├── unit_factory.dart     # Factory for creating units
│   └── units/                # Unit implementations
├── screens/                  # UI screens
├── services/                 # Game logic and state management
└── widgets/                  # Reusable UI components
```
