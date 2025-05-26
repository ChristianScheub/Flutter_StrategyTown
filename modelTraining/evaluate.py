#!/usr/bin/env python3
"""
Evaluation script for trained agents
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
        logging.FileHandler("evaluation.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class Evaluator:
    """Evaluates trained DQN agents"""
    
    def __init__(
        self,
        model_paths: List[str],
        episodes: int = 50,
        max_steps_per_episode: int = 1000
    ):
        """Initialize the evaluator"""
        self.model_paths = model_paths
        self.num_agents = len(model_paths)
        self.episodes = episodes
        self.max_steps_per_episode = max_steps_per_episode
        
        # Set up environments and agents
        self.environments = []
        self.agents = []
        self.param_generators = []
        
        # Create evaluation directory
        self.eval_dir = os.path.join("evaluation", f"run_{int(time.time())}")
        os.makedirs(self.eval_dir, exist_ok=True)
        
        # Evaluation statistics
        self.stats = {
            "episode_rewards": [],
            "episode_lengths": [],
            "final_scores": [],
            "wins": []
        }
        
    def setup_agents(self):
        """Set up environments and agents"""
        for i in range(self.num_agents):
            # Create environment
            env = GameEnvironment(player_name=f"AI_Agent_{i+1}")
            self.environments.append(env)
            
            # Create parameter generator
            param_gen = ActionParameterGenerator(env)
            self.param_generators.append(param_gen)
            
            # Create agent
            state_shape = (5, env.MAP_SIZE_X, env.MAP_SIZE_Y)  # Example: (channels, height, width)
            action_space = 7  # Number of action types
            
            agent = DQNAgent(
                state_shape=state_shape,
                action_space=action_space,
                model_name=f"agent_{i+1}",
                epsilon=0.05,  # Low exploration during evaluation
                epsilon_min=0.01
            )
            
            # Load pre-trained model
            model_path = self.model_paths[i]
            agent.load_model(model_path)
            
            self.agents.append(agent)
            
            logger.info(f"Loaded agent {i+1} from model {model_path}")
    
    def evaluate_agents(self):
        """Evaluate all agents"""
        logger.info(f"Starting evaluation for {self.num_agents} agents for {self.episodes} episodes")
        
        for episode in tqdm(range(self.episodes)):
            episode_rewards = np.zeros(self.num_agents)
            episode_steps = np.zeros(self.num_agents, dtype=int)
            final_scores = np.zeros(self.num_agents)
            
            # Reset all environments
            states = []
            for env in self.environments:
                state = env.reset()
                states.append(state)
            
            # Evaluate each agent for one episode
            for agent_idx in range(self.num_agents):
                env = self.environments[agent_idx]
                agent = self.agents[agent_idx]
                param_gen = self.param_generators[agent_idx]
                
                state = states[agent_idx]
                done = False
                total_reward = 0
                step = 0
                
                while not done and step < self.max_steps_per_episode:
                    # Choose an action
                    action = agent.choose_action(state)
                    
                    # Generate appropriate parameters
                    action_params = param_gen.generate_params_for_action(action)
                    
                    # Take a step
                    next_state, reward, done, info = env.step(action, action_params)
                    
                    # Update state and tracking variables
                    state = next_state
                    total_reward += reward
                    step += 1
                    
                    # Log every 100 steps
                    if step % 100 == 0:
                        logger.debug(f"Agent {agent_idx+1}, Episode {episode+1}, Step {step}: Reward {reward:.2f}")
                
                # Update episode stats
                episode_rewards[agent_idx] = total_reward
                episode_steps[agent_idx] = step
                final_scores[agent_idx] = env._get_player_score()
                
                logger.info(f"Agent {agent_idx+1} - Episode {episode+1}: "
                            f"Total Reward: {total_reward:.2f}, Steps: {step}, "
                            f"Final Score: {final_scores[agent_idx]}")
            
            # Determine winner based on final scores
            winner_idx = np.argmax(final_scores) if np.max(final_scores) > 0 else -1
            winners = np.zeros(self.num_agents)
            if winner_idx >= 0:
                winners[winner_idx] = 1
            
            # Store statistics
            self.stats["episode_rewards"].append(episode_rewards.tolist())
            self.stats["episode_lengths"].append(episode_steps.tolist())
            self.stats["final_scores"].append(final_scores.tolist())
            self.stats["wins"].append(winners.tolist())
            
            # Log episode summary
            logger.info(f"Episode {episode+1} complete. "
                       f"Winner: Agent_{winner_idx+1 if winner_idx >= 0 else 'None'} "
                       f"with score {np.max(final_scores)}")
            
            # Save stats periodically
            if (episode + 1) % 10 == 0:
                self._save_stats()
                self._plot_results()
    
    def _save_stats(self):
        """Save evaluation statistics to CSV"""
        # Episode rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                 columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.to_csv(os.path.join(self.eval_dir, "eval_rewards.csv"), index=False)
        
        # Episode lengths
        lengths_df = pd.DataFrame(self.stats["episode_lengths"],
                                  columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        lengths_df.to_csv(os.path.join(self.eval_dir, "eval_lengths.csv"), index=False)
        
        # Final scores
        scores_df = pd.DataFrame(self.stats["final_scores"],
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        scores_df.to_csv(os.path.join(self.eval_dir, "eval_scores.csv"), index=False)
        
        # Wins
        wins_df = pd.DataFrame(self.stats["wins"],
                              columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        wins_df.to_csv(os.path.join(self.eval_dir, "eval_wins.csv"), index=False)
        
        # Summary stats
        summary = {
            "Agent": [f"Agent_{i+1}" for i in range(self.num_agents)],
            "Avg_Reward": np.mean(self.stats["episode_rewards"], axis=0),
            "Avg_Score": np.mean(self.stats["final_scores"], axis=0),
            "Win_Rate": np.mean(self.stats["wins"], axis=0),
            "Avg_Episode_Length": np.mean(self.stats["episode_lengths"], axis=0)
        }
        
        summary_df = pd.DataFrame(summary)
        summary_df.to_csv(os.path.join(self.eval_dir, "eval_summary.csv"), index=False)
    
    def _plot_results(self):
        """Plot evaluation results"""
        # Create figures for displaying results
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        
        # Plot episode rewards
        rewards_df = pd.DataFrame(self.stats["episode_rewards"], 
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        rewards_df.plot(ax=axes[0, 0])
        axes[0, 0].set_title("Episode Rewards")
        axes[0, 0].set_xlabel("Episode")
        axes[0, 0].set_ylabel("Total Reward")
        axes[0, 0].grid(True)
        
        # Plot final scores
        scores_df = pd.DataFrame(self.stats["final_scores"],
                                columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        scores_df.plot(ax=axes[0, 1])
        axes[0, 1].set_title("Final Game Scores")
        axes[0, 1].set_xlabel("Episode")
        axes[0, 1].set_ylabel("Score")
        axes[0, 1].grid(True)
        
        # Plot win rates
        wins_df = pd.DataFrame(self.stats["wins"],
                              columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        wins_cumsum = wins_df.cumsum()
        for i in range(self.num_agents):
            episodes = np.arange(1, len(wins_cumsum) + 1)
            win_rates = wins_cumsum[f"Agent_{i+1}"] / episodes
            axes[1, 0].plot(episodes, win_rates, label=f"Agent_{i+1}")
        
        axes[1, 0].set_title("Cumulative Win Rate")
        axes[1, 0].set_xlabel("Episode")
        axes[1, 0].set_ylabel("Win Rate")
        axes[1, 0].grid(True)
        axes[1, 0].legend()
        
        # Plot episode lengths
        lengths_df = pd.DataFrame(self.stats["episode_lengths"],
                                 columns=[f"Agent_{i+1}" for i in range(self.num_agents)])
        lengths_df.plot(ax=axes[1, 1])
        axes[1, 1].set_title("Episode Lengths")
        axes[1, 1].set_xlabel("Episode")
        axes[1, 1].set_ylabel("Number of Steps")
        axes[1, 1].grid(True)
        
        plt.tight_layout()
        plt.savefig(os.path.join(self.eval_dir, "evaluation_results.png"))
        plt.close()

def run_evaluation(args):
    """Run the evaluation process"""
    # Get model paths from args
    model_paths = []
    for i in range(args.num_agents):
        if i < len(args.model_paths):
            model_paths.append(args.model_paths[i])
        else:
            logger.error(f"Missing model path for agent {i+1}")
            return
    
    evaluator = Evaluator(
        model_paths=model_paths,
        episodes=args.episodes,
        max_steps_per_episode=args.steps
    )
    
    # Setup agents
    evaluator.setup_agents()
    
    # Start evaluation
    evaluator.evaluate_agents()
    
    # Final stats
    evaluator._save_stats()
    evaluator._plot_results()
    
    logger.info("Evaluation completed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Evaluate trained DQN agents')
    parser.add_argument('--num-agents', type=int, default=5, help='Number of agents to evaluate')
    parser.add_argument('--episodes', type=int, default=50, help='Number of episodes to evaluate')
    parser.add_argument('--steps', type=int, default=1000, help='Maximum steps per episode')
    parser.add_argument('--model-paths', nargs='+', required=True, 
                        help='Paths to the trained models to evaluate')
    
    args = parser.parse_args()
    run_evaluation(args)
