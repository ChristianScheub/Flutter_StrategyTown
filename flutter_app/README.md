# Flutter Application

## Overview

The `flutter_app` module serves as the main user interface and presentation layer for our strategy simulation game. It implements a modern, responsive UI that brings the game's mechanics to life through intuitive controls, smooth animations, and visually appealing game elements.

This Flutter application is specifically designed to showcase the gameplay provided by the `game_core` library while providing an engaging user experience across different devices and screen sizes. The UI is built with a focus on usability, visual appeal, and performance.

## Key Features

- **Interactive Game Map** - Panning, zooming, and selection mechanics
- **Resource Management Interface** - Visual display of all player resources
- **Building and Unit Controls** - Intuitive UI for game actions
- **Turn-Based Flow UI** - Clear indication of turn progression
- **Multiplayer Management** - Player switching and management interfaces
- **Save/Load System** - UI for game persistence
- **Settings and Configuration** - Game preferences and options
- **Responsive Design** - Support for different screen sizes and orientations

## Architecture

The Flutter application follows an architecture that emphasizes separation of concerns, testability, and maintainability:

### Module Structure

```
lib/
├── main.dart              # Application entry point
├── screens/               # Top-level screens
│   ├── game_screen.dart   # Main game interface
│   ├── home_screen.dart   # Initial navigation/menu
│   └── settings_screen.dart # Game configuration
├── services/              # App-specific services
│   ├── game_service.dart  # Bridge to game_core
│   ├── save_game_service.dart # UI for save/load operations
│   └── game/              # UI<->Core integration services
├── theme/                 # Visual styling
│   ├── app_theme.dart     # Theme definition
│   └── styles.dart        # Common styles
├── utils/                 # Helper utilities
│   ├── constants.dart     # App constants
│   └── formatters.dart    # Text/number formatting
└── widgets/               # Reusable UI components
    ├── game_map.dart      # Map rendering widget
    ├── resource_panel.dart # Resources display
    ├── turn_info_panel.dart # Turn information
    └── unified_action_panel.dart # Game actions UI
```

### Architectural Approach

The Flutter app implements a **Feature-Based Architecture** that combines aspects of several patterns:

#### UI Layer (Presentation)

1. **Screen Components** - High-level containers representing full screens
2. **Widget Components** - Reusable, composable UI elements
3. **Controllers** - Handle widget state and UI logic

#### Application Layer

1. **Services** - Handle business logic and coordinate with game_core
2. **Providers** - Manage state and dependency injection using Riverpod

#### Integration Layer

1. **Bridges** - Connect the UI to the game_core library
2. **Mappers** - Transform domain models to UI models when needed

### State Management Flow

The application uses Riverpod for state management with this flow:

1. **UI Events** - User interactions trigger actions
2. **Controllers/Notifiers** - Process these actions
3. **Game Core Integration** - Communicate with the game_core library
4. **State Updates** - New state flows back to UI through providers
5. **UI Rendering** - Widgets rebuild based on state changes

### Widget Composition

The UI is built through a composition approach:

- **Composition over Inheritance** - Widgets are composed from smaller widgets
- **Smart/Dumb Division** - Smart widgets handle logic, dumb widgets just render
- **Container/Presentational Pattern** - Logic separation from visual presentation

### Technical Implementation Details

1. **Flutter's Canvas API** - Custom painting for the game map
2. **Gesture Recognition** - Custom gesture detectors for map interaction
3. **Animation Framework** - Implicit and explicit animations for smooth transitions
4. **Responsive Layout** - Flexible layouts using MediaQuery and LayoutBuilder
5. **Theme Management** - Consistent visual styling through ThemeData

## Integration with Game Core

The Flutter app integrates with the game_core package through several mechanisms:

### Provider Integration

```dart
// Make game_core providers available in the Flutter app
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier(ref);
});

// UI-specific providers that consume game_core state
final selectedUnitUIProvider = Provider<UnitUIModel?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  final selectedUnit = gameState.selectedUnit;
  if (selectedUnit == null) return null;
  return UnitUIModel.fromDomain(selectedUnit);
});
```

### Service Wrappers

```dart
class GameService {
  final GameController _controller;
  
  void moveUnitWithAnimation(String unitId, Position position) {
    // UI-specific logic before delegating to game_core
    _controller.moveUnit(unitId, position);
    // UI-specific logic after the action (animations, sounds, etc.)
  }
}
```

## UI/UX Design Principles

The application follows these key UI/UX principles:

1. **Immediate Feedback** - Visual and audio feedback for all user actions
2. **Progressive Disclosure** - Complex mechanics revealed gradually
3. **Consistent Mental Model** - Game elements behave consistently
4. **Error Prevention** - Invalid actions are prevented or clearly marked
5. **Undo/Redo** - Where possible, actions can be undone
6. **Accessibility** - Support for different input methods and screen readers

## Getting Started

To run the Flutter application:

```bash
# Navigate to the app directory
cd flutter_app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Requirements

- Flutter SDK 3.0.0 or higher
- Dart 2.17.0 or higher
- Dependencies listed in pubspec.yaml

## Development Guidelines

When working on the Flutter app:

1. Follow the Flutter style guide
2. Maintain separation between UI and game logic
3. Keep widgets focused on a single responsibility
4. Use named constructors for widget variations
5. Document complex widgets and logic
6. Write widget tests for critical UI components

## Testing

The application includes several types of tests:

```bash
# Run widget tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## Performance Considerations

- **Widget Rebuilds** - Minimize through judicious use of const and selective rebuilding
- **Canvas Rendering** - Optimize game map rendering for smooth performance
- **Memory Management** - Properly dispose controllers and animations

## License

This Flutter application is part of the main project and shares the same license.
- `ios/` - iOS project files
- `web/` - Web build files
- `test/` - Unit and widget tests

## Getting Started
1. Install dependencies:
   ```sh
   flutter pub get
   ```
2. Run the app:
   ```sh
   flutter run
   ```

## Notes
- Make sure to configure your backend endpoint in the appropriate service files.
