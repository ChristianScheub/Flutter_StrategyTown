import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/src/services/controlService/control_service.dart';

/// Beispiel für die Verwendung der Terminal Game Interface
/// Diese Klasse zeigt, wie ein Tensorflow Modell oder andere KI-Systeme 
/// das Spiel über die Control Service Schicht steuern könnten
class TerminalGameExample {
  final Ref _ref;
  
  TerminalGameExample(this._ref);
  
  /// Startet ein Beispielspiel über die Terminal-Schnittstelle
  Future<void> runTerminalGameExample() async {
    print('=== Terminal Game Interface Example ===\n');
    
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    final initService = _ref.read(initGameForGuiServiceProvider);
    
    // 1. Spiel initialisieren
    print('1. Initializing game...');
    final gameInitialized = initService.initSinglePlayerGame(
      humanPlayerName: "Terminal Player",
      aiPlayerName: "Terminal AI",
    );
    
    if (!gameInitialized) {
      print('Failed to initialize game');
      return;
    }
    
    print('Game initialized successfully\n');
    
    // 2. Spielstatus anzeigen
    print('2. Game Status:');
    print(terminalInterface.getGameStatus());
    print('');
    
    // 3. Verfügbare Aktionen anzeigen
    print('3. Available Actions:');
    print(terminalInterface.getAvailableActions());
    print('');
    
    // 4. Spieler-Einheiten auflisten
    print('4. Player Units:');
    print(terminalInterface.listPlayerUnits());
    print('');
    
    // 5. Spieler-Gebäude auflisten
    print('5. Player Buildings:');
    print(terminalInterface.listPlayerBuildings());
    print('');
    
    // 6. Beispiel-Aktionen ausführen
    print('6. Executing sample actions...');
    
    // Erste Einheit auswählen (falls vorhanden)
    final gameController = _ref.read(gameControllerProvider);
    final units = gameController.playerUnits;
    
    if (units.isNotEmpty) {
      final firstUnit = units.first;
      print(terminalInterface.selectUnit(firstUnit.id));
      
      // Einheit bewegen
      final newX = firstUnit.position.x + 1;
      final newY = firstUnit.position.y;
      print(terminalInterface.moveUnit(firstUnit.id, newX, newY));
    }
    
    // Zug beenden
    print(terminalInterface.endTurn());
    print('');
    
    // 7. Neuer Spielstatus nach Aktionen
    print('7. Game Status After Actions:');
    print(terminalInterface.getGameStatus());
    print('');
    
    print('=== Terminal Game Example Completed ===');
  }
  
  /// Simuliert einen einfachen KI-Spielzug über die Terminal-Schnittstelle
  Future<void> simulateAITurn() async {
    print('=== Simulating AI Turn ===\n');
    
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    final gameController = _ref.read(gameControllerProvider);
    
    // 1. Aktuelle Situation analysieren
    print('Analyzing current situation...');
    print(terminalInterface.getGameStatus());
    
    final playerUnits = gameController.playerUnits;
    final enemyUnits = gameController.enemyUnits;
    
    // 2. Strategie-Entscheidung (vereinfacht)
    if (playerUnits.isNotEmpty && enemyUnits.isNotEmpty) {
      print('\nStrategy: Attack nearest enemy');
      
      final attackerUnit = playerUnits.first;
      final targetEnemy = enemyUnits.first;
      
      print(terminalInterface.selectUnit(attackerUnit.id));
      print(terminalInterface.attackTarget(
        attackerUnit.id, 
        targetEnemy.position.x, 
        targetEnemy.position.y
      ));
    } else if (playerUnits.isNotEmpty) {
      print('\nStrategy: Explore and expand');
      
      final unit = playerUnits.first;
      final newX = unit.position.x + 2;
      final newY = unit.position.y + 1;
      
      print(terminalInterface.selectUnit(unit.id));
      print(terminalInterface.moveUnit(unit.id, newX, newY));
    }
    
    // 3. Zug beenden
    print('\nEnding AI turn...');
    print(terminalInterface.endTurn());
    
    print('\n=== AI Turn Completed ===');
  }
  
  /// Zeigt detaillierte Spielanalyse für Tensorflow Training
  Map<String, dynamic> getGameStateForTraining() {
    final gameController = _ref.read(gameControllerProvider);
    final terminalInterface = _ref.read(terminalGameInterfaceProvider);
    
    // Sammle alle relevanten Daten für Training
    return {
      'turn': gameController.currentTurn,
      'resources': gameController.playerResources,
      'playerUnits': gameController.playerUnits.map((unit) => {
        'id': unit.id,
        'type': unit.type.toString(),
        'position': {'x': unit.position.x, 'y': unit.position.y},
        'actionsLeft': unit.actionsLeft,
      }).toList(),
      'playerBuildings': gameController.playerBuildings.map((building) => {
        'id': building.id,
        'type': building.type.toString(),
        'position': {'x': building.position.x, 'y': building.position.y},
        'level': building.level,
      }).toList(),
      'enemyUnits': gameController.enemyUnits.map((unit) => {
        'id': unit.id,
        'type': unit.type.toString(),
        'position': {'x': unit.position.x, 'y': unit.position.y},
      }).toList(),
      'enemyBuildings': gameController.enemyBuildings.map((building) => {
        'id': building.id,
        'type': building.type.toString(),
        'position': {'x': building.position.x, 'y': building.position.y},
        'level': building.level,
      }).toList(),
      'gameStatus': terminalInterface.getGameStatus(),
      'availableActions': terminalInterface.getAvailableActions().split('\n'),
    };
  }
}

/// Provider für das Terminal Game Example
final terminalGameExampleProvider = Provider<TerminalGameExample>((ref) {
  return TerminalGameExample(ref);
});
