#!/usr/bin/env python3
"""
Game API Client - Python wrapper for the Game API Service (8080)
"""

import json
import requests
import logging
from typing import Dict, Any, List, Optional, Union

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class GameApiClient:
    """Client for interacting with the Game API Service"""
    
    def __init__(self, base_url: str = "http://localhost:8080/api"):
        """Initialize the API client with the base URL"""
        self.base_url = base_url
        self.session = requests.Session()
        
    def _make_request(self, method: str, endpoint: str, data: Dict = None, max_retries: int = 3) -> Dict[str, Any]:
        """Make a request to the API with retries"""
        url = f"{self.base_url}/{endpoint}"
        
        for attempt in range(max_retries):
            try:
                if method.upper() == 'GET':
                    response = self.session.get(url)
                elif method.upper() == 'POST':
                    response = self.session.post(url, json=data)
                elif method.upper() == 'DELETE':
                    response = self.session.delete(url)
                else:
                    raise ValueError(f"Unsupported HTTP method: {method}")
                    
                response.raise_for_status()
                # Parse JSON response and ensure it's a dictionary
                response_data = response.json()
                if not isinstance(response_data, dict):
                    logger.warning(f"API returned non-dictionary response: {response_data}")
                    return {"success": True, "data": response_data}
                return response_data
                
            except requests.exceptions.RequestException as e:
                if attempt == max_retries - 1:  # Last attempt
                    logger.error(f"API request failed after {max_retries} attempts: {e}")
                    return {"success": False, "error": str(e)}
                else:
                    logger.warning(f"API request attempt {attempt + 1} failed: {e}. Retrying...")
                    continue
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse API response as JSON: {e}")
                if response.content:
                    logger.debug(f"Raw response: {response.content[:1000]}")
                return {"success": False, "error": "Invalid JSON response"}
    
    # Game Management
    def get_server_status(self) -> Dict[str, Any]:
        """Get server status"""
        return self._make_request('GET', 'status')
    
    def get_game_status(self) -> Dict[str, Any]:
        """Get game status"""
        return self._make_request('GET', 'game-status')
        
    def get_detailed_game_status(self) -> Dict[str, Any]:
        """Get detailed game status"""
        return self._make_request('GET', 'detailed-game-status')
    
    def get_available_actions(self) -> Dict[str, Any]:
        """Get available actions"""
        return self._make_request('GET', 'available-actions')
    
    def start_new_game(self) -> Dict[str, Any]:
        """Start a new game"""
        return self._make_request('POST', 'start-new-game')
        
    # Player Management
    def get_all_players(self) -> Dict[str, Any]:
        """Get all players"""
        return self._make_request('GET', 'players/all')
        
    def get_current_player(self) -> Dict[str, Any]:
        """Get current player"""
        return self._make_request('GET', 'players/current')
    
    def get_scoreboard(self) -> Dict[str, Any]:
        """Get scoreboard"""
        return self._make_request('GET', 'scoreboard')
    
    def add_human_player(self, name: str) -> Dict[str, Any]:
        """Add a human player"""
        return self._make_request('POST', f'players/add-human/{name}')
    
    def add_ai_player(self, name: str) -> Dict[str, Any]:
        """Add an AI player"""
        return self._make_request('POST', f'players/add-ai/{name}')
    
    def switch_player(self) -> Dict[str, Any]:
        """Switch to the next player"""
        return self._make_request('POST', 'switch-player')
    
    def remove_player(self, player_id: str) -> Dict[str, Any]:
        """Remove a player"""
        return self._make_request('DELETE', f'players/remove/{player_id}')
        
    # Unit & Building Management
    def get_units(self) -> Dict[str, Any]:
        """Get all units"""
        return self._make_request('GET', 'units')
    
    def get_buildings(self) -> Dict[str, Any]:
        """Get all buildings"""
        return self._make_request('GET', 'buildings')
    
    def select_unit(self, unit_id: str) -> Dict[str, Any]:
        """Select a unit"""
        return self._make_request('POST', f'units/select/{unit_id}')
    
    def select_building(self, building_id: str) -> Dict[str, Any]:
        """Select a building"""
        return self._make_request('POST', f'buildings/select/{building_id}')
    
    def move_unit(self, unit_id: str, x: int, y: int) -> Dict[str, Any]:
        """Move a unit to a new position"""
        return self._make_request('POST', f'units/move/{unit_id}/{x}/{y}')
    
    def move_unit_at_position(self, from_x: int, from_y: int, to_x: int, to_y: int) -> Dict[str, Any]:
        """Move a unit from one position to another"""
        return self._make_request('POST', f'units/move-from-position/{from_x}/{from_y}/{to_x}/{to_y}')
    
    def found_city(self) -> Dict[str, Any]:
        """Found a city with the selected unit"""
        return self._make_request('POST', 'found-city')
    
    def found_city_with_unit(self, unit_id: str) -> Dict[str, Any]:
        """Select a unit and found a city with it"""
        # Chain two API calls
        select_result = self.select_unit(unit_id)
        if select_result.get("success", False):
            return self.found_city()
        return select_result
    
    def harvest_resource(self) -> Dict[str, Any]:
        """Harvest resource with the selected unit"""
        return self._make_request('POST', 'units/harvest')
    
    def upgrade_building(self) -> Dict[str, Any]:
        """Upgrade the selected building"""
        return self._make_request('POST', 'buildings/upgrade')
    
    # Map Management
    def get_area_map(self, x: int, y: int, radius: int) -> Dict[str, Any]:
        """Get map area at the specified position and radius"""
        return self._make_request('GET', f'area-map/{x}/{y}/{radius}')
    
    def get_tile_info(self, x: int, y: int) -> Dict[str, Any]:
        """Get information about a specific tile"""
        return self._make_request('GET', f'tile-info/{x}/{y}')
    
    # Training Units
    def train_unit(self, unit_type: str, building_id: str) -> Dict[str, Any]:
        """Train a specific unit at a building"""
        select_result = self.select_building(building_id)
        if select_result.get("success", False):
            return self._make_request('POST', f'train-unit/{unit_type}/{building_id}')
        return select_result
    
    def train_unit_generic(self, unit_type: str) -> Dict[str, Any]:
        """Train a unit of the specified type (generic training)"""
        return ""
        
    # Building Construction
    def build_quick(self, building_type: str, unit_id: str) -> Dict[str, Any]:
        """Quickly build a specific type of building with a unit"""
        return self._make_request('POST', f'quick-build/{building_type}/{unit_id}')
    
    def build_with_unit(self, unit_id: str, building_type: str, x: int, y: int) -> Dict[str, Any]:
        """Build a building at specific coordinates with a unit"""
        return self._make_request('POST', f'buildings/build-with-unit/{unit_id}/{building_type}/{x}/{y}')
    
    # Game Control
    def end_turn(self) -> Dict[str, Any]:
        """End the current player's turn"""
        return self._make_request('POST', 'end-turn')
    
    def clear_selection(self) -> Dict[str, Any]:
        """Clear current selection"""
        return self._make_request('POST', 'clear-selection')
