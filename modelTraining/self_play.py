#!/usr/bin/env python3
"""
Self-play training script that rotates through multiple AI models
"""

import os
import sys
import time
import numpy as np
import pandas as pd
import tensorflow as tf
import matplotlib.pyplot as plt
from typing import Dict, List, Tuple
import logging
from tqdm import tqdm
import argparse

from game_environment import GameEnvironment
from dqn_agent import DQNAgent
from parameter_generator import ActionParameterGenerator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("self_play.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class SelfPlayTrainer:
    """Handles self-play training of multiple DQN agents"""
    
    def __init__(
        self,
        num_agents: int = 5,
        episodes: int = 1000,
        max_steps_per_episode: int = 500,
        save_interval: int = 10
    ):
        """Initialize the self-play trainer"""
        self.num_agents = num_agents
        self.episodes = episodes
        self.max_steps_per_episode = max_steps_per_episode
        self.save_interval = save_interval
        
        # Set up shared environment
        self.environment = GameEnvironment()
        self.param_generator = ActionParameterGenerator(self.environment)
        
        # Agents
        self.agents = []
        
        # Create training directory
        self.training_dir = os.path.join("self_play_training", f"run_{int(time.time())}")
        os.makedirs(self.training_dir, exist_ok=True)
        os.makedirs(os.path.join(self.training_dir, "models"), exist_ok=True)
        
        # Training statistics
        self.stats = {
            "episode_rewards": [],
            "episode_steps": [],
            "scores": [],
            "wins": []
        }
        
    def setup_agents(self):
        """Set up DQN agents"""
        for i in range(self.num_agents):
            # Create agent
            state_shape = (5, self.environment.MAP_SIZE_X, self.environment.MAP_SIZE_Y)
            action_space = 7  # Number of action types
            
            agent = DQNAgent(
                state_shape=state_shape,
                action_space=action_space,
                model_name=f"agent_{i+1}",
                epsilon=0.8,  # Start with high exploration
                epsilon_decay=0.995,
                epsilon_min=0.1,
                memory_size=50000
            )
            
            self.agents.append(agent)
            
            logger.info(f"Created agent {i+1}")
    
    def self_play_training(self):
        """Train agents via self-play"""
        logger.info(f"Starting self-play training for {self.num_agents} agents for {self.episodes} episodes")
        
        for episode in tqdm(range(self.episodes)):
            # Reset environment
            state = self.environment.reset()
            done = False
            step = 0
            
            # Track rewards for each agent
            episode_rewards = np.zeros(self.num_agents)
            player_id_to_agent_idx = {}
            
            # Create a game with multiple AI players
            for i in range(self.num_agents):
                result = self.environment.api_client.add_ai_player(f"AI_Player_{i+1}")
                if result.get("success", False):
                    player_id = result.get("player", {}).get("id")
                    player_id_to_agent_idx[player_id] = i
            
            # Play a complete game
            while not done and step < self.max_steps_per_episode:
                # Get current player
                current_player_info = self.environment.api_client.get_current_player()
                if not current_player_info.get("success", False):
                    logger.error("Failed to get current player information")
                    break
                
                current_player_id = current_player_info.get("player", {}).get("id")
                
                # Find the agent index for the current player
                if current_player_id not in player_id_to_agent_idx:
                    logger.error(f"Current player ID {current_player_id} not found in mapping")
                    # End turn and continue
                    self.environment.api_client.end_turn()
                    continue
                
                agent_idx = player_id_to_agent_idx[current_player_id]
                agent = self.agents[agent_idx]
                
                # Choose an action
                action = agent.choose_action(state)
                
                # Generate appropriate parameters
                action_params = self.param_generator.generate_params_for_action(action)
                
                # Take a step
                next_state, reward, done, info = self.environment.step(action, action_params)
                
                # Store experience in the agent's memory
                agent.remember(state, action, reward, next_state, done)
                
                # Train the current agent
                agent.replay()
                
                # Update state and tracking variables
                state = next_state
                episode_rewards[agent_idx] += reward
                
                # If we've performed 10 actions for the current player or action is end turn,
                # then end the turn to give other agents a chance
                if step % 10 == 9 or action == self.environment.ACTION_END_TURN:
                    self.environment.api_client.end_turn()
                
                step += 1
                
                # Log every 100 steps
                if step % 100 == 0:
                    logger.debug(f"Episode {episode+1}, Step {step}: Agent {agent_idx+1} took action")
            
            # Get final scores for all players
            scoreboard = self.environment.api_client.get_scoreboard()
            if not scoreboard.get("success", False):
                logger.error("Failed to get scoreboard")
                continue
                
            players = scoreboard.get("players", [])
            
            # Map scores to agent indexes
            final_scores = np.zeros(self.num_agents)
            for player in players:
                player_id = player.get("id")
                if player_id in player_id_to_agent_idx:
                    agent_idx = player_id_to_agent_idx[player_id]
                    final_scores[agent_idx] = player.get("score", 0)
            
            # Determine winner
            winner_idx = np.argmax(final_scores) if np.max(final_scores) > 0 else -1
            winners = np.zeros(self.num_agents)
            if winner_idx >= 0:
                winners[winner_idx] = 1
            
            # Store statistics
            self.stats["episode_rewards"].append(episode_rewards.tolist())
            self.stats["episode_steps"].append(step)
            self.stats["scores"].append(final_scores.tolist())
            self.stats["wins"].append(winners.tolist())
            
            # Log episode summary
            logger.info(f"Episode {episode+1}: Steps={step}, "
                       f"Winner: Agent_{winner_idx+1 if winner_idx >= 0 else 'None'} "
                       f"with score {np.max(final_scores):.2f}")
            
            # Save models and stats periodically
            if (episode + 1) % self.save_interval == 0:
                self._save_models(episode + 1)
                self._save_stats()
                self._plot_training_progress()
    
    def _save_models(self, episode: int):
        """Save all agent models"""
        for i, agent in enumerate(self.agents):
            filename = f"agent_{i+1}_episode_{episode}.h5"
            filepath = os.path.join(self.training_dir, "models", filename)
            agent.model.save(filepath)
            logger.info(f"Saved Agent {i+1} model to {filepath}")
    
    def _save_stats(self):
        """Save training statistics to CSV"""
        # Episode rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                 columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.to_csv(os.path.join(self.training_dir, "rewards.csv"), index=False)
        
        # Episode steps
        pd.DataFrame(self.stats["episode_steps"], columns=["Steps"]).to_csv(
            os.path.join(self.training_dir, "steps.csv"), index=False)
        
        # Final scores
        scores_df = pd.DataFrame(self.stats["scores"],
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        scores_df.to_csv(os.path.join(self.training_dir, "scores.csv"), index=False)
        
        # Wins
        wins_df = pd.DataFrame(self.stats["wins"],
                              columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        wins_df.to_csv(os.path.join(self.training_dir, "wins.csv"), index=False)
        
        # Summary stats
        current_episode = len(self.stats["episode_steps"])
        summary = {
            "Agent": [f"Agent_{i+1}" for i in range(self.num_agents)],
            "Avg_Reward": np.mean(self.stats["episode_rewards"], axis=0),
            "Avg_Score": np.mean(self.stats["scores"], axis=0),
            "Win_Rate": np.sum(self.stats["wins"], axis=0) / current_episode,
            "Wins": np.sum(self.stats["wins"], axis=0)
        }
        
        summary_df = pd.DataFrame(summary)
        summary_df.to_csv(os.path.join(self.training_dir, "summary.csv"), index=False)
    
    def _plot_training_progress(self):
        """Plot training progress charts"""
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        
        # Plot rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.plot(ax=axes[0, 0])
        axes[0, 0].set_title("Episode Rewards")
        axes[0, 0].set_xlabel("Episode")
        axes[0, 0].set_ylabel("Total Reward")
        axes[0, 0].grid(True)
        
        # Plot scores
        scores_df = pd.DataFrame(self.stats["scores"],
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        scores_df.plot(ax=axes[0, 1])
        axes[0, 1].set_title("Game Scores")
        axes[0, 1].set_xlabel("Episode")
        axes[0, 1].set_ylabel("Score")
        axes[0, 1].grid(True)
        
        # Plot cumulative wins
        wins_df = pd.DataFrame(self.stats["wins"],
                              columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        wins_cumsum = wins_df.cumsum()
        for i in range(self.num_agents):
            axes[1, 0].plot(wins_cumsum[f"Agent_{i+1}"], label=f"Agent_{i+1}")
        
        axes[1, 0].set_title("Cumulative Wins")
        axes[1, 0].set_xlabel("Episode")
        axes[1, 0].set_ylabel("Number of Wins")
        axes[1, 0].grid(True)
        axes[1, 0].legend()
        
        # Plot episode lengths
        pd.DataFrame(self.stats["episode_steps"], columns=["Steps"]).plot(ax=axes[1, 1])
        axes[1, 1].set_title("Episode Lengths")
        axes[1, 1].set_xlabel("Episode")
        axes[1, 1].set_ylabel("Number of Steps")
        axes[1, 1].grid(True)
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.training_dir, "training_progress.png"))
        plt.close()

def run_self_play_training(args):
    """Run the self-play training process"""
    trainer = SelfPlayTrainer(
        num_agents=args.num_agents,
        episodes=args.episodes,
        max_steps_per_episode=args.steps,
        save_interval=args.save_interval
    )
    
    # Setup agents
    trainer.setup_agents()
    
    # Start training
    trainer.self_play_training()
    
    logger.info("Self-play training completed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Self-play training for DQN agents')
    parser.add_argument('--num-agents', type=int, default=5, help='Number of agents to train')
    parser.add_argument('--episodes', type=int, default=1000, help='Number of episodes to train')
    parser.add_argument('--steps', type=int, default=500, help='Maximum steps per episode')
    parser.add_argument('--save-interval', type=int, default=10, help='Save models every N episodes')
    
    args = parser.parse_args()
    run_self_play_training(args)
