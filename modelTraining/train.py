#!/usr/bin/env python3
"""
Training script for DQN agents
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
        logging.FileHandler("training.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class Trainer:
    """Handles the training of DQN agents"""
    
    def __init__(
        self,
        environment,
        num_agents: int = 5,
        episodes: int = 1000,
        max_steps_per_episode: int = 500,
        save_interval: int = 10,
        max_api_calls_per_turn: int = 20
    ):
        """Initialize the trainer"""
        self.environment = environment
        self.num_agents = num_agents
        self.episodes = episodes
        self.max_steps_per_episode = max_steps_per_episode
        self.save_interval = save_interval
        self.max_api_calls_per_turn = max_api_calls_per_turn
        
        # Action space size - must match GameEnvironment actions
        self.action_space = 8  # Updated to match GameEnvironment action count
        
        self.parameter_generator = ActionParameterGenerator(environment)
        
        # Training statistics
        self.training_stats = {
            'episode_rewards': [],
            'episode_lengths': [],
            'api_calls_per_episode': [],
            'rounds_per_episode': [],
            'ai_performance': {i: [] for i in range(num_agents)}
        }
        self.agents = []
        
        # Create agents
        self.setup_agents()
        
    def setup_agents(self):
        """Setup DQN agents"""
        try:
            # Calculate state size based on the new flattened state vector from GameEnvironment
            # From _get_state method: terrain(1600) + resources(1600) + units(3600) + buildings(2800) + visibility(400) + combat(400) + global_resources(4)
            state_size = 1600 + 1600 + 3600 + 2800 + 400 + 400 + 4  # = 10404
            state_shape = (state_size,)
            
            for i in range(self.num_agents):
                agent = DQNAgent(
                    state_shape=state_shape,
                    action_space=self.action_space,
                    learning_rate=1e-4,
                    gamma=0.99,
                    epsilon=1.0,
                    epsilon_decay=0.995,
                    epsilon_min=0.1,
                    batch_size=64,
                    update_target_freq=1000,
                    memory_size=10000
                )
                self.agents.append(agent)
                
            logger.info(f"Created {self.num_agents} agents with state shape {state_shape} "
                       f"and action space {self.action_space}")
        except Exception as e:
            logger.error(f"Error setting up agents: {e}")
            raise
    
    def _save_models(self, suffix: str):
        """Save all agent models"""
        try:
            save_dir = os.path.join("models", f"checkpoint_{suffix}")
            os.makedirs(save_dir, exist_ok=True)
            
            for i, agent in enumerate(self.agents):
                filename = os.path.join(save_dir, f"agent_{i+1}.h5")
                agent.save_model(filename)
                
            logger.info(f"Saved all agent models to {save_dir}")
        except Exception as e:
            logger.error(f"Error saving models: {e}")
            
    def _load_models(self, suffix: str):
        """Load all agent models"""
        try:
            load_dir = os.path.join("models", f"checkpoint_{suffix}")
            
            for i, agent in enumerate(self.agents):
                filename = os.path.join(load_dir, f"agent_{i+1}.h5")
                if os.path.exists(filename):
                    agent.load_model(filename)
                    
            logger.info(f"Loaded all agent models from {load_dir}")
        except Exception as e:
            logger.error(f"Error loading models: {e}")
            
    def train_agents(self):
        """Train all agents using the multi-AI turn management system"""
        logger.info(f"Starting training for {self.num_agents} agents for {self.episodes} episodes")
        
        try:
            for episode in tqdm(range(self.episodes)):
                # Reset environment for new episode
                state = self.environment.reset()
                
                episode_rewards = []
                episode_losses = []
                episode_steps = 0
                episode_api_calls = 0
                
                # Track performance per AI
                ai_rewards = {i: 0 for i in range(self.num_agents)}
                ai_steps = {i: 0 for i in range(self.num_agents)}
                
                while episode_steps < self.max_steps_per_episode:
                    # Get current AI index from environment
                    current_ai_index = self.environment.current_ai_index
                    current_agent = self.agents[current_ai_index]
                    
                    # Get action from current agent
                    action = current_agent.act(state)
                    
                    # Generate action parameters if needed
                    action_params = self.parameter_generator.generate_params_for_action(action)
                    
                    # Take action in environment
                    next_state, reward, done, info = self.environment.step(action, action_params)
                    
                    # Store experience for current agent
                    current_agent.remember(state, action, reward, next_state, done)
                    
                    # Train current agent if enough experience
                    if len(current_agent.memory) > current_agent.batch_size:
                        loss = current_agent.train()
                        episode_losses.append(loss)
                    
                    # Update statistics
                    ai_rewards[current_ai_index] += reward
                    ai_steps[current_ai_index] += 1
                    episode_steps += 1
                    episode_api_calls += info.get('api_calls_used', 0)
                    
                    state = next_state
                    
                    # Log AI performance periodically
                    if episode_steps % 50 == 0:
                        logger.info(f"Episode {episode + 1}, Step {episode_steps}: "
                                  f"Current AI: {current_ai_index + 1}, "
                                  f"Round: {info.get('round_counter', 0)}, "
                                  f"API calls used: {info.get('api_calls_used', 0)}/{self.max_api_calls_per_turn}, "
                                  f"Reward: {reward:.2f}")
                    
                    if done:
                        logger.info(f"Episode {episode + 1} finished after {episode_steps} steps")
                        break
                
                # Calculate episode statistics
                total_reward = sum(ai_rewards.values())
                avg_loss = np.mean(episode_losses) if episode_losses else 0
                
                episode_rewards.append(total_reward)
                self.training_stats['episode_rewards'].append(total_reward)
                self.training_stats['episode_lengths'].append(episode_steps)
                self.training_stats['api_calls_per_episode'].append(episode_api_calls)
                self.training_stats['rounds_per_episode'].append(info.get('round_counter', 0))
                
                # Track individual AI performance
                for ai_idx in range(self.num_agents):
                    self.training_stats['ai_performance'][ai_idx].append(ai_rewards[ai_idx])
                
                # Save models periodically
                if (episode + 1) % self.save_interval == 0:
                    self._save_models(f"episode_{episode + 1}")
                    self._save_training_stats()
                    
                # Log episode summary
                logger.info(f"Episode {episode + 1} Summary:")
                logger.info(f"  Total Reward: {total_reward:.2f}")
                logger.info(f"  Steps: {episode_steps}")
                logger.info(f"  API Calls: {episode_api_calls}")
                logger.info(f"  Rounds: {info.get('round_counter', 0)}")
                logger.info(f"  Average Loss: {avg_loss:.4f}")
                logger.info(f"  AI Rewards: {ai_rewards}")
                
                # Update epsilon for all agents
                for agent in self.agents:
                    agent.update_epsilon()
                
        except KeyboardInterrupt:
            logger.info("Training interrupted by user")
            self._save_models("interrupted")
            self._save_training_stats()
        except Exception as e:
            logger.error(f"Error during training: {e}", exc_info=True)
            self._save_models("error")
            self._save_training_stats()
    
    def _save_training_stats(self):
        """Save detailed training statistics"""
        try:
            import json
            stats_dir = "training_stats"
            os.makedirs(stats_dir, exist_ok=True)
            
            # Save statistics as JSON
            with open(os.path.join(stats_dir, "training_stats.json"), 'w') as f:
                json.dump(self.training_stats, f, indent=2)
            
            # Save as CSV for easy analysis
            rewards_df = pd.DataFrame({
                'episode': range(len(self.training_stats['episode_rewards'])),
                'total_reward': self.training_stats['episode_rewards'],
                'episode_length': self.training_stats['episode_lengths'],
                'api_calls': self.training_stats['api_calls_per_episode'],
                'rounds': self.training_stats['rounds_per_episode']
            })
            rewards_df.to_csv(os.path.join(stats_dir, "episode_stats.csv"), index=False)
            
            # Save individual AI performance
            ai_performance_df = pd.DataFrame(self.training_stats['ai_performance'])
            ai_performance_df.to_csv(os.path.join(stats_dir, "ai_performance.csv"), index=False)
            
            logger.info(f"Saved training statistics to {stats_dir}")
        except Exception as e:
            logger.error(f"Error saving training statistics: {e}")

    def _save_stats(self):
        """Save training statistics to CSV"""
        # Episode rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                 columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.to_csv(os.path.join(self.training_dir, "rewards.csv"), index=False)
        
        # Episode lengths
        lengths_df = pd.DataFrame(self.stats["episode_lengths"],
                                  columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        lengths_df.to_csv(os.path.join(self.training_dir, "lengths.csv"), index=False)
    
    def _plot_training_progress(self):
        """Plot training progress charts"""
        # Create figure with four subplots
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
        
        # Plot rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.plot(ax=ax1)
        ax1.set_title("Episode Rewards")
        ax1.set_xlabel("Episode")
        ax1.set_ylabel("Total Reward")
        ax1.grid(True)
        
        # Plot moving average of rewards
        rewards_ma = rewards_df.rolling(window=10).mean()
        rewards_ma.plot(ax=ax1, linestyle='--', linewidth=2)
        
        # Plot episode lengths
        lengths_df = pd.DataFrame(self.stats["episode_lengths"],
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        lengths_df.plot(ax=ax2)
        ax2.set_title("Episode Lengths")
        ax2.set_xlabel("Episode")
        ax2.set_ylabel("Number of Steps")
        ax2.grid(True)
        
        # Plot territory control
        territory_df = pd.DataFrame(self.stats["win_rates"],
                                  columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        territory_df.plot(ax=ax3)
        ax3.set_title("Territory Control %")
        ax3.set_xlabel("Episode")
        ax3.set_ylabel("Territory Control")
        ax3.grid(True)
        
        # Plot average scores components
        scores_df = pd.DataFrame(
            self.stats["avg_scores"],
            columns=["Reward", "Steps", "Territory", "Resources"]
        )
        scores_ma = scores_df.rolling(window=10).mean()
        scores_ma.plot(ax=ax4)
        ax4.set_title("Training Metrics (10-episode moving average)")
        ax4.set_xlabel("Episode")
        ax4.set_ylabel("Value")
        ax4.grid(True)
        ax4.legend()
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.training_dir, "training_progress.png"))
        plt.close()

def run_training(args):
    """Run the training process"""
    environment = GameEnvironment(max_api_calls_per_turn=args.max_api_calls)
    trainer = Trainer(
        environment=environment,
        num_agents=args.num_agents,
        episodes=args.episodes,
        max_steps_per_episode=args.steps,
        save_interval=args.save_interval
    )
    
    # Setup agents
    trainer.setup_agents()
    
    # Start training
    trainer.train_agents()
    
    logger.info("Training completed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Train DQN agents for the game')
    parser.add_argument('--num-agents', type=int, default=5, help='Number of agents to train')
    parser.add_argument('--episodes', type=int, default=1000, help='Number of episodes to train')
    parser.add_argument('--steps', type=int, default=500, help='Maximum steps per episode')
    parser.add_argument('--save-interval', type=int, default=10, help='Save models every N episodes')
    parser.add_argument('--max-api-calls', type=int, default=20, help='Max API calls per turn')
    
    args = parser.parse_args()
    run_training(args)
