import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sim_city/models/units/unit_abilities.dart';
import 'package:flutter_sim_city/models/units/civilian/unit_base_classes.dart';
import 'package:flutter_sim_city/models/units/civilian/farmer.dart';
import 'package:flutter_sim_city/models/units/civilian/lumberjack.dart';
import 'package:flutter_sim_city/models/units/civilian/miner.dart';
import 'package:flutter_sim_city/models/units/civilian/settler.dart';
import 'package:flutter_sim_city/models/units/military/archer.dart';
import 'package:flutter_sim_city/models/units/military/knight.dart';
import 'package:flutter_sim_city/models/units/military/soldier_troop.dart';
import 'package:flutter_sim_city/models/map/position.dart';
import 'package:flutter_sim_city/models/map/tile.dart';
import 'package:flutter_sim_city/models/buildings/building.dart';
import 'package:flutter_sim_city/models/resource/resource.dart';

void main() {
  group('Unit Abilities Tests', () {
    test('Farmer implements BuilderUnit and HarvesterUnit interfaces', () {
      final farmer = Farmer.create(Position(x: 0, y: 0));
      
      expect(farmer is BuilderUnit, true);
      expect(farmer is HarvesterUnit, true);
      expect(farmer is CivilianUnit, true);
      expect(farmer is CombatCapable, false);
    });
    
    
    test('Miner implements BuilderUnit and HarvesterUnit interfaces', () {
      final miner = Miner.create(Position(x: 0, y: 0));
      
      expect(miner is BuilderUnit, true);
      expect(miner is HarvesterUnit, true);
      expect(miner is CivilianUnit, true);
      expect(miner is CombatCapable, false);
    });
    
    test('Settler implements SettlerCapable interface', () {
      final settler = Settler.create(Position(x: 0, y: 0));
      
      expect(settler is SettlerCapable, true);
      expect(settler is CivilianUnit, true);
      expect(settler is CombatCapable, false);
    });
    
    
    test('Miner can only build mines', () {
      final miner = Miner.create(Position(x: 0, y: 0));
      final tile = Tile(
        position: Position(x: 0, y: 0),
        type: TileType.mountain,
        resourceType: ResourceType.stone,
        resourceAmount: 100,
      );
      
      expect(miner.canBuild(BuildingType.mine, tile), true);
      expect(miner.canBuild(BuildingType.farm, tile), false);
      expect(miner.canBuild(BuildingType.lumberCamp, tile), false);
      expect(miner.canBuild(BuildingType.barracks, tile), false);
    });
    
    test('Farmer can only build farms', () {
      final farmer = Farmer.create(Position(x: 0, y: 0));
      final tile = Tile(
        position: Position(x: 0, y: 0),
        type: TileType.grass,
      );
      
      expect(farmer.canBuild(BuildingType.farm, tile), true);
      expect(farmer.canBuild(BuildingType.mine, tile), false);
      expect(farmer.canBuild(BuildingType.lumberCamp, tile), false);
      expect(farmer.canBuild(BuildingType.barracks, tile), false);
    });
  });
}
