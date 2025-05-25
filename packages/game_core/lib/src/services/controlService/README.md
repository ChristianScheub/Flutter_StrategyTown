# Control Service Schicht

Diese Schicht stellt eine abstrahierte API zwischen der UI und der Spiel-Engine zur Verfügung. Sie kann sowohl von der Flutter UI als auch von einem Tensorflow Modell oder anderen KI-Systemen verwendet werden.

## Architektur

```
┌─────────────────┐    ┌─────────────────┐
│   Flutter UI    │    │ Tensorflow/KI   │
└─────────────────┘    └─────────────────┘
         │                        │
         └──────────┬──────────────┘
                    │
         ┌─────────────────┐
         │ Control Service │
         │     Schicht     │
         └─────────────────┘
                    │
         ┌─────────────────┐
         │  Spiel Engine   │
         │ (GameStateNoti- │
         │    fier etc.)   │
         └─────────────────┘
```

## Komponenten

### 1. GameController (`game_controller.dart`)
**Zeilen: 220**  
Haupt-API mit allen wichtigen Spielfunktionen. Stellt eine einheitliche Schnittstelle für:
- Spielerzustand-Zugriff (Ressourcen, Einheiten, Gebäude)
- Spieler-Management (Human/AI-Spieler hinzufügen/entfernen)
- Spielaktionen (Auswahl, Bewegung, Bau, Training, Angriff)
- Navigation (Kamera-Bewegung, Sprung zu Städten/Gegner)
- Spezifische Gebäude-Bauaktionen
- Spiel-Management (Speichern/Laden, Neue Spiele starten)

### 2. PlayerControlService (`player_control_service.dart`)
**Zeilen: 118**  
Verwaltung von Spielern:
- `addHumanPlayer()` - Fügt menschlichen Spieler hinzu
- `addAIPlayer()` - Fügt KI-Spieler hinzu
- `removePlayer()` - Entfernt Spieler
- `getAllPlayerIds()` - Holt alle Spieler-IDs

### 3. GameActionService (`game_action_service.dart`)
**Zeilen: 116**  
Ausführung von Spielaktionen:
- `selectUnit()` / `selectBuilding()` - Auswahl
- `moveUnit()` - Einheit bewegen
- `buildBuilding()` - Gebäude bauen
- `trainUnit()` - Einheit trainieren
- `attackTarget()` - Angriff
- `endTurn()` - Zug beenden

### 4. GameStateService (`game_state_service.dart`)
**Zeilen: 119**  
Zugriff auf Spielzustand:
- `getPlayerResources()` - Ressourcen abrufen
- `getPlayerUnits()` / `getEnemyUnits()` - Einheiten abrufen
- `hasEnoughResources()` - Ressourcen prüfen
- `saveGame()` / `loadGame()` - Speichern/Laden

### 5. InitGameForGuiService (`init_game_for_gui_service.dart`)
**Zeilen: 117**  
Vorkonfigurierte Spielinitialisierung:
- `initSinglePlayerGame()` - Einzelspieler-Spiel
- `initMultiPlayerGame()` - Mehrspieler-Spiel
- `initAITestGame()` - KI-Test-Spiel
- `initCustomGame()` - Benutzerdefiniertes Spiel

### 6. TerminalGameInterface (`terminal_game_interface.dart`)
**Zeilen: 232**  
Text-basierte API für KI/Terminal-Zugriff:
- `getGameStatus()` - Spielstatus als String
- `getAvailableActions()` - Verfügbare Aktionen auflisten
- `listPlayerUnits()` / `listEnemyUnits()` - Einheiten als Text
- `listPlayerBuildings()` / `listEnemyBuildings()` - Gebäude als Text
- String-basierte Aktions-Methoden für KI-Integration
- Vereinfachte Parameter (String/Int statt komplexe Objekte)

## Verwendung

### In der Flutter UI:

