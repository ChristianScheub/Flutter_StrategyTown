#!/usr/bin/env python3
"""
Script to visualize training results and compare models
"""

import os
import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from typing import List, Dict, Any

def load_training_data(data_dir: str) -> Dict[str, Any]:
    """Load training data from CSV files"""
    data = {}
    
    # Load rewards data
    rewards_path = os.path.join(data_dir, "rewards.csv")
    if os.path.exists(rewards_path):
        data["rewards"] = pd.read_csv(rewards_path)
    
    # Load scores data
    scores_path = os.path.join(data_dir, "scores.csv")
    if os.path.exists(scores_path):
        data["scores"] = pd.read_csv(scores_path)
    
    # Load wins data
    wins_path = os.path.join(data_dir, "wins.csv")
    if os.path.exists(wins_path):
        data["wins"] = pd.read_csv(wins_path)
    
    # Load steps data
    steps_path = os.path.join(data_dir, "steps.csv")
    if os.path.exists(steps_path):
        data["steps"] = pd.read_csv(steps_path)
        
    # Load summary data
    summary_path = os.path.join(data_dir, "summary.csv")
    if os.path.exists(summary_path):
        data["summary"] = pd.read_csv(summary_path)
    
    return data

def plot_agent_performance(data: Dict[str, Any], output_dir: str):
    """Create detailed performance plots for each agent"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Get number of agents
    if "rewards" in data:
        num_agents = len(data["rewards"].columns)
    elif "scores" in data:
        num_agents = len(data["scores"].columns)
    else:
        print("No agent data found")
        return
    
    # For each agent
    for i in range(num_agents):
        agent_name = f"Agent_{i+1}"
        
        fig, axes = plt.subplots(2, 2, figsize=(15, 12))
        fig.suptitle(f"{agent_name} Performance", fontsize=16)
        
        # Plot rewards over time
        if "rewards" in data:
            ax = axes[0, 0]
            rewards = data["rewards"][agent_name]
            rewards.plot(ax=ax, label="Per Episode")
            
            # Plot moving average
            window_size = min(20, len(rewards))
            if window_size > 1:
                rewards.rolling(window=window_size).mean().plot(
                    ax=ax, color='red', linewidth=2, label=f"{window_size}-Ep Moving Avg"
                )
                
            ax.set_title(f"{agent_name} Rewards")
            ax.set_xlabel("Episode")
            ax.set_ylabel("Reward")
            ax.grid(True)
            ax.legend()
        
        # Plot scores over time
        if "scores" in data:
            ax = axes[0, 1]
            scores = data["scores"][agent_name]
            scores.plot(ax=ax, label="Per Episode")
            
            # Plot moving average
            window_size = min(20, len(scores))
            if window_size > 1:
                scores.rolling(window=window_size).mean().plot(
                    ax=ax, color='red', linewidth=2, label=f"{window_size}-Ep Moving Avg"
                )
                
            ax.set_title(f"{agent_name} Game Scores")
            ax.set_xlabel("Episode")
            ax.set_ylabel("Score")
            ax.grid(True)
            ax.legend()
        
        # Plot cumulative wins
        if "wins" in data:
            ax = axes[1, 0]
            wins = data["wins"][agent_name]
            cumulative_wins = wins.cumsum()
            cumulative_wins.plot(ax=ax)
            
            # Add win rate
            episodes = np.arange(1, len(wins) + 1)
            win_rate = cumulative_wins / episodes
            
            ax2 = ax.twinx()
            win_rate.plot(ax=ax2, color='red', linestyle='--')
            
            ax.set_title(f"{agent_name} Wins")
            ax.set_xlabel("Episode")
            ax.set_ylabel("Cumulative Wins", color='blue')
            ax2.set_ylabel("Win Rate", color='red')
            ax.grid(True)
        
        # Plot win rate comparison (all agents)
        if "wins" in data and "summary" in data:
            ax = axes[1, 1]
            
            # For all agents, calculate win rates over time
            win_rates = {}
            for j in range(num_agents):
                other_agent = f"Agent_{j+1}"
                wins_series = data["wins"][other_agent]
                episodes = np.arange(1, len(wins_series) + 1)
                win_rates[other_agent] = wins_series.cumsum() / episodes
            
            # Plot win rates for all agents
            win_rates_df = pd.DataFrame(win_rates)
            win_rates_df.plot(ax=ax)
            
            ax.set_title("Win Rate Comparison")
            ax.set_xlabel("Episode")
            ax.set_ylabel("Win Rate")
            ax.grid(True)
            ax.legend()
        
        plt.tight_layout()
        plt.subplots_adjust(top=0.92)
        plt.savefig(os.path.join(output_dir, f"{agent_name}_performance.png"))
        plt.close()

def plot_comparison_charts(data: Dict[str, Any], output_dir: str):
    """Create comparison charts between all agents"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Summary barplots
    if "summary" in data:
        summary = data["summary"]
        
        # Get metrics to plot
        metrics = [col for col in summary.columns if col != "Agent"]
        
        for metric in metrics:
            plt.figure(figsize=(10, 6))
            
            # Sort by the metric for better visualization
            sorted_summary = summary.sort_values(by=metric)
            
            sns.barplot(x="Agent", y=metric, data=sorted_summary)
            plt.title(f"Comparison of {metric} Across Agents")
            plt.xlabel("Agent")
            plt.ylabel(metric)
            plt.grid(True, axis='y')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, f"comparison_{metric}.png"))
            plt.close()
    
    # Line plots comparing performance over time
    for metric_name, metric_data in data.items():
        if metric_name in ["rewards", "scores", "wins"]:
            plt.figure(figsize=(12, 6))
            
            # Smooth data with rolling average
            window_size = min(20, metric_data.shape[0])
            if window_size > 1:
                smoothed_data = metric_data.rolling(window=window_size).mean()
                
                for column in smoothed_data.columns:
                    plt.plot(smoothed_data.index, smoothed_data[column], label=column)
            else:
                for column in metric_data.columns:
                    plt.plot(metric_data.index, metric_data[column], label=column)
                
            plt.title(f"Comparison of {metric_name.capitalize()} (Rolling Avg)")
            plt.xlabel("Episode")
            plt.ylabel(metric_name.capitalize())
            plt.grid(True)
            plt.legend()
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, f"comparison_{metric_name}_over_time.png"))
            plt.close()

