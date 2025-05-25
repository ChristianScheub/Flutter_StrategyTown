import 'dart:math';
import 'package:game_core/src/models/buildings/building.dart';
import 'package:game_core/src/models/buildings/barracks.dart';
import 'package:game_core/src/models/buildings/city_center.dart';
import 'package:game_core/src/models/enemy_faction.dart';
import 'package:game_core/src/models/game/game_state.dart';
import 'package:game_core/src/models/resource/resource.dart';
import 'package:game_core/src/models/units/unit.dart';
import 'package:game_core/src/models/units/unit_factory.dart';
import 'package:game_core/src/services/score_service.dart';

/// Strategie für das Rekrutieren neuer Einheiten
class AIRecruitStrategy {
  final Random _random = Random();
  
  /// Führt die Rekrutierungsstrategie aus
  GameState execute(GameState state, EnemyFaction faction, double difficultyScale) {
    // 1. Analysiere die aktuelle Zusammensetzung der Armee und Bedürfnisse
    final currentMilitaryCount = faction.units.where((u) => u.isCombatUnit).length;
    final currentCivilianCount = faction.units.where((u) => !u.isCombatUnit).length;
    final currentFarmerCount = faction.units.where((u) => u.type == UnitType.farmer).length;
    final currentMinerCount = faction.units.where((u) => u.type == UnitType.miner).length;
    final currentLumberjackCount = faction.units.where((u) => u.type == UnitType.lumberjack).length;
    final currentTotal = faction.units.length;

    // Ressourcen analysieren
    final food = faction.resources.getAmount(ResourceType.food);
    final wood = faction.resources.getAmount(ResourceType.wood);
    final stone = faction.resources.getAmount(ResourceType.stone);

    // Ideale Zusammensetzung basierend auf der Spielphase und Ressourcen berechnen
    bool needMilitaryUnits = true;
    bool needResourceUnits = false;
    // Wenn Ressourcen knapp sind, priorisiere Resource-Units
    if (food < 30 || wood < 20 || stone < 15) {
      needResourceUnits = true;
      needMilitaryUnits = false;
    } else if (state.turn < 10) {
      needMilitaryUnits = currentMilitaryCount < currentCivilianCount;
    } else if (state.turn < 30) {
      needMilitaryUnits = currentMilitaryCount < currentCivilianCount * 1.5;
    } else {
      needMilitaryUnits = currentMilitaryCount < currentTotal * 0.7;
    }

    // 2. Wähle ein Gebäude zum Trainieren aus
    Building? trainingBuilding;
    UnitType unitToTrain = UnitType.soldierTroop;

    // Zuerst versuchen, den geeigneten Gebäudetyp basierend auf Bedürfnissen zu finden
    for (final building in faction.buildings) {
      if (needMilitaryUnits && building is Barracks) {
        trainingBuilding = building;
        final militaryTypes = [UnitType.knight, UnitType.soldierTroop, UnitType.archer];
        if (state.turn > 30 && _random.nextInt(10) < 7) {
          unitToTrain = UnitType.knight;
        } else {
          unitToTrain = militaryTypes[_random.nextInt(militaryTypes.length)];
        }
        break;
      } else if ((needResourceUnits || !needMilitaryUnits) && building is CityCenter) {
        trainingBuilding = building;
        // Priorisiere Farmer, Miner, Lumberjack wenn Ressourcen knapp
        final List<UnitType> resourceTypes = [];
        if (food < 30 && currentFarmerCount < 3) resourceTypes.add(UnitType.farmer);
        if (wood < 20 && currentLumberjackCount < 2) resourceTypes.add(UnitType.lumberjack);
        if (stone < 15 && currentMinerCount < 2) resourceTypes.add(UnitType.miner);
        // Wenn keine spezielle Ressourceneinheit benötigt wird, mische alle zivilen Typen
        final civilianTypes = [UnitType.settler, UnitType.farmer, UnitType.commander, UnitType.lumberjack, UnitType.miner];
        if (resourceTypes.isNotEmpty) {
          unitToTrain = resourceTypes[_random.nextInt(resourceTypes.length)];
        } else if (state.turn > 20 && _random.nextInt(10) < 7) {
          unitToTrain = UnitType.settler;
        } else {
          unitToTrain = civilianTypes[_random.nextInt(civilianTypes.length)];
        }
        break;
      }
    }
    
    // Wenn wir das ideale Gebäude nicht finden konnten, verwende ein beliebiges verfügbares
    if (trainingBuilding == null) {
      for (final building in faction.buildings) {
        if (building is CityCenter) {
          trainingBuilding = building;
          
          // Bestimme eine zufällige Zivileinheit
          final civilianTypes = [UnitType.settler, UnitType.farmer, UnitType.commander];
          unitToTrain = civilianTypes[_random.nextInt(civilianTypes.length)];
          break;
        } else if (building is Barracks) {
          trainingBuilding = building;
          
          // Bestimme eine zufällige Kampfeinheit
          final militaryTypes = [UnitType.knight, UnitType.soldierTroop, UnitType.archer];
          unitToTrain = militaryTypes[_random.nextInt(militaryTypes.length)];
          break;
        }
      }
    }
    
    // 3. Wenn kein geeignetes Gebäude gefunden wurde, können wir nicht rekrutieren
    if (trainingBuilding == null) {
      print("KI kann keine Einheit rekrutieren: Kein geeignetes Gebäude gefunden");
      return state.copyWith(enemyFaction: faction); // Kein Update notwendig
    }
    
    // 4. Prüfen, ob genug Ressourcen vorhanden sind
    int foodCost = UnitFactory.getUnitFoodCost(unitToTrain);
    
    if (!faction.resources.hasEnough(ResourceType.food, foodCost)) {
      print("KI kann keine Einheit rekrutieren: Nicht genug Nahrung (${faction.resources.getAmount(ResourceType.food)}/$foodCost)");
      return state.copyWith(enemyFaction: faction);
    }
    
    // 5. Erstelle die neue Einheit mit aktuellem Rundenzähler und AI player ID
    final newUnit = UnitFactory.createUnit(
      unitToTrain, 
      trainingBuilding.position, 
      ownerID: "ai1",
      currentTurn: state.turn
    );
    
    // 6. Aktualisiere Ressourcen
    final newResources = faction.resources.subtract(ResourceType.food, foodCost);
    
    // 7. Aktualisiere Fraktionsdaten
    final updatedFaction = faction.copyWith(
      units: [...faction.units, newUnit],
      resources: newResources,
      currentStrategy: faction.currentStrategy, // Strategy beibehalten
    );
    
    // Debug-Ausgabe
    print("KI hat ${newUnit.type} an Position (${trainingBuilding.position.x}, ${trainingBuilding.position.y}) rekrutiert");
    
    // Aktualisiere den Spielzustand mit der neuen Fraktion und den Punkten für AI player
    return ScoreService.addUnitTrainingPoints(
      state.copyWith(enemyFaction: updatedFaction),
      "ai1"
    );
  }
}
