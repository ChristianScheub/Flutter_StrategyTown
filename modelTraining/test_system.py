#!/usr/bin/env python3
"""
Test script to verify connection to the Game API and basic agent functionality
"""

import argparse
import logging
import time
from game_api_client import GameApiClient
from game_environment import GameEnvironment
from simple_agent import SimpleAgent

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_api_connection():
    """Test connection to the Game API"""
    client = GameApiClient()
    logger.info("Testing connection to Game API...")
    
    try:
        # Try to get server status
        status = client.get_server_status()
        if status.get("success", False):
            logger.info("✅ Successfully connected to Game API")
            logger.info(f"Server message: {status.get('message', 'No message')}")
            return True
        else:
            logger.error(f"❌ API returned error: {status}")
            return False
    except Exception as e:
        logger.error(f"❌ Failed to connect to Game API: {e}")
        return False

def test_game_environment():
    """Test basic game environment functionality"""
    logger.info("Creating game environment...")
    env = GameEnvironment(player_name="Test_Agent")
    
    # Try to setup a game
    logger.info("Setting up game with AI players...")
    setup_success = env.setup_game(num_players=2)
    
    if not setup_success:
        logger.error("❌ Failed to setup game")
        return False
    
    logger.info("✅ Successfully setup game")
    
    # Get initial state
    logger.info("Getting initial game state...")
    state = env._get_state()
    
    if state is None:
        logger.error("❌ Failed to get game state")
        return False
    
    logger.info(f"✅ Got game state with shape: {state.shape}")
    
    # Try to perform an action
    logger.info("Testing end turn action...")
    next_state, reward, done, info = env.step(env.ACTION_END_TURN)
    
    if next_state is None:
        logger.error("❌ Failed to perform action")
        return False
    
    logger.info(f"✅ Action performed successfully, received reward: {reward}")
    logger.info(f"Game info: {info}")
    
    return True

def test_agent_creation():
    """Test creating and using a simple agent"""
    logger.info("Creating simple agent...")
    state_size = 100  # Example state size
    action_size = 7   # Example action size
    
    agent = SimpleAgent(state_size, action_size, name="test_agent")
    
    # Print model summary
    logger.info("Agent model summary:")
    logger.info(agent.get_model_summary())
    
    # Test making a prediction
    logger.info("Testing forward pass with random state...")
    import numpy as np
    state = np.random.random(state_size)
    action_values = agent.forward(state)
    
    logger.info(f"✅ Forward pass successful, output shape: {action_values.shape}")
    
    # Test saving model
    logger.info("Testing model saving...")
    import os
    os.makedirs("models", exist_ok=True)
    
    agent.save_model("models/test_agent.h5")
    logger.info("✅ Model saved successfully")
    
    return True

def run_tests():
    """Run all tests and report results"""
    results = {
        "API Connection": test_api_connection(),
        "Game Environment": test_game_environment(),
        "Agent Creation": test_agent_creation(),
    }
    
    # Print summary
    logger.info("\n=== Test Results Summary ===")
    all_passed = True
    
    for test_name, passed in results.items():
        status = "✅ PASSED" if passed else "❌ FAILED"
        logger.info(f"{test_name}: {status}")
        if not passed:
            all_passed = False
    
    if all_passed:
        logger.info("\n✅ All tests passed! The training system is ready to use.")
        logger.info("Next steps:")
        logger.info("1. Run full training: ./run_training_pipeline.sh")
        logger.info("2. Or train models individually: python simple_agent.py")
    else:
        logger.error("\n❌ Some tests failed. Please fix the issues before proceeding.")
    
    return all_passed

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Test Game API and training system')
    parser.add_argument('--test-api', action='store_true', help='Test Game API connection only')
    parser.add_argument('--test-env', action='store_true', help='Test game environment only')
    parser.add_argument('--test-agent', action='store_true', help='Test agent creation only')
    
    args = parser.parse_args()
    
    if args.test_api:
        test_api_connection()
    elif args.test_env:
        test_game_environment()
    elif args.test_agent:
        test_agent_creation()
    else:
        run_tests()