```dart
// Spieler hinzufügen
final gameController = ref.read(gameControllerProvider);
gameController.addHumanPlayer("Player 1");
gameController.addAIPlayer("Computer");

// Spielaktionen
gameController.selectUnit("unit_1");
gameController.moveUnit("unit_1", Position(5, 5));
gameController.buildBuilding(BuildingType.farm, Position(3, 3));

// Spezifische Gebäude bauen
gameController.buildFarm();
gameController.buildBarracks();
gameController.buildDefensiveTower();

// Spezifische Gebäude mit bestimmten Einheiten bauen
gameController.buildFarmWithUnit("unit_1", Position(3, 3));
gameController.buildLumberCampWithUnit("unit_2", Position(4, 4));
gameController.buildMineWithUnit("unit_3", Position(5, 5));
gameController.buildBarracksWithUnit("unit_4", Position(6, 6));
gameController.buildDefensiveTowerWithUnit("unit_5", Position(7, 7));
gameController.buildWallWithUnit("unit_6", Position(8, 8));

// Navigation
gameController.jumpToFirstCity();
gameController.jumpToEnemyHeadquarters();

// Zug beenden
gameController.endTurn();

// Spiel-Management
await gameController.saveGame(saveName: "My Save");
```

### Für Tensorflow/KI:

```dart
// Terminal Interface verwenden
final terminalInterface = ref.read(terminalGameInterfaceProvider);

// Spielstatus abrufen
String status = terminalInterface.getGameStatus();
String detailedStatus = terminalInterface.getDetailedGameStatus();
String actions = terminalInterface.getAvailableActions();

// Aktionen ausführen
terminalInterface.moveUnit("unit_1", 5, 5);
terminalInterface.attackTarget("warrior_1", 10, 10);
terminalInterface.foundCity();
terminalInterface.buildFarm();
terminalInterface.endTurn();

// Kommando-String-Verarbeitung für KI
String result = terminalInterface.processCommand("move_unit settler_1 3 4");
String result2 = terminalInterface.processCommand("build farm 5 5");
String result3 = terminalInterface.processCommand("end_turn");

// Spieler-Management
terminalInterface.addHumanPlayer("Human Player");
terminalInterface.addAIPlayer("AI Opponent");

// Spiel-Management
await terminalInterface.saveGame("AI_Training_Session_1");
await terminalInterface.loadGame("previous_session");
```

### Spiel initialisieren:

```dart
// Einzelspieler
final initService = ref.read(initGameForGuiServiceProvider);
initService.initSinglePlayerGame(
  humanPlayerName: "Player",
  aiPlayerName: "Computer AI"
);

// Mehrspieler
initService.initMultiPlayerGame(
  playerNames: ["Player 1", "Player 2"],
  includeAI: true
);
```

## Integration

### Bestehende UI ersetzen:
Ersetzen Sie direkte `GameStateNotifier` Calls durch Control Service:

```dart
// Alt:
ref.read(gameStateProvider.notifier).selectUnit(unitId);

// Neu:
ref.read(gameControllerProvider).selectUnit(unitId);
```

### Tensorflow Integration:
Die `TerminalGameInterface` bietet String-basierte Methoden, die einfach von Python/Tensorflow konsumiert werden können:

```python
# Beispiel Python Integration (konzeptionell)
def ai_play_turn(game_interface):
    # Spielstatus abrufen
    status = game_interface.get_detailed_status()
    units = game_interface.list_player_units()
    actions = game_interface.get_available_actions()
    
    # KI-Entscheidung treffen basierend auf String-Daten
    action = ai_model.decide_action(status, units, actions)
    
    # Aktion über String-Kommandos ausführen
    result = game_interface.process_command(action)
    
    # Zug beenden
    game_interface.process_command("end_turn")
    
    return result

# Beispiel-Kommandos für KI-Training:
commands = [
    "select_unit settler_1",
    "move_unit settler_1 5 5", 
    "found_city",
    "build_farm",
    "train_unit farmer barracks_1",
    "end_turn"
]

for cmd in commands:
    result = game_interface.process_command(cmd)
    print(f"Command: {cmd} -> Result: {result}")
```

### Erweiterte KI-Integration:

```python
# Vollständige KI-Session
class SimCityAI:
    def __init__(self, game_interface):
        self.interface = game_interface
        
    def setup_game(self):
        self.interface.process_command("start_new_game")
        self.interface.process_command("add_human_player TestPlayer")
        self.interface.process_command("add_ai_player AI_Opponent")
        
    def analyze_game_state(self):
        status = self.interface.process_command("get_detailed_status")
        units = self.interface.process_command("get_units")
        buildings = self.interface.process_command("get_buildings")
        enemies = self.interface.process_command("get_enemy_units")
        
        return {
            'status': status,
            'units': units, 
            'buildings': buildings,
            'enemies': enemies
        }
        
    def execute_strategy(self, strategy_commands):
        results = []
        for cmd in strategy_commands:
            result = self.interface.process_command(cmd)
            results.append(result)
        return results
```

