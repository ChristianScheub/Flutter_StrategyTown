#!/usr/bin/env python3
"""
Environment for Game API - Provides an interface for rein        # Get initial state
        try:
            state = self._get_state()
            self.current_score = self._get_player_score()
            self.previous_score = self.current_score
            self.idle_turns = 0
            
            return state
        except Exception as e:
            logger.error(f"Error during reset: {e}")
            raise RuntimeError("Failed to reset environment") from ent learning agents
"""

import json
import numpy as np
import logging
import time
from typing import Dict, List, Tuple, Any, Optional
from game_api_client import GameApiClient

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class GameEnvironment:
    """Environment wrapper for the game API to be used with reinforcement learning agents"""
    
    # Map size constants
    MAP_SIZE_X = 50
    MAP_SIZE_Y = 50
    MAP_VIEW_RADIUS = 10
    
    # State observation window size
    STATE_WINDOW_SIZE = 20  # Observe 20x20 area around units
    
    # Game limits
    MAX_ROUNDS = 500
    IDLE_TURN_PENALTY = -5.0
    
    # Unit ranges
    UNIT_VISION_RANGE = 5
    COMBAT_RANGE = {
        "archer": 3,  
        "knight": 1,
        "defensiveTower": 4
    }
    
    # Action space definitions  
    ACTION_MOVE_UNIT = 0
    ACTION_FOUND_CITY = 1
    ACTION_BUILD = 2
    ACTION_TRAIN_UNIT = 3
    ACTION_HARVEST = 4
    ACTION_UPGRADE_BUILDING = 5
    ACTION_ATTACK = 6
    ACTION_END_TURN = 7
    
    # Building types 
    BUILDING_TYPES = ["cityCenter", "farm", "lumberCamp", "mine", "barracks", "defensiveTower", "wall"]
    
    # Unit types
    UNIT_TYPES = ["settler", "archer", "knight", "farmer", "lumberjack", "miner", "commander", "architect"]
    
    # Terrain types
    TERRAIN_TYPES = ["grass", "water", "mountain", "forest"]
    
    # Resource types
    RESOURCE_TYPES = ["food", "wood", "stone", "iron"]

    def __init__(self, player_name: str = "AI_Agent", max_api_calls_per_turn: int = 20):
        """Initialize the game environment"""
        self.api_client = GameApiClient()
        self.player_name = player_name
        self.player_id = None
        self.current_score = 0
        self.previous_score = 0
        self.idle_turns = 0
        self.turn_counter = 0
        self.last_action_time = time.time()
        
        # AI Turn Management
        self.max_api_calls_per_turn = max_api_calls_per_turn
        self.current_api_calls = 0
        self.current_ai_index = 0
        self.ai_players = []  # List of AI player IDs
        self.round_counter = 0
        
        # Performance Monitoring
        self.api_call_history = []
        self.performance_stats = {
            'total_api_calls': 0,
            'average_calls_per_turn': 0
        }
        
        # Initialize map state matrices
        self.terrain_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.int8)
        self.resource_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.int8)
        self.unit_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.int8)
        self.building_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.int8)
        self.visibility_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.bool_)
        self.combat_influence_map = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.float32)

    def _init_maps(self):
        """Initialize the map matrices with terrain and resource data"""
        try:
            # Get initial map data
            map_data = self.api_client.get_area_map(0, 0, max(self.MAP_SIZE_X, self.MAP_SIZE_Y))
            
            if isinstance(map_data, dict):
                tiles = map_data.get("tiles", [])
                for tile in tiles:
                    x = tile.get("x", 0)
                    y = tile.get("y", 0)
                    if 0 <= x < self.MAP_SIZE_X and 0 <= y < self.MAP_SIZE_Y:
                        # Set terrain type
                        self.terrain_map[y,x] = self._get_terrain_type_id(tile.get("type", "grass"))
                        
                        # Set resource type if present
                        resource_type = tile.get("resourceType")
                        if resource_type:
                            self.resource_map[y,x] = self._get_resource_type_id(resource_type)
                            
        except Exception as e:
            logger.error(f"Error initializing maps: {e}")
            return False
        
        return True

    def setup_game(self, num_players: int = 5) -> bool:
        """Setup a new game with all Python agents as human players (no backend AI)"""
        try:
            # Start a new game
            result = self.api_client.start_new_game()
            if not result.get("success", False):
                logger.error(f"Failed to start a new game: {result}")
                return False

            # Add all RL agents as human players
            self.agent_names = [f"RL_Agent_{i+1}" for i in range(num_players)]
            for agent_name in self.agent_names:
                result = self.api_client.add_human_player(agent_name)
                if not result.get("success", False):
                    logger.error(f"Failed to add RL agent as human player '{agent_name}': {result}")
                    return False
                logger.info(f"Added RL agent as human player: {agent_name}")

            # Collect all players and set up turn management
            if not self._collect_players():
                logger.error("Failed to collect players for turn management")
                return False

            logger.info(f"Game setup complete with {len(self.ai_players)} RL agents (all as human players)")
            return True

        except Exception as e:
            logger.error(f"Failed to setup game: {e}")
            return False
    
    def reset(self) -> np.ndarray:
        """Reset the environment and return the initial state"""
        # Start a new game and add players
        if not self.setup_game():
            raise RuntimeError("Failed to reset the environment")
        
        # Initialize map matrices
        if not self._init_maps():
            raise RuntimeError("Failed to initialize map state")
        
        # Get the initial state
        state = self._get_state()
        self.current_score = self._get_player_score()
        self.previous_score = self.current_score
        self.idle_turns = 0
        self.turn_counter = 0
        
        return state
    
    def step(self, action: int, action_params: Dict[str, Any] = None) -> Tuple[np.ndarray, float, bool, Dict]:
        """Execute an action and return the next state, reward, done flag, and info"""
        if action_params is None:
            action_params = {}
        
        # Check if we should switch to next AI before taking action
        if self._should_switch_ai():
            if not self._switch_to_next_ai():
                logger.error("Failed to switch to next AI")
                # Continue with current AI to avoid getting stuck
        
        # Track whether any successful action was taken
        action_taken = False
        
        # Execute the selected action and track API calls
        if action == self.ACTION_MOVE_UNIT:
            if 'unit_id' in action_params and 'x' in action_params and 'y' in action_params:
                if self._track_api_call('move_unit'):
                    result = self.api_client.move_unit(
                        action_params['unit_id'], 
                        action_params['x'], 
                        action_params['y']
                    )
                    action_taken = result.get("success", False)
                
        elif action == self.ACTION_FOUND_CITY:
            if 'unit_id' in action_params:
                if self._track_api_call('found_city_with_unit'):
                    result = self.api_client.found_city_with_unit(action_params['unit_id'])
                    action_taken = result.get("success", False)
                
        elif action == self.ACTION_BUILD:
            if all(k in action_params for k in ['unit_id', 'building_type', 'x', 'y']):
                if self._track_api_call('build_with_unit'):
                    result = self.api_client.build_with_unit(
                        action_params['unit_id'],
                        action_params['building_type'],
                        action_params['x'],
                        action_params['y']
                    )
                    action_taken = result.get("success", False)
                
        elif action == self.ACTION_TRAIN_UNIT:
            if all(k in action_params for k in ['unit_type', 'building_id']):
                if self._track_api_call('train_unit'):
                    result = self.api_client.train_unit(
                        action_params['unit_type'],
                        action_params['building_id']
                    )
                    # Handle both dict and string responses
                    if isinstance(result, dict):
                        action_taken = result.get("success", False)
                    else:
                        # If it's a string, assume it's an error or success message
                        action_taken = "success" in str(result).lower()
                
        elif action == self.ACTION_HARVEST:
            if 'unit_id' in action_params:
                if self._track_api_call('select_unit'):
                    self.api_client.select_unit(action_params['unit_id'])
                if self._track_api_call('harvest_resource'):
                    result = self.api_client.harvest_resource()
                    # Handle both dict and string responses
                    if isinstance(result, dict):
                        action_taken = result.get("success", False)
                    else:
                        action_taken = "success" in str(result).lower()
                
        elif action == self.ACTION_UPGRADE_BUILDING:
            if 'building_id' in action_params:
                if self._track_api_call('select_building'):
                    self.api_client.select_building(action_params['building_id'])
                if self._track_api_call('upgrade_building'):
                    result = self.api_client.upgrade_building()
                    # Handle both dict and string responses
                    if isinstance(result, dict):
                        action_taken = result.get("success", False)
                    else:
                        action_taken = "success" in str(result).lower()
                
        elif action == self.ACTION_END_TURN:
            if self._track_api_call('end_turn'):
                result = self.api_client.end_turn()
                action_taken = True  # End turn is always successful
                self.turn_counter += 1  # Increment turn counter on turn end
                # Force switch to next AI after ending turn
                self._switch_to_next_ai()

        # Get the next state
        try:
            next_state = self._get_state()
        except Exception as e:
            logger.error(f"Error getting next state: {e}")
            next_state = self._get_empty_state()

        # Update score tracking
        self.previous_score = self.current_score
        self.current_score = self._get_player_score()

        # Calculate reward
        reward = self._calculate_reward(action_taken)

        # Update idle turn counter
        if action_taken:
            self.idle_turns = 0
        else:
            self.idle_turns += 1

        # Check if the game is done
        done = self._is_game_over()

        # Create info dictionary
        info = {
            'action_taken': action_taken,
            'score_change': self.current_score - self.previous_score,
            'current_score': self.current_score,
            'idle_turns': self.idle_turns,
            'turn_counter': self.turn_counter,
            'current_ai': self.current_ai_index,
            'api_calls_used': self.current_api_calls,
            'api_calls_remaining': self.max_api_calls_per_turn - self.current_api_calls
        }

        return next_state, reward, done, info

    def _is_game_over(self) -> bool:
        """Check if the game is over"""
        # Game is over if we've reached the maximum number of rounds
        if self.turn_counter >= self.MAX_ROUNDS:
            return True
        
        # Game is over if too many idle turns
        if self.idle_turns >= 50:  # Prevent infinite loops
            return True
        
        # Could add other end conditions here like:
        # - Only one player remaining
        # - Victory conditions met
        # - Time limits exceeded
        
        return False

    def _get_empty_state(self) -> np.ndarray:
        """Return an empty state representation as a flattened array with consistent size"""
        # Create empty state with fixed size: 10404 elements
        # 1600 (terrain) + 1600 (resources) + 3600 (units) + 2800 (buildings) + 800 (visibility+combat) + 4 (global resources)
        expected_size = 10404
        empty_state = np.zeros(expected_size, dtype=np.float32)
        logger.debug(f"Created empty state with size: {empty_state.shape[0]}")
        return empty_state

    def _get_state(self) -> np.ndarray:
        """Get the current state as a dictionary of observation arrays"""
        try:
            # Get game status (track this API call)
            if self._track_api_call('get_detailed_game_status'):
                detailed_status = self.api_client.get_detailed_game_status()
            else:
                # If we can't make more API calls, return empty state
                logger.warning("Cannot make API call for game status - API limit reached")
                return self._get_empty_state()
            
            player_id = self.player_id

            # Update unit and building positions
            self._update_unit_positions(detailed_status)
            self._update_building_positions(detailed_status)
            
            # Update influence maps
            self._update_combat_influence()
            self._update_visibility()
            
            # Get overall resource levels
            resources = np.zeros(len(self.RESOURCE_TYPES))
            if isinstance(detailed_status, dict):
                for player in detailed_status.get("players", []):
                    if player.get("id") == player_id:
                        resources_data = player.get("resources", {})
                        for i, res_type in enumerate(self.RESOURCE_TYPES):
                            resources[i] = resources_data.get(res_type, 0) / 1000.0  # Normalize
                        break

            # Get relevant slices based on unit positions
            state_slices = self._get_state_windows()
            
            # Use consistent number of windows for all features to ensure fixed state size
            def get_fixed_windows(arr, n, pad_val=0):
                """Get exactly n windows, padding with empty windows if needed"""
                arr = np.array(arr)
                windows = []
                for i in range(n):
                    if i < arr.shape[0]:
                        windows.append(arr[i])
                    else:
                        # Pad with empty window if we don't have enough
                        windows.append(np.full((self.STATE_WINDOW_SIZE, self.STATE_WINDOW_SIZE), pad_val, dtype=np.float32))
                return np.array(windows)

            # Use fixed number of windows to ensure consistent state size
            terrain_windows = get_fixed_windows(state_slices['terrain'], 1)
            resources_windows = get_fixed_windows(state_slices['resources'], 4)  # 4 windows
            units_windows = get_fixed_windows(state_slices['units'], 1)
            buildings_windows = get_fixed_windows(state_slices['buildings'], 1)
            visibility_windows = get_fixed_windows(state_slices['visibility'], 1)
            combat_windows = get_fixed_windows(state_slices['combat'], 1)

            state_components = []
            
            # Terrain (one-hot encoded) - 1 window = 1600 elements
            terrain = terrain_windows[0].reshape(-1)  # 400 elements
            terrain_one_hot = np.zeros((terrain.size * len(self.TERRAIN_TYPES)))  # 400 * 4 = 1600
            for i, val in enumerate(terrain):
                if 0 <= val < len(self.TERRAIN_TYPES):
                    terrain_one_hot[i * len(self.TERRAIN_TYPES) + int(val)] = 1
            state_components.append(terrain_one_hot)

            # Resources (direct values) - 4 windows = 1600 elements
            state_components.append(resources_windows.reshape(-1))  # 4 * 400 = 1600

            # Units (one-hot encoded) - 1 window = 3600 elements
            units = units_windows[0].reshape(-1)  # 400 elements
            units_one_hot = np.zeros((units.size * len(self.UNIT_TYPES)))  # 400 * 9 = 3600
            for i, val in enumerate(units):
                if 0 <= abs(val) <= len(self.UNIT_TYPES):
                    units_one_hot[i * len(self.UNIT_TYPES) + int(abs(val))] = np.sign(val)
            state_components.append(units_one_hot)

            # Buildings (one-hot encoded) - 1 window = 2800 elements
            buildings = buildings_windows[0].reshape(-1)  # 400 elements
            buildings_one_hot = np.zeros((buildings.size * len(self.BUILDING_TYPES)))  # 400 * 7 = 2800
            for i, val in enumerate(buildings):
                if 0 <= abs(val) <= len(self.BUILDING_TYPES):
                    buildings_one_hot[i * len(self.BUILDING_TYPES) + int(abs(val))] = np.sign(val)
            state_components.append(buildings_one_hot)

            # Visibility and combat (direct values) - 1 window each = 400 + 400 = 800 elements
            state_components.append(visibility_windows[0].reshape(-1))  # 400
            state_components.append(combat_windows[0].reshape(-1))      # 400

            # Resource levels (global) = 4 elements
            state_components.append(resources)  # 4

            # Concatenate all components into a single state vector
            # Total: 1600 + 1600 + 3600 + 2800 + 800 + 4 = 10404 elements
            state = np.concatenate(state_components)
            state = state.astype(np.float32)  # Ensure correct data type

            # Verify state size consistency
            expected_size = 10404  # 1600 + 1600 + 3600 + 2800 + 800 + 4
            if state.shape[0] != expected_size:
                logger.warning(f"State size mismatch: expected {expected_size}, got {state.shape[0]}")
                # Pad or truncate to expected size
                if state.shape[0] < expected_size:
                    padding = np.zeros(expected_size - state.shape[0], dtype=np.float32)
                    state = np.concatenate([state, padding])
                else:
                    state = state[:expected_size]

            return state

        except Exception as e:
            logger.error(f"Error getting state: {e}")
            return self._get_empty_state()

    def _get_state_windows(self) -> Dict[str, np.ndarray]:
        """Get observation windows around units and buildings"""
        windows = {
            'terrain': [],
            'resources': [], 
            'units': [],
            'buildings': [],
            'visibility': [],
            'combat': []
        }
        
        # Get positions to observe around (friendly units and buildings)
        observe_positions = []
        
        # Add unit positions
        units = self._get_friendly_units()
        for unit in units:
            pos = unit.get("position", {})
            observe_positions.append((pos.get("x", 0), pos.get("y", 0)))
            
        # Add building positions    
        buildings = self._get_friendly_buildings()
        for building in buildings:
            pos = building.get("position", {})
            observe_positions.append((pos.get("x", 0), pos.get("y", 0)))
            
        # Get windows for each position
        for x, y in observe_positions:
            # Calculate window bounds
            x_min = max(0, x - self.STATE_WINDOW_SIZE//2)
            x_max = min(self.MAP_SIZE_X, x + self.STATE_WINDOW_SIZE//2)
            y_min = max(0, y - self.STATE_WINDOW_SIZE//2)
            y_max = min(self.MAP_SIZE_Y, y + self.STATE_WINDOW_SIZE//2)
            
            # Extract windows
            windows['terrain'].append(self.terrain_map[y_min:y_max, x_min:x_max])
            windows['resources'].append(self.resource_map[y_min:y_max, x_min:x_max])
            windows['units'].append(self.unit_map[y_min:y_max, x_min:x_max])
            windows['buildings'].append(self.building_map[y_min:y_max, x_min:x_max])
            windows['visibility'].append(self.visibility_map[y_min:y_max, x_min:x_max])
            windows['combat'].append(self.combat_influence_map[y_min:y_max, x_min:x_max])
            
        # Pad arrays to fixed size if needed
        for key in windows:
            if windows[key]:
                windows[key] = np.stack(windows[key])
            else:
                windows[key] = np.zeros((1, self.STATE_WINDOW_SIZE, self.STATE_WINDOW_SIZE))
                
        return windows
        
    def _update_unit_positions(self, game_status: Dict):
        """Update unit position map"""
        # Clear current unit positions
        self.unit_map.fill(0)
        
        # Add friendly units
        units = game_status.get("units", [])
        for unit in units:
            if isinstance(unit, dict):
                pos = unit.get("position", {})
                x, y = pos.get("x", 0), pos.get("y", 0)
                if 0 <= x < self.MAP_SIZE_X and 0 <= y < self.MAP_SIZE_Y:
                    unit_id = self._get_unit_type_id(unit.get("type", ""))
                    owner_id = unit.get("ownerID")
                    # Use positive IDs for friendly units, negative for enemy
                    if owner_id == self.player_id:
                        self.unit_map[y,x] = unit_id
                    else:
                        self.unit_map[y,x] = -unit_id
                        
    def _update_building_positions(self, game_status: Dict):
        """Update building position map"""
        # Clear current building positions
        self.building_map.fill(0)
        
        # Add buildings
        buildings = game_status.get("buildings", [])
        for building in buildings:
            if isinstance(building, dict):
                pos = building.get("position", {})
                x, y = pos.get("x", 0), pos.get("y", 0)
                if 0 <= x < self.MAP_SIZE_X and 0 <= y < self.MAP_SIZE_Y:
                    building_id = self._get_building_type_id(building.get("type", ""))
                    owner_id = building.get("ownerID")
                    # Use positive IDs for friendly buildings, negative for enemy
                    if owner_id == self.player_id:
                        self.building_map[y,x] = building_id
                    else:
                        self.building_map[y,x] = -building_id
                        
    def _get_state_window(self, center_x: int, center_y: int) -> np.ndarray:
        """Get a state observation window centered at given coordinates"""
        # Calculate window bounds
        half_size = self.STATE_WINDOW_SIZE // 2
        min_y = max(0, center_y - half_size)
        max_y = min(self.MAP_SIZE_Y, center_y + half_size)
        min_x = max(0, center_x - half_size)
        max_x = min(self.MAP_SIZE_X, center_x + half_size)
        
        # Initialize state tensors for each channel
        state_shape = (self.STATE_WINDOW_SIZE, self.STATE_WINDOW_SIZE, sum(self.STATE_CHANNELS.values()))
        state = np.zeros(state_shape, dtype=np.float32)
        
        # Fill window with visible state data
        channel_idx = 0
        
        # Terrain channels
        for i in range(self.STATE_CHANNELS['terrain']):
            state[:,:,channel_idx+i] = (self.terrain_map[min_y:max_y, min_x:max_x] == i).astype(np.float32)
        channel_idx += self.STATE_CHANNELS['terrain']
        
        # Resource channels
        for i in range(self.STATE_CHANNELS['resources']):
            state[:,:,channel_idx+i] = (self.resource_map[min_y:max_y, min_x:max_x] == i).astype(np.float32)
        channel_idx += self.STATE_CHANNELS['resources']
        
        # Unit channels
        for i in range(self.STATE_CHANNELS['units']):
            state[:,:,channel_idx+i] = (self.unit_map[min_y:max_y, min_x:max_x] == i).astype(np.float32)
        channel_idx += self.STATE_CHANNELS['units']
        
        # Building channels  
        for i in range(self.STATE_CHANNELS['buildings']):
            state[:,:,channel_idx+i] = (self.building_map[min_y:max_y, min_x:max_x] == i).astype(np.float32)
        channel_idx += self.STATE_CHANNELS['buildings']
        
        # Combat influence map
        state[:,:,channel_idx] = self.combat_influence_map[min_y:max_y, min_x:max_x]
        channel_idx += self.STATE_CHANNELS['combat']
        
        # Visibility mask
        state[:,:,channel_idx] = self.visibility_map[min_y:max_y, min_x:max_x]
        channel_idx += self.STATE_CHANNELS['visibility']
        
        return state
    
    def _calculate_action_mask(self, min_x: int, min_y: int, max_x: int, max_y: int) -> np.ndarray:
        """Calculate action mask for the given window based on game rules"""
        mask = np.zeros((max_y - min_y, max_x - min_x), dtype=np.float32)
        
        # Get units in view
        visible_units = self._get_visible_units(min_x, min_y, max_x, max_y)
        
        for unit in visible_units:
            x, y = unit['position']['x'] - min_x, unit['position']['y'] - min_y
            if 0 <= x < mask.shape[1] and 0 <= y < mask.shape[0]:
                # Mark movement range
                movement_range = self._get_unit_movement_range(unit)
                for dx in range(-movement_range, movement_range + 1):
                    for dy in range(-movement_range, movement_range + 1):
                        if abs(dx) + abs(dy) <= movement_range:  # Manhattan distance
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < mask.shape[1] and 0 <= new_y < mask.shape[0]:
                                if self._is_valid_move(unit, new_x + min_x, new_y + min_y):
                                    mask[new_y, new_x] = 1
                
                # Mark build range for builder units
                if self._is_builder_unit(unit):
                    build_range = self._get_unit_build_range(unit)
                    for dx in range(-build_range, build_range + 1):
                        for dy in range(-build_range, build_range + 1):
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < mask.shape[1] and 0 <= new_y < mask.shape[0]:
                                if self._is_valid_build_location(new_x + min_x, new_y + min_y):
                                    mask[new_y, new_x] = 1
                
                # Mark attack range for combat units
                if self._is_combat_unit(unit):
                    attack_range = self._get_unit_attack_range(unit)
                    for dx in range(-attack_range, attack_range + 1):
                        for dy in range(-attack_range, attack_range + 1):
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < mask.shape[1] and 0 <= new_y < mask.shape[0]:
                                if self._has_attackable_target(new_x + min_x, new_y + min_y):
                                    mask[new_y, new_x] = 1
        
        return mask

    def _update_combat_influence(self):
        """Update the combat influence map based on unit positions and strengths"""
        # Reset combat influence map
        self.combat_influence_map.fill(0)
        
        # Get all units
        units = self._get_all_units()
        
        for unit in units:
            if self._is_combat_unit(unit):
                x, y = unit['position']['x'], unit['position']['y']
                strength = self._get_unit_combat_strength(unit)
                attack_range = self._get_unit_attack_range(unit)
                
                # Update influence in attack range
                for dx in range(-attack_range, attack_range + 1):
                    for dy in range(-attack_range, attack_range + 1):
                        if abs(dx) + abs(dy) <= attack_range:  # Manhattan distance
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < self.MAP_SIZE_X and 0 <= new_y < self.MAP_SIZE_Y:
                                # Add influence based on distance and unit strength
                                distance = abs(dx) + abs(dy)
                                influence = strength * (1 - distance/attack_range)
                                self.combat_influence_map[new_y, new_x] += influence
    
    def _update_visibility(self):
        """Update the visibility map based on unit and building positions"""
        # Reset visibility map
        self.visibility_map.fill(False)
        
        # Update for units
        units = self._get_all_units()
        for unit in units:
            if unit['owner'] == self.player_id:
                x, y = unit['position']['x'], unit['position']['y']
                vision_range = self.UNIT_VISION_RANGE
                
                for dx in range(-vision_range, vision_range + 1):
                    for dy in range(-vision_range, vision_range + 1):
                        if abs(dx) + abs(dy) <= vision_range:
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < self.MAP_SIZE_X and 0 <= new_y < self.MAP_SIZE_Y:
                                self.visibility_map[new_y, new_x] = True
        
        # Update for buildings
        buildings = self._get_all_buildings()
        for building in buildings:
            if building['owner'] == self.player_id:
                x, y = building['position']['x'], building['position']['y']
                vision_range = self._get_building_vision_range(building)
                
                for dx in range(-vision_range, vision_range + 1):
                    for dy in range(-vision_range, vision_range + 1):
                        if abs(dx) + abs(dy) <= vision_range:
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < self.MAP_SIZE_X and 0 <= new_y < self.MAP_SIZE_Y:
                                self.visibility_map[new_y, new_x] = True
                            
    def _get_empty_state(self) -> np.ndarray:
        """Return an empty state representation as a flattened array with consistent size"""
        # Create empty state with fixed size: 10404 elements
        # 1600 (terrain) + 1600 (resources) + 3600 (units) + 2800 (buildings) + 800 (visibility+combat) + 4 (global resources)
        expected_size = 10404
        empty_state = np.zeros(expected_size, dtype=np.float32)
        logger.debug(f"Created empty state with size: {empty_state.shape[0]}")
        return empty_state
        
    def _get_terrain_type_id(self, terrain_type: str) -> int:
        """Convert terrain type to numeric ID"""
        terrain_map = {
            "grass": 0,
            "water": 1,
            "mountain": 2,
            "forest": 3
        }
        return terrain_map.get(terrain_type.lower(), 0)

    def _get_unit_type_id(self, unit_type: str) -> int:
        """Convert unit type to numeric ID"""
        type_map = {unit_type.lower(): i+1 for i, unit_type in enumerate(self.UNIT_TYPES)}
        return type_map.get(unit_type.lower(), 0)
    
    def _get_building_type_id(self, building_type: str) -> int:
        """Convert building type to numeric ID"""
        type_map = {btype.lower(): i+1 for i, btype in enumerate(self.BUILDING_TYPES)}
        return type_map.get(building_type.lower(), 0)
    
    def _get_action_mask(self) -> np.ndarray:
        """Create a binary mask for valid action positions"""
        mask = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X), dtype=np.float32)
        
        # Get valid positions from game state
        game_status = self.api_client.get_detailed_game_status()
        valid_positions = game_status.get("validPositions", [])
        
        # Mark valid positions as 1
        for pos in valid_positions:
            x, y = pos.get("x", 0), pos.get("y", 0)
            if 0 <= x < self.MAP_SIZE_X and 0 <= y < self.MAP_SIZE_Y:
                mask[y, x] = 1
        
        return mask
    
    def _get_player_score(self) -> int:
        """Get the current player's score"""
        try:
            scoreboard = self.api_client.get_scoreboard()
            
            if isinstance(scoreboard, dict):
                players = scoreboard.get("players", [])
            elif isinstance(scoreboard, str):
                try:
                    data = json.loads(scoreboard)
                    players = data.get("players", [])
                except json.JSONDecodeError:
                    logger.warning(f"Could not parse scoreboard: {scoreboard}")
                    return 0
            else:
                logger.warning(f"Unexpected scoreboard response type: {type(scoreboard)}")
                return 0
            
            for player in players:
                if isinstance(player, dict) and player.get("id") == self.player_id:
                    return player.get("score", 0)
                
            return 0
        except Exception as e:
            logger.error(f"Error getting player score: {e}")
            return 0
    
    def _calculate_reward(self, action_taken: bool) -> float:
        """Calculate reward primarily based on score changes and winning conditions"""
        reward = 0.0
        
        # Primary reward component: score changes
        score_change = self.current_score - self.previous_score
        reward += float(score_change) * 5.0  # Heavily weight score changes (increased from 2.0)
        
        # Get current rankings and give position-based rewards
        try:
            scoreboard = self.api_client.get_scoreboard()
            if isinstance(scoreboard, dict):
                players = sorted(scoreboard.get("players", []), 
                               key=lambda x: x.get("score", 0), 
                               reverse=True)
                
                # Find our position
                for position, player in enumerate(players):
                    if player.get("id") == self.player_id:
                        # Give higher rewards for better positions
                        position_reward = (len(players) - position) * 3.0
                        reward += position_reward
                        
                        # Extra reward for being in first place
                        if position == 0:
                            reward += 10.0
                        break
        except Exception as e:
            logger.warning(f"Could not calculate position reward: {e}")
        
        # Minimal strategic rewards to encourage expansion
        game_status = self.api_client.get_detailed_game_status()
        
        # Small reward for resource production capabilities
        buildings = game_status.get("buildings", [])
        resource_buildings = [b for b in buildings if isinstance(b, dict) and 
                          b.get("ownerID") == self.player_id and
                          b.get("type") in ["farm", "lumberCamp", "mine"]]
        reward += len(resource_buildings) * 0.2  # Reduced from original values
        
        # Small reward for military presence
        units = game_status.get("units", [])
        military_units = [u for u in units if isinstance(u, dict) and 
                        u.get("ownerID") == self.player_id and
                        u.get("type") in [ "archer", "knight"]]
        reward += len(military_units) * 0.1  # Reduced from original values
        
        # Idle turn penalty remains to discourage inaction
        if not action_taken and self.idle_turns > 0:
            reward += self.IDLE_TURN_PENALTY * self.idle_turns
        
        # End game scoring adjustments
        progress = self.turn_counter / self.MAX_ROUNDS
        if progress > 0.8:  # Final 20% of game
            # Double rewards to encourage strong finish
            reward *= 2.0
            
            # Extra reward for maintaining high score near the end
            if self.current_score > 0:  # Only if we have a positive score
                reward += (self.current_score / 100.0) * progress * 2.0
        
        return reward
        
    def _calculate_strategic_bonus(self, buildings: List[Dict]) -> float:
        """Calculate bonus for strategic building placement"""
        bonus = 0.0
        
        # Get positions of all buildings
        positions = [(b.get("position", {}).get("x", 0), 
                     b.get("position", {}).get("y", 0)) for b in buildings]
        
        # Reward for defensive structures near resource buildings
        for i, b1 in enumerate(buildings):
            if b1.get("type") in ["farm", "lumberCamp", "mine"]:
                # Check for nearby defensive structures
                x1, y1 = positions[i]
                for j, b2 in enumerate(buildings):
                    if b2.get("type") in ["defensiveTower", "wall"]:
                        x2, y2 = positions[j]
                        distance = abs(x2 - x1) + abs(y2 - y1)  # Manhattan distance
                        if distance <= 3:  # Within protection range
                            bonus += 0.5
        
        return bonus
        
    def _calculate_territory_control(self, buildings: List[Dict]) -> float:
        """Calculate territory control bonus based on building placement"""
        bonus = 0.0
        
        # Create territory map
        territory = np.zeros((self.MAP_SIZE_Y, self.MAP_SIZE_X))
        
        # Mark territory influence
        for building in buildings:
            pos = building.get("position", {})
            x, y = pos.get("x", 0), pos.get("y", 0)
            
            # Add influence in a radius around building
            radius = 3
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    try:
                        ny, nx = y + dy, x + dx
                        if 0 <= ny < self.MAP_SIZE_Y and 0 <= nx < self.MAP_SIZE_X:
                            distance = abs(dx) + abs(dy)
                            if distance <= radius:
                                territory[ny, nx] += 1.0 / (distance + 1)
                    except Exception as e:
                        logger.error(f"Error calculating territory influence: {e}")
                        continue
        
        # Calculate bonus based on territory coverage and concentration
        coverage = np.sum(territory > 0) / (self.MAP_SIZE_X * self.MAP_SIZE_Y)
        concentration = np.mean(territory[territory > 0])
        
        bonus = coverage * 5.0 + concentration * 2.0
        
        return bonus
        
    def get_available_actions(self) -> Dict:
        """Get available actions from the game"""
        return self.api_client.get_available_actions()
    
    def get_valid_action_parameters(self, action: int) -> List[Dict]:
        """Get valid parameters for a given action type"""
        valid_params = []
        game_status = self.api_client.get_detailed_game_status()
        
        if action == self.ACTION_MOVE_UNIT:
            units = self.api_client.get_units().get("units", [])
            for unit in units:
                if unit.get("ownerId") == self.player_id and unit.get("movesLeft", 0) > 0:
                    # Get valid movement positions for this unit
                    pos = unit.get("position", {})
                    current_x, current_y = pos.get("x", 0), pos.get("y", 0)
                    unit_id = unit.get("id")
                    
                    # Get valid moves from game status
                    valid_moves = game_status.get("validMoves", {}).get(unit_id, [])
                    for move in valid_moves:
                        valid_params.append({
                            "unit_id": unit_id,
                            "x": move.get("x"),
                            "y": move.get("y")
                        })
                    
        elif action == self.ACTION_FOUND_CITY:
            # Find all settlers that can found cities
            units = self.api_client.get_units().get("units", [])
            for unit in units:
                if (unit.get("ownerId") == self.player_id and 
                    unit.get("type") == "settler" and
                    unit.get("canAct", False)):
                    valid_params.append({"unit_id": unit.get("id")})
                    
        elif action == self.ACTION_BUILD:
            # For each builder unit, get valid building positions
            units = self.api_client.get_units().get("units", [])
            for unit in units:
                if unit.get("ownerId") == self.player_id and unit.get("canAct", False):
                    unit_type = unit.get("type", "")
                    unit_id = unit.get("id")
                    
                    # Map unit types to what they can build
                    build_options = {
                        "farmer": ["farm"],
                        "lumberjack": ["lumberCamp"],
                        "miner": ["mine"],
                        "commander": ["barracks"],
                        "architect": ["defensiveTower", "wall"]
                    }
                    
                    if unit_type in build_options:
                        # Get valid build positions from game status
                        valid_builds = game_status.get("validBuilds", {}).get(unit_id, [])
                        for build_pos in valid_builds:
                            for building_type in build_options[unit_type]:
                                valid_params.append({
                                    "unit_id": unit_id,
                                    "building_type": building_type,
                                    "x": build_pos.get("x"),
                                    "y": build_pos.get("y")
                                })
                                
        elif action == self.ACTION_TRAIN_UNIT:
            # Find all buildings that can train units
            buildings = self.api_client.get_buildings().get("buildings", [])
            for building in buildings:
                if building.get("ownerId") == self.player_id:
                    building_type = building.get("type")
                    building_id = building.get("id")
                    
                    # Map building types to units they can train
                    train_options = {
                        "barracks": ["archer", "knight"],
                        "cityCenter": ["settler", "farmer", "lumberjack", 
                                     "miner", "commander", "architect"]
                    }
                    
                    if building_type in train_options:
                        for unit_type in train_options[building_type]:
                            valid_params.append({
                                "building_id": building_id,
                                "unit_type": unit_type
                            })
                            
        elif action == self.ACTION_HARVEST:
            # Find all units that can harvest
            units = self.api_client.get_units().get("units", [])
            for unit in units:
                if (unit.get("ownerId") == self.player_id and 
                    unit.get("canAct", False) and
                    unit.get("type") in ["farmer", "lumberjack", "miner"]):
                    valid_params.append({"unit_id": unit.get("id")})
                    
        elif action == self.ACTION_UPGRADE_BUILDING:
            # Find all buildings that can be upgraded
            buildings = self.api_client.get_buildings().get("buildings", [])
            for building in buildings:
                if (building.get("ownerId") == self.player_id and
                    building.get("canUpgrade", False)):
                    valid_params.append({"building_id": building.get("id")})
                    
        elif action == self.ACTION_END_TURN:
            # End turn is always valid
            valid_params.append({})  # No parameters needed
            
        return valid_params
    
    def _get_all_units(self) -> List[Dict]:
        """Get all units in the game"""
        try:
            game_status = self.api_client.get_detailed_game_status()
            if isinstance(game_status, dict):
                return game_status.get("units", [])
            return []
        except Exception as e:
            logger.error(f"Error getting all units: {e}")
            return []

    def _get_friendly_units(self) -> List[Dict]:
        """Get all friendly units"""
        all_units = self._get_all_units()
        return [unit for unit in all_units if unit.get("ownerID") == self.player_id]

    def _get_all_buildings(self) -> List[Dict]:
        """Get all buildings in the game"""
        try:
            game_status = self.api_client.get_detailed_game_status()
            if isinstance(game_status, dict):
                return game_status.get("buildings", [])
            return []
        except Exception as e:
            logger.error(f"Error getting all buildings: {e}")
            return []

    def _get_friendly_buildings(self) -> List[Dict]:
        """Get all friendly buildings"""
        all_buildings = self._get_all_buildings()
        return [building for building in all_buildings if building.get("ownerID") == self.player_id]

    def _update_visibility(self):
        """Update the visibility map based on unit and building positions"""
        # Reset visibility map
        self.visibility_map.fill(False)
        
        # Update for units
        units = self._get_all_units()
        for unit in units:
            if unit['owner'] == self.player_id:
                x, y = unit['position']['x'], unit['position']['y']
                vision_range = self.UNIT_VISION_RANGE
                
                for dx in range(-vision_range, vision_range + 1):
                    for dy in range(-vision_range, vision_range + 1):
                        if abs(dx) + abs(dy) <= vision_range:
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < self.MAP_SIZE_X and 0 <= new_y < self.MAP_SIZE_Y:
                                self.visibility_map[new_y, new_x] = True
        
        # Update for buildings
        buildings = self._get_all_buildings()
        for building in buildings:
            if building['owner'] == self.player_id:
                x, y = building['position']['x'], building['position']['y']
                vision_range = self._get_building_vision_range(building)
                
                for dx in range(-vision_range, vision_range + 1):
                    for dy in range(-vision_range, vision_range + 1):
                        if abs(dx) + abs(dy) <= vision_range:
                            new_x, new_y = x + dx, y + dy
                            if 0 <= new_x < self.MAP_SIZE_X and 0 <= new_y < self.MAP_SIZE_Y:
                                self.visibility_map[new_y, new_x] = True
                                
    def _track_api_call(self, api_function_name: str) -> bool:
        """Track API calls and check if limit is reached"""
        self.current_api_calls += 1
        self.performance_stats['total_api_calls'] += 1
        
        # Log API call for monitoring
        self.api_call_history.append({
            'timestamp': time.time(),
            'function': api_function_name,
            'ai_index': self.current_ai_index,
            'turn_counter': self.turn_counter
        })
        
        # Check if AI has reached its call limit
        if self.current_api_calls >= self.max_api_calls_per_turn:
            logger.info(f"AI {self.current_ai_index} reached API call limit ({self.max_api_calls_per_turn})")
            return False
        
        return True
    
    def _should_switch_ai(self) -> bool:
        """Check if we should switch to the next AI player"""
        # Switch if current AI has reached its API call limit
        if self.current_api_calls >= self.max_api_calls_per_turn:
            return True
        
        # Could add other conditions here later, such as:
        # - Time-based switching
        # - Performance-based switching
        # - Manual override conditions
        
        return False

    def _switch_to_next_ai(self) -> bool:
        """Switch to the next AI player"""
        try:
            # Reset API call counter for the new AI
            self.current_api_calls = 0
            
            # Move to next AI
            self.current_ai_index = (self.current_ai_index + 1) % len(self.ai_players)
            
            # If we've cycled through all AIs, start a new round
            if self.current_ai_index == 0:
                self._start_new_round()
            
            # Switch to the new AI player - switch_player() takes no arguments according to error
            if self.ai_players:
                result = self.api_client.switch_player()
                
                if result.get("success", False):
                    # Update player_id to current AI player
                    self.player_id = self.ai_players[self.current_ai_index]
                    logger.info(f"Switched to AI {self.current_ai_index} (Player: {self.player_id})")
                    return True
                else:
                    logger.error(f"Failed to switch to AI {self.current_ai_index}: {result}")
                    return False
            
            return False
            
        except Exception as e:
            logger.error(f"Error switching to next AI: {e}")
            return False
    
    def _start_new_round(self):
        """Start a new game round when all AIs have completed their turns"""
        self.round_counter += 1
        logger.info(f"Starting new round {self.round_counter}")
        
        # Update performance statistics
        if self.round_counter > 0:
            total_calls = self.performance_stats['total_api_calls']
            total_turns = self.round_counter * len(self.ai_players)
            self.performance_stats['average_calls_per_turn'] = total_calls / max(total_turns, 1)
        
        # Log round statistics
        logger.info(f"Round {self.round_counter} started - Total API calls: {self.performance_stats['total_api_calls']}")
        logger.info(f"Average calls per turn: {self.performance_stats['average_calls_per_turn']:.2f}")
    
    def _collect_players(self) -> bool:
        """Collect all RL agent player IDs (all human players with RL_Agent_ prefix) using the explicit player list API, with retry. Handles string-formatted player lists."""
        import re
        max_retries = 10
        retry_delay = 0.2
        for attempt in range(max_retries):
            self.ai_players = []  # Clear before each attempt to avoid duplicates
            try:
                # Use the correct method from the API client
                player_response = self.api_client.get_all_players() if hasattr(self.api_client, 'get_all_players') else None
                logger.debug(f"Raw response from get_all_players(): {player_response}")
                if player_response is None:
                    logger.warning(f"get_all_players() returned None (attempt {attempt+1}/{max_retries})")
                    time.sleep(retry_delay)
                    continue
                players = []
                # Handle dict response with string-formatted player list
                if isinstance(player_response, dict):
                    if 'players' in player_response and isinstance(player_response['players'], str):
                        # Parse the string for player lines
                        player_lines = player_response['players'].split('\n')
                        # Skip the header line (e.g., 'ALL PLAYERS:')
                        player_lines = [line.strip() for line in player_lines if line.strip() and not line.strip().startswith('ALL PLAYERS')]
                        for line in player_lines:
                            # Example line: 'rl_agent_1 (Human) [CURRENT]'
                            match = re.match(r'^(rl_agent_\w+) \((Human|AI)\)', line, re.IGNORECASE)
                            if match:
                                player_name = match.group(1)
                                player_type = match.group(2)
                                if player_type.lower() == "human" and player_name.lower().startswith("rl_agent_"):
                                    # Use player_name as ID (since no explicit ID)
                                    self.ai_players.append(player_name)
                                    logger.info(f"Found RL agent: {player_name} (type: {player_type})")
                    elif 'players' in player_response and isinstance(player_response['players'], list):
                        players = player_response['players']
                    elif 'data' in player_response:
                        players = player_response['data']
                    else:
                        players = player_response
                # Fallback: if players is a list of dicts (legacy/alternate API)
                if isinstance(players, list):
                    for player in players:
                        if not isinstance(player, dict):
                            continue
                        player_id = player.get("id")
                        player_name = player.get("name", "")
                        player_type = player.get("type", "")
                        if player_type.lower() == "human" and player_name.lower().startswith("rl_agent_"):
                            self.ai_players.append(player_id)
                            logger.info(f"Found RL agent: {player_name} (ID: {player_id})")
                if self.ai_players:
                    self.player_id = self.ai_players[0]
                    self.current_ai_index = 0
                    logger.info(f"Initialized with {len(self.ai_players)} RL agents (all as human players)")
                    return True
                else:
                    logger.warning(f"No RL agent players found in the game yet (attempt {attempt+1}/{max_retries}). Players: {player_response}")
                    time.sleep(retry_delay)
            except Exception as e:
                logger.error(f"Error collecting RL agent players: {e}")
                time.sleep(retry_delay)
        logger.error(f"No RL agent players found in the game after {max_retries} retries.")
        return False
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """Get current performance statistics"""
        return {
            **self.performance_stats,
            'current_round': self.round_counter,
            'current_ai_index': self.current_ai_index,
            'current_api_calls': self.current_api_calls,
            'api_calls_remaining': self.max_api_calls_per_turn - self.current_api_calls,
            'total_ai_players': len(self.ai_players)
        }