def generate_summary_report(data: Dict[str, Any], output_dir: str):
    """Generate a textual summary report"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    report = []
    report.append("# Training Results Summary Report\n")
    
    # Overall statistics
    report.append("## Overall Statistics\n")
    
    if "steps" in data:
        steps = data["steps"]
        report.append(f"- Total Episodes: {len(steps)}")
        report.append(f"- Average Episode Length: {steps['Steps'].mean():.2f} steps")
        report.append(f"- Longest Episode: {steps['Steps'].max()} steps")
        report.append(f"- Shortest Episode: {steps['Steps'].min()} steps")
        report.append("")
    
    # Agent performance summary
    if "summary" in data:
        report.append("## Agent Performance\n")
        summary = data["summary"]
        
        # Format summary in a table
        report.append("| Agent | Average Reward | Average Score | Win Rate | Wins |")
        report.append("| ----- | ------------- | ------------ | -------- | ---- |")
        
        for _, row in summary.iterrows():
            agent = row["Agent"]
            
            avg_reward = row.get("Avg_Reward", "N/A")
            if avg_reward != "N/A":
                avg_reward = f"{avg_reward:.2f}"
                
            avg_score = row.get("Avg_Score", "N/A")
            if avg_score != "N/A":
                avg_score = f"{avg_score:.2f}"
                
            win_rate = row.get("Win_Rate", "N/A")
            if win_rate != "N/A":
                win_rate = f"{win_rate:.2%}"
                
            wins = row.get("Wins", "N/A")
            if wins != "N/A":
                wins = f"{int(wins)}"
                
            report.append(f"| {agent} | {avg_reward} | {avg_score} | {win_rate} | {wins} |")
        
        report.append("")
    
    # Best performing agent
    report.append("## Best Performing Agent\n")
    
    if "summary" in data and "Win_Rate" in data["summary"].columns:
        best_agent_idx = data["summary"]["Win_Rate"].idxmax()
        best_agent = data["summary"].iloc[best_agent_idx]
        
        report.append(f"- **Best Agent:** {best_agent['Agent']}")
        report.append(f"- **Win Rate:** {best_agent['Win_Rate']:.2%}")
        
        if "Avg_Score" in best_agent:
            report.append(f"- **Average Score:** {best_agent['Avg_Score']:.2f}")
        if "Avg_Reward" in best_agent:
            report.append(f"- **Average Reward:** {best_agent['Avg_Reward']:.2f}")
        if "Wins" in best_agent:
            report.append(f"- **Total Wins:** {int(best_agent['Wins'])}")
            
        report.append("")
    
    # Training trend analysis
    report.append("## Training Trend Analysis\n")
    
    if "rewards" in data:
        # Get the last agent column
        agent_columns = data["rewards"].columns
        if len(agent_columns) > 0:
            last_agent = agent_columns[-1]
            rewards = data["rewards"][last_agent]
            
            # Split into quarters
            quarter_len = len(rewards) // 4
            
            if quarter_len > 0:
                q1_rewards = rewards.iloc[:quarter_len].mean()
                q2_rewards = rewards.iloc[quarter_len:quarter_len*2].mean()
                q3_rewards = rewards.iloc[quarter_len*2:quarter_len*3].mean()
                q4_rewards = rewards.iloc[quarter_len*3:].mean()
                
                report.append("### Average Rewards by Training Quarter")
                report.append(f"- First Quarter: {q1_rewards:.2f}")
                report.append(f"- Second Quarter: {q2_rewards:.2f}")
                report.append(f"- Third Quarter: {q3_rewards:.2f}")
                report.append(f"- Fourth Quarter: {q4_rewards:.2f}")
                
                # Calculate improvement
                improvement = (q4_rewards - q1_rewards) / abs(q1_rewards) if q1_rewards != 0 else float('inf')
                report.append(f"- **Overall Improvement:** {improvement:.2%}")
                report.append("")
    
    # Write the report
    with open(os.path.join(output_dir, "summary_report.md"), "w") as f:
        f.write("\n".join(report))
    
    return "\n".join(report)

def main(args):
    """Main function to visualize training results"""
    data_dir = args.data_dir
    output_dir = args.output_dir if args.output_dir else os.path.join(data_dir, "visualizations")
    
    print(f"Loading data from: {data_dir}")
    data = load_training_data(data_dir)
    
    if not data:
        print("No data found in the specified directory.")
        return
    
    print(f"Generating visualizations in: {output_dir}")
    
    # Create individual agent performance charts
    plot_agent_performance(data, output_dir)
    
    # Create comparison charts
    plot_comparison_charts(data, output_dir)
    
    # Generate summary report
    report = generate_summary_report(data, output_dir)
    print("Summary report generated. First few lines:")
    print("\n".join(report.split("\n")[:10]) + "\n...")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Visualize AI training results")
    parser.add_argument("data_dir", type=str, help="Directory containing training data CSV files")
    parser.add_argument("--output-dir", type=str, help="Directory to save visualizations (default: data_dir/visualizations)")
    
    args = parser.parse_args()
    main(args)