## Vorteile

1. **Abstraktion**: UI ist vom Spiel-Code entkoppelt
2. **Einheitliche API**: Gleiche Schnittstelle für UI und KI
3. **Einfache Integration**: String-basierte Methoden für externe Systeme
4. **Kommando-Prozessor**: `processCommand()` ermöglicht direkten String-Input für KI
5. **Wartbarkeit**: Änderungen in der Spiel-Engine beeinflussen nicht die UI
6. **Testbarkeit**: Control Services können isoliert getestet werden
7. **Flexibilität**: Neue UIs oder KI-Systeme können einfach angeschlossen werden
8. **KI-Training**: Vollständige String-API für Machine Learning Integration
9. **Debugging**: Detaillierte Status-Informationen für Analyse
10. **Skalierbarkeit**: Spieler-Management für Multi-Agent-Systeme

## Implementierungs-Status ✅

**Vollständig implementiert:**
- ✅ GameController mit allen 30+ GUI-Funktionen 
- ✅ Vollständige String-basierte Terminal-API
- ✅ Kommando-Prozessor für KI-Integration
- ✅ Spieler-Management (Human/AI)
- ✅ Spiel-Verwaltung (Speichern/Laden/Neu)
- ✅ Navigation und Kamera-Steuerung
- ✅ Alle Gebäude-Bau-Aktionen
- ✅ Alle Einheiten-Training-Aktionen  
- ✅ Detaillierte Status-Abfragen
- ✅ Error-Handling und Validierung
- ✅ Migration von game_screen.dart abgeschlossen

**Migration Erfolg:**
- **Vorher**: Direkte `gameStateProvider.notifier` Aufrufe in UI
- **Nachher**: Saubere Abstraktion über GameController
- **Ergebnis**: 100% funktionale GUI + vollständige KI-API

## Nächste Schritte

1. **KI-Training Setup**: Python-Integration mit Terminal-Interface
2. **Multi-Agent-Training**: Mehrere KI-Spieler gleichzeitig
3. **Performance-Monitoring**: Spiel-Metriken für Training
4. **Erweiterte Befehle**: Batch-Kommandos und Makros
5. **Replay-System**: Spiel-Sessions für Analyse speichern

## Fazit

Die Control Service Schicht ist **vollständig funktional** und bietet:
- **100% GUI-Parität**: Alle Funktionen der ursprünglichen UI
- **KI-Ready**: String-basierte API für Machine Learning
- **Erweiterbar**: Neue Features einfach hinzufügbar
- **Wartbar**: Klare Trennung zwischen UI und Spiel-Logik
- **Testbar**: Isolierte Services für Unit-Tests

Die Implementierung ermöglicht nahtlose Integration von Tensorflow-Modellen und anderen KI-Systemen, während die bestehende Flutter-UI vollständig funktional bleibt.

## Dateistruktur

```
lib/services/controlService/
├── control_service.dart              # Index/Export file
├── game_controller.dart              # Haupt-API (220 Zeilen)
├── player_control_service.dart       # Spieler-Management (118 Zeilen)
├── game_action_service.dart          # Spielaktionen (116 Zeilen)
├── game_state_service.dart           # Spielzustand (119 Zeilen)
├── init_game_for_gui_service.dart    # Spiel-Initialisierung (117 Zeilen)
├── terminal_game_interface.dart      # Terminal/KI API (400+ Zeilen)
├── terminal_game_example.dart        # Beispiel für KI-Integration
├── game_screen_migration_helper.dart # UI-Migration Helper
└── README.md                         # Diese Dokumentation
```

**Neue Funktionen in v2.0:**
- **Erweiterte Terminal-API**: Alle GUI-Funktionen verfügbar als String-Kommandos
- **Kommando-Prozessor**: `processCommand()` für direkte String-Eingabe
- **Detaillierte Status-API**: `getDetailedGameStatus()` für umfassende Spiel-Analyse
- **Spieler-Management**: Vollständige Unterstützung für Human/AI-Spieler
- **Spiel-Verwaltung**: Speichern/Laden über Terminal-Interface
- **KI-Integration**: Optimiert für Machine Learning und Training

Alle Dateien implementieren die vollständige GUI-Funktionalität und bieten sowohl objekt-orientierte als auch string-basierte APIs.

