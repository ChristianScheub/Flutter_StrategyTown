#!/usr/bin/env python3
"""
Parameter generator for the game environment
"""

import random
from typing import Dict, List, Any

class ActionParameterGenerator:
    """Generates valid parameters for different action types"""
    
    def __init__(self, environment):
        """Initialize with a reference to the game environment"""
        self.env = environment
    
    def get_move_unit_params(self) -> Dict[str, Any]:
        """Generate parameters for moving a unit"""
        units = self.env.api_client.get_units().get("units", [])
        
        # Filter for the current player's units that can move
        player_units = [u for u in units if isinstance(u, dict) and u.get("ownerId") == self.env.player_id and u.get("movesLeft", 0) > 0]
        
        if not player_units:
            return {}
        
        # Choose a random unit
        unit = random.choice(player_units)
        unit_id = unit.get("id")
        
        # Get current position
        current_pos = unit.get("position", {})
        current_x = current_pos.get("x", 0)
        current_y = current_pos.get("y", 0)
        
        # Generate a valid move within range
        move_range = unit.get("moveRange", 1)
        delta_x = random.randint(-move_range, move_range)
        delta_y = random.randint(-move_range, move_range)
        
        new_x = max(0, min(self.env.MAP_SIZE_X - 1, current_x + delta_x))
        new_y = max(0, min(self.env.MAP_SIZE_Y - 1, current_y + delta_y))
        
        return {
            "unit_id": unit_id,
            "x": new_x,
            "y": new_y
        }
    
    def get_found_city_params(self) -> Dict[str, Any]:
        """Generate parameters for founding a city"""
        units = self.env.api_client.get_units().get("units", [])
        
        # Find settler units belonging to the current player
        settlers = [u for u in units 
                  if isinstance(u, dict) and u.get("ownerId") == self.env.player_id and u.get("type") == "settler"]
        
        if not settlers:
            return {}
        
        # Choose a random settler
        settler = random.choice(settlers)
        
        return {
            "unit_id": settler.get("id")
        }
    
    def get_build_params(self) -> Dict[str, Any]:
        """Generate parameters for building a structure"""
        units = self.env.api_client.get_units().get("units", [])
        
        # Find builder units belonging to the current player
        builders = [u for u in units 
                  if isinstance(u, dict) and u.get("ownerId") == self.env.player_id and 
                     u.get("type") in ["farmer", "lumberjack", "miner", "commander", "architect"]]
        
        if not builders:
            return {}
        
        # Choose a random builder
        unit = random.choice(builders)
        unit_id = unit.get("id")
        unit_type = unit.get("type")
        
        # Match builder type to building type
        building_type_map = {
            "farmer": "farm",
            "lumberjack": "lumberCamp",
            "miner": "mine",
            "commander": "barracks",
            "architect": ["defensiveTower", "wall"]
        }
        
        building_choices = building_type_map.get(unit_type, ["farm"])
        if isinstance(building_choices, list):
            building_type = random.choice(building_choices)
        else:
            building_type = building_choices
        
        # Get current position
        current_pos = unit.get("position", {})
        current_x = current_pos.get("x", 0)
        current_y = current_pos.get("y", 0)
        
        # Build near current position
        build_x = max(0, min(self.env.MAP_SIZE_X - 1, current_x + random.randint(-1, 1)))
        build_y = max(0, min(self.env.MAP_SIZE_Y - 1, current_y + random.randint(-1, 1)))
        
        return {
            "unit_id": unit_id,
            "building_type": building_type,
            "x": build_x,
            "y": build_y
        }
    
    def get_train_unit_params(self) -> Dict[str, Any]:
        """Generate parameters for training a unit"""
        buildings = self.env.api_client.get_buildings().get("buildings", [])
        
        # Find buildings belonging to the current player that can train units
        training_buildings = [b for b in buildings 
                           if isinstance(b, dict) and b.get("ownerId") == self.env.player_id and 
                              b.get("type") in ["city", "barracks"]]
        
        # If no suitable buildings, try generic training
        if not training_buildings:
            return {
                "unit_type": random.choice(self.env.UNIT_TYPES)
            }
        
        # Choose a random building
        building = random.choice(training_buildings)
        building_id = building.get("id")
        building_type = building.get("type")
        
        # Choose appropriate unit type based on building type
        unit_choices = {
            "city": ["settler", "farmer", "lumberjack", "miner", "architect"],
            "barracks": [ "archer", "knight", "commander"]
        }.get(building_type, ["settler"])
        
        unit_type = random.choice(unit_choices)
        
        return {
            "unit_type": unit_type,
            "building_id": building_id
        }
    
    def get_harvest_params(self) -> Dict[str, Any]:
        """Generate parameters for harvesting resources"""
        units = self.env.api_client.get_units().get("units", [])
        
        # Find resource gathering units
        harvesters = [u for u in units 
                   if isinstance(u, dict) and u.get("ownerId") == self.env.player_id and 
                      u.get("type") in ["farmer", "lumberjack", "miner"]]
        
        if not harvesters:
            return {}
        
        # Choose a random harvester
        harvester = random.choice(harvesters)
        
        return {
            "unit_id": harvester.get("id")
        }
    
    def get_upgrade_building_params(self) -> Dict[str, Any]:
        """Generate parameters for upgrading a building"""
        buildings = self.env.api_client.get_buildings().get("buildings", [])
        
        # Find upgradable buildings
        upgradable = [b for b in buildings 
                    if isinstance(b, dict) and b.get("ownerId") == self.env.player_id and 
                       b.get("level", 0) < b.get("maxLevel", 1)]
        
        if not upgradable:
            return {}
        
        # Choose a random building to upgrade
        building = random.choice(upgradable)
        
        return {
            "building_id": building.get("id")
        }
    
    def generate_params_for_action(self, action_type: int) -> Dict[str, Any]:
        """Generate appropriate parameters for the given action type"""
        param_generators = {
            self.env.ACTION_MOVE_UNIT: self.get_move_unit_params,
            self.env.ACTION_FOUND_CITY: self.get_found_city_params,
            self.env.ACTION_BUILD: self.get_build_params,
            self.env.ACTION_TRAIN_UNIT: self.get_train_unit_params,
            self.env.ACTION_HARVEST: self.get_harvest_params,
            self.env.ACTION_UPGRADE_BUILDING: self.get_upgrade_building_params,
            self.env.ACTION_END_TURN: lambda: {}  # No params needed for end turn
        }
        
        generator = param_generators.get(action_type, lambda: {})
        return generator()
