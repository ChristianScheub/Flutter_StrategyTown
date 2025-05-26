# Game AI Training System

This project implements an AI training system that uses the Game API Service to train reinforcement learning agents. These agents learn to play the game effectively and can compete against each other through self-play. The system supports both simple neural networks and TensorFlow-based models.

## Overview

The training system:
1. Connects to the Game API running on localhost:8080
2. Trains multiple AI models with different parameters
3. Uses reinforcement learning to improve through gameplay
4. Has models compete against each other in self-play
5. Evaluates and ranks models based on performance
6. Converts the best models to TensorFlow format for advanced use

## Setup

1. Ensure the Game API Service is running at `http://localhost:8080`:

```bash
# Start the backend service (in a separate terminal)
cd ../backend_service && ./run_server.sh
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run the setup script:

```bash
chmod +x setup.sh
./setup.sh
```

## Quick Start - Complete Training Pipeline

To run the complete training pipeline in one step:

```bash
./run_training_pipeline.sh
```

This script will:
- Check if the backend service is running
- Train 5 different AI models
- Run self-play tournaments
- Evaluate all models against each other
- Convert models to TensorFlow format (if available)
- Generate visualizations of training results

## Project Structure

- `game_api_client.py`: Python wrapper for the Game API Service
- `game_environment.py`: Environment that interfaces with the game API for reinforcement learning
- `simple_agent.py`: Implementation of a basic neural network agent
- `dqn_agent.py`: Implementation of the Deep Q-Network agent (requires TensorFlow)
- `parameter_generator.py`: Generates valid action parameters for the game
- `train.py`: Script for training multiple agents independently
- `self_play.py`: Script for training agents through self-play
- `evaluate.py`: Script for evaluating trained agents
- `visualize_results.py`: Script for visualizing training results
- `convert_to_tensorflow.py`: Converts simple models to TensorFlow format

## Training Models Individually

To train multiple independent agents:

```bash
python simple_agent.py --num-agents 5 --episodes 200 --save-interval 20
```

Options:
- `--num-agents`: Number of agents to train (default: 5)
- `--episodes`: Number of training episodes (default: 200)
- `--save-interval`: Interval for saving models (default: 20)

## Self-Play Training

To train agents through self-play (where agents compete against each other):

```bash
python self_play.py --iterations 50 --matches 20
```

Options:
- `--iterations`: Number of training iterations (default: 50) 
- `--matches`: Number of matches per iteration (default: 20)
- `--models`: Path pattern for models to use in self-play (default: "models/agent_*.h5")

## Evaluating Models

To evaluate trained models:

```bash
python evaluate.py --models models/agent_*.h5 --matches 30
```

Options:
- `--models`: Path pattern for models to evaluate (default: "models/agent_*.h5")
- `--matches`: Number of evaluation matches (default: 30)
- `--output`: Output directory for evaluation results (default: "evaluation/logs")

## Converting Models to TensorFlow

Once you have trained models, you can convert them to TensorFlow format:

```bash
python convert_to_tensorflow.py --input-dir models --output-dir models/tensorflow
```

Options:
- `--input-dir`: Directory containing H5 model files (default: "models")
- `--output-dir`: Directory to save TensorFlow models (default: "models/tensorflow")
- `--input-model`: Specific model file to convert (optional)
- `--output-model`: Output path for specific model (optional)

## Visualizing Results

To visualize training or evaluation results:

```bash
python visualize_results.py --training-logs training/logs --evaluation-logs evaluation/logs
```

This will generate performance charts, score comparisons, and win-rate visualizations.

## Game API Integration

The training system integrates with the Game API Service running on `localhost:8080`. The architecture of this integration:

### API Layer
- `game_api_client.py`: A Python wrapper for the HTTP API
- Handles all requests to the Game API Service
- Manages sessions, errors, and response parsing

### Environment Layer
- `game_environment.py`: Reinforcement learning environment
- Translates game states to vector representations for ML models
- Translates model actions into API calls
- Calculates rewards based on game outcomes

### Agent Layer
- `simple_agent.py`: Neural network agent with NumPy
- `dqn_agent.py`: Deep Q-Network agent with TensorFlow
- Makes decisions based on game state
- Learns from reinforcement signals

## Training Process

The training process involves:

1. **Initialization**: Start a new game via the Game API
2. **State Observation**: Get the current game state from the API
3. **Decision Making**: Agent selects an action based on the state
4. **Action Execution**: Execute the action through the API
5. **Reward Calculation**: Calculate rewards based on score changes and game outcomes
6. **Learning**: Update the agent's neural network based on rewards
7. **Iteration**: Repeat until the episode ends
8. **Model Saving**: Save the trained neural network at regular intervals

Key reinforcement learning concepts:
- **Rewards**: Agents receive rewards for increasing score, building cities, collecting resources
- **Penalties**: Agents receive penalties for inactivity, losing units, or illegal moves
- **Exploration vs. Exploitation**: Balance between trying new actions and exploiting known good strategies
- **Experience Replay**: Learning from past experiences to improve decision making

## Model Architecture

The neural network architecture used:

1. **Input**: Game state representation (features extracted from the Game API)
2. **Hidden Layers**: Multiple dense layers with ReLU activation
3. **Output**: Action values for each possible game action

### Simple Agent Model:
- Input → Dense(128) → ReLU → Dense(64) → ReLU → Output

### DQN Agent Model (when TensorFlow is available):
- Input → Conv2D → MaxPooling → Conv2D → MaxPooling → Flatten → Dense → ReLU → Dense → Output

## Future Improvements

Potential extensions to this training system:

1. **Actor-Critic Architecture**: Implement actor-critic models for better policy learning
2. **Distributed Training**: Train multiple agents in parallel across multiple instances
3. **Curriculum Learning**: Progressive difficulty increase during training
4. **Meta-Learning**: Train models that can adapt quickly to new game scenarios
5. **Multi-Modal Input**: Incorporate additional game information beyond the basic state
