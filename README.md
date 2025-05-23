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