## Vollständige API-Referenz

### GameController Methoden:
**Spiel-Zustand:**
- `currentGameState` - Aktueller Spielzustand
- `isGameActive` - Prüft ob Spiel läuft
- `currentTurn` - Aktuelle Rundenanzahl
- `playerResources` - Spieler-Ressourcen als Map
- `playerUnits` / `enemyUnits` - Listen der Einheiten
- `playerBuildings` / `enemyBuildings` - Listen der Gebäude

**Auswahl & Navigation:**
- `selectUnit(unitId)` - Einheit auswählen
- `selectBuilding(buildingId)` - Gebäude auswählen  
- `selectTile(position)` - Kachel auswählen
- `clearSelection()` - Auswahl aufheben
- `jumpToFirstCity()` - Zur ersten Stadt springen
- `jumpToEnemyHeadquarters()` - Zum Feind-HQ springen

**Aktionen:**
- `moveUnit(unitId, position)` - Einheit bewegen
- `attackTarget(unitId, position)` - Ziel angreifen
- `foundCity()` - Stadt gründen
- `harvestResource()` - Ressourcen ernten
- `upgradeBuilding()` - Gebäude verbessern

**Bauen:**
- `buildBuilding(type, position)` - Allgemeines Bauen
- `buildFarm()` / `buildLumberCamp()` / `buildMine()` - Spezifische Gebäude
- `buildBarracks()` / `buildDefensiveTower()` / `buildWall()` - Militärgebäude
- `selectBuildingToBuild(type)` - Gebäudetyp für Platzierung auswählen
- `buildBuildingAtPosition(position)` - An Position bauen

**Training:**
- `trainUnit(type, buildingId)` - Einheit trainieren
- `trainUnitGeneric(type)` - Allgemeines Training
- `selectUnitToTrain(type)` - Einheitentyp auswählen

**Spieler-Management:**
- `addHumanPlayer(name, [id])` - Menschlichen Spieler hinzufügen
- `addAIPlayer(name, [id])` - KI-Spieler hinzufügen
- `removePlayer(id)` - Spieler entfernen
- `getAllPlayerIds()` - Alle Spieler-IDs

**Spiel-Verwaltung:**
- `startNewGame()` - Neues Spiel starten
- `saveGame([name])` - Spiel speichern
- `loadGame(key)` - Spiel laden
- `endTurn()` - Zug beenden

### TerminalGameInterface String-Kommandos:
**Bewegung & Kampf:**
- `"move_unit <unitId> <x> <y>"` - Einheit bewegen
- `"attack <unitId> <x> <y>"` - Angreifen

**Auswahl:**
- `"select_unit <unitId>"` - Einheit auswählen
- `"select_building <buildingId>"` - Gebäude auswählen
- `"select_tile <x> <y>"` - Kachel auswählen
- `"clear_selection"` - Auswahl aufheben

**Bauen:**
- `"build <type> <x> <y>"` - Bauen an Position
- `"build_farm"` / `"build_mine"` / `"build_barracks"` - Schnell-Bau
- `"select_building_to_build <type>"` - Gebäudetyp auswählen
- `"build_at_position <x> <y>"` - An ausgewählter Position bauen

**Training:**
- `"train_unit <type> <buildingId>"` - Einheit trainieren
- `"train_generic <type>"` - Allgemeines Training
- `"select_unit_to_train <type>"` - Einheitentyp auswählen

**Aktionen:**
- `"found_city"` - Stadt gründen
- `"harvest"` - Ressourcen ernten
- `"upgrade_building"` - Gebäude verbessern
- `"end_turn"` - Zug beenden

**Navigation:**
- `"jump_to_first_city"` - Zur ersten Stadt
- `"jump_to_enemy_hq"` - Zum Feind-HQ

**Information:**
- `"get_status"` - Basis-Spielstatus
- `"get_detailed_status"` - Detaillierter Status
- `"get_units"` / `"get_buildings"` - Listen abrufen
- `"get_enemy_units"` / `"get_enemy_buildings"` - Feind-Listen
- `"get_actions"` - Verfügbare Kommandos
- `"help"` - Hilfe anzeigen

**Spieler & Spiel:**
- `"add_human_player <name> [id]"` - Menschlichen Spieler hinzufügen
- `"add_ai_player <name> [id]"` - KI-Spieler hinzufügen
- `"remove_player <id>"` - Spieler entfernen
- `"start_new_game"` - Neues Spiel

