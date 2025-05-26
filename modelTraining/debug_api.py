#!/usr/bin/env python3
"""
Debug script to inspect API responses
"""
import json
import logging
from game_api_client import GameApiClient

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def main():
    """Print API responses for debugging"""
    client = GameApiClient()
    
    # Start a new game
    start_result = client.start_new_game()
    logger.info(f"Start game result: {json.dumps(start_result, indent=2)}")
    
    # Add player
    player_result = client.add_ai_player("Debug_Player")
    logger.info(f"Add player result: {json.dumps(player_result, indent=2)}")
    
    # Get units
    units_result = client.get_units()
    logger.info(f"Units result: {json.dumps(units_result, indent=2)}")
    
    # Get detailed game status
    status = client.get_detailed_game_status()
    logger.info(f"Game status: {json.dumps(status, indent=2)}")

if __name__ == "__main__":
    main()
