// Haupt-Export für alle Control Services
export 'game_controller.dart';
export 'player_control_service.dart';
export 'game_action_service.dart';
export 'game_state_service.dart';
export 'init_game_for_gui_service.dart';
export 'terminal_game_interface.dart';

/// Control Service Schicht für Flutter Sim City
/// 
/// Diese Schicht stellt eine abstrahierte API zwischen der UI und der Spiel-Engine zur Verfügung.
/// Sie kann sowohl von der Flutter UI als auch von einem Tensorflow Modell verwendet werden.
/// 
/// Hauptkomponenten:
/// 
/// - **GameController**: Haupt-API mit allen wichtigen Spielfunktionen
/// - **PlayerControlService**: Verwaltung von Spielern (Hinzufügen, Entfernen, etc.)
/// - **GameActionService**: Ausführung von Spielaktionen (Bewegen, Bauen, Angreifen, etc.)
/// - **GameStateService**: Zugriff auf Spielzustand und Speichern/Laden
/// - **InitGameForGuiService**: Vorkonfigurierte Spielinitialisierung für die GUI
/// - **TerminalGameInterface**: Text-basierte API für KI/Terminal Zugriff
/// 
/// Verwendung in der UI:
/// ```dart
/// final gameController = ref.read(gameControllerProvider);
/// gameController.addHumanPlayer("Player 1");
/// gameController.moveUnit("unit_1", Position(5, 5));
/// ```
/// 
/// Verwendung für KI/Terminal:
/// ```dart
/// final terminalInterface = ref.read(terminalGameInterfaceProvider);
/// print(terminalInterface.getGameStatus());
/// terminalInterface.moveUnit("unit_1", 5, 5);
/// ```