### Mehrspieler Funktionen

#### Spieler hinzufügen
```dart
// Menschlichen Spieler hinzufügen
gameController.addHumanPlayer("Player 1");

// KI-Spieler hinzufügen
gameController.addAIPlayer("Computer");
```

#### Spielerzug-Management
```dart
// Aktuelle Spielerinformationen
String currentPlayer = gameController.currentPlayerId;
bool isHuman = gameController.isCurrentPlayerHuman;
bool isAI = gameController.isCurrentPlayerAI;

// Spielerwechsel
gameController.switchToNextPlayer();  // Nächster Spieler
gameController.switchToPlayer("player_2");  // Bestimmter Spieler

// Spielerdaten abrufen
Map<String, int> resources = gameController.currentPlayerResources;
List<Unit> units = gameController.currentPlayerUnits;
List<Building> buildings = gameController.currentPlayerBuildings;
```

#### Terminal-Mehrspielerbefehle
```bash
# Spielerwechsel
switch_player                    # Nächster Spieler
switch_to_player human_player_1  # Zu bestimmtem Spieler wechseln

# Spielerinformationen
get_current_player               # Aktueller Spieler
list_all_players                 # Alle Spieler auflisten

# Spielerdaten abrufen
get_player_resources player_2    # Ressourcen eines Spielers
get_player_units player_2        # Einheiten eines Spielers 
get_player_buildings player_2    # Gebäude eines Spielers
```

### Spiel initialisieren:

#### Einzelspieler
```dart
final initService = ref.read(initGameForGuiServiceProvider);
initService.initSinglePlayerGame(
  humanPlayerName: "Player",
  aiPlayerName: "Computer AI"
);
```

#### Mehrspieler
```dart
// Mehrere menschliche Spieler
initService.initMultiPlayerGame(
  playerNames: ["Alice", "Bob", "Charlie"],
  includeAI: true,  // Optional KI-Gegner
  aiPlayerName: "Computer"
);

// Benutzerdefiniert mit KI/Human-Mix
initService.initCustomGame(
  playerConfigs: [
    PlayerConfig.human("Alice"),
    PlayerConfig.ai("Smart AI"),
    PlayerConfig.human("Bob"),
    PlayerConfig.ai("Aggressive AI"),
  ]
);
```

### Spielerzustand im GameState
```dart
// Neues currentPlayerId Feld für aktiven Spieler
class GameState {
  final String currentPlayerId;  // "player", "human_player_1", "ai_1", etc.
  
  // Mehrspielermethoden
  GameState switchToNextPlayer();
  GameState switchToPlayer(String playerId);
  
  // Aktuelle Spieler-Zugriffe  
  bool get isCurrentPlayerHuman;
  bool get isCurrentPlayerAI;
  Player? get currentPlayer;
  List<Unit> get currentPlayerUnits;
  List<Building> get currentPlayerBuildings;
  ResourcesCollection get currentPlayerResources;
}
```

## 🔄 **Migration von Legacy-Code**

Das System ist **rückwärtskompatibel**. Legacy-Code funktioniert weiterhin:

```dart
// ALT (funktioniert weiterhin):
List<Unit> units = gameController.playerUnits;          // Nutzt aktuellen Spieler
Map<String, int> resources = gameController.playerResources;  // Nutzt aktuellen Spieler

// NEU (explizit für Mehrspielerspiele):
List<Unit> units = gameController.currentPlayerUnits;   // Explizit aktueller Spieler
Map<String, int> resources = gameController.currentPlayerResources;
```

### Spiel initialisieren:

#### Einzelspieler
```dart
final initService = ref.read(initGameForGuiServiceProvider);
initService.initSinglePlayerGame(
  humanPlayerName: "Player",
  aiPlayerName: "Computer AI"
);
```

#### Mehrspieler
```dart
// Mehrere menschliche Spieler
initService.initMultiPlayerGame(
  playerNames: ["Alice", "Bob", "Charlie"],
  includeAI: true,  // Optional KI-Gegner
  aiPlayerName: "Computer"
);

// Benutzerdefiniert mit KI/Human-Mix
initService.initCustomGame(
  playerConfigs: [
    PlayerConfig.human("Alice"),
    PlayerConfig.ai("Smart AI"),
    PlayerConfig.human("Bob"),
    PlayerConfig.ai("Aggressive AI"),
  ]
);
```
