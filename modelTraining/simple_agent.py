#!/usr/bin/env python3
"""
Simple model generator that creates a basic policy neural network compatible with TensorFlow.
This script will generate a TensorFlow-compatible model without requiring TensorFlow for training.
The model can then be loaded by TensorFlow when needed.
"""

import os
import numpy as np
import joblib
from collections import deque
from game_environment import GameEnvironment
import random
import logging
import json
from typing import Dict, List, Tuple, Any
import h5py

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SimpleAgent:
    """A simple reinforcement learning agent that can be converted to TensorFlow format"""
    
    def __init__(self, state_size, action_size, name="simple_agent"):
        """Initialize agent parameters"""
        self.state_size = state_size
        self.action_size = action_size
        self.name = name
        
        # Learning parameters
        self.gamma = 0.99  # discount factor
        self.epsilon = 1.0  # exploration rate
        self.epsilon_min = 0.1  # minimum exploration rate
        self.epsilon_decay = 0.995  # decay rate for exploration
        self.learning_rate = 0.001  # learning rate
        
        # Create simple model as NumPy weights
        # This represents weights of a simple neural network:
        # Input layer -> Hidden layer -> Output layer
        self.weights = {
            # Input layer to hidden layer (3 layers, 128 hidden neurons)
            'W1': np.random.randn(15000, 128) * 0.1,  # 15000 = 6 * 50 * 50 (flattened state size)
            'b1': np.zeros(128),
            
            # Hidden layer to hidden layer
            'W2': np.random.randn(128, 64) * 0.1,
            'b2': np.zeros(64),
            
            # Hidden layer to output layer
            'W3': np.random.randn(64, action_size) * 0.1,
            'b3': np.zeros(action_size),
        }
        
        # Memory for experience replay
        self.memory = deque(maxlen=2000)
        
    def remember(self, state, action, reward, next_state, done):
        """Store experience in memory"""
        self.memory.append((state, action, reward, next_state, done))
    
    def forward(self, state):
        """Forward pass through the network using numpy"""
        # Make sure state is in the right shape
        if len(state.shape) == 3:  # If shape is (6, 50, 50)
            state = state.reshape(1, -1)  # Flatten to (1, 15000)
        elif len(state.shape) == 1:
            state = state.reshape(1, -1)
            
        # Layer 1
        z1 = np.dot(state, self.weights['W1']) + self.weights['b1']
        a1 = np.maximum(0, z1)  # ReLU activation
        
        # Layer 2
        z2 = np.dot(a1, self.weights['W2']) + self.weights['b2']
        a2 = np.maximum(0, z2)  # ReLU activation
        
        # Output layer
        z3 = np.dot(a2, self.weights['W3']) + self.weights['b3']
        
        # Return Q-values
        return z3
    
    def act(self, state):
        """Choose an action based on the current state"""
        if np.random.rand() <= self.epsilon:
            return random.randrange(self.action_size)
        
        act_values = self.forward(state)
        return np.argmax(act_values[0])
    
    def replay(self, batch_size=32):
        """Train the model using experiences from memory"""
        if len(self.memory) < batch_size:
            return
            
        # Sample a minibatch from memory
        minibatch = random.sample(self.memory, batch_size)
        
        for state, action, reward, next_state, done in minibatch:
            target = reward
            if not done:
                next_q_values = self.forward(next_state)
                target = reward + self.gamma * np.amax(next_q_values)
            
            # Update the value for the chosen action
            target_f = self.forward(state)
            target_f[0][action] = target
            
            # Update weights using simple gradient descent
            self._update_weights(state, target_f[0])
        
        # Decay epsilon
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
    
    def _update_weights(self, state, target):
        """Simple weight update using gradient descent"""
        # For a real implementation, this would use proper backpropagation
        # This is a simplified update for demonstration purposes
        
        # Forward pass to get current outputs
        # Layer 1
        z1 = np.dot(state, self.weights['W1']) + self.weights['b1']
        a1 = np.maximum(0, z1)  # ReLU
        
        # Layer 2
        z2 = np.dot(a1, self.weights['W2']) + self.weights['b2']
        a2 = np.maximum(0, z2)  # ReLU
        
        # Output layer
        z3 = np.dot(a2, self.weights['W3']) + self.weights['b3']
        
        # Compute simple error
        error = target - z3[0]
        
        # Update output layer
        delta_W3 = np.outer(a2[0], error) * self.learning_rate
        self.weights['W3'] += delta_W3
        self.weights['b3'] += error * self.learning_rate
        
        # Update hidden layers (simplified, not proper backpropagation)
        delta_a2 = np.dot(error, self.weights['W3'].T)
        delta_a1 = np.dot(delta_a2, self.weights['W2'].T)
        
        # Apply ReLU gradient (1 if z > 0 else 0)
        delta_a2 *= (z2 > 0).astype(float)
        delta_a1 *= (z1 > 0).astype(float)
        
        # Update hidden layer weights
        delta_W2 = np.outer(a1[0], delta_a2[0]) * self.learning_rate
        self.weights['W2'] += delta_W2
        self.weights['b2'] += delta_a2[0] * self.learning_rate
        
        # Update input layer weights
        delta_W1 = np.outer(state[0], delta_a1[0]) * self.learning_rate
        self.weights['W1'] += delta_W1
        self.weights['b1'] += delta_a1[0] * self.learning_rate
    
    def save_model(self, filepath):
        """Save the model weights to a file"""
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        joblib.dump(self.weights, filepath + ".joblib")
        
        # Also save in a format that can be loaded by TensorFlow
        self._save_tf_compatible(filepath)
        
        logger.info(f"Model saved to {filepath}")
    
    def load_model(self, filepath):
        """Load the model weights from a file"""
        if os.path.exists(filepath + ".joblib"):
            self.weights = joblib.load(filepath + ".joblib")
            logger.info(f"Model loaded from {filepath}")
        else:
            logger.warning(f"Model file {filepath} not found")
    
    def _save_tf_compatible(self, filepath):
        """Save the model in a format that can be loaded by TensorFlow"""
        # Create an HDF5 file that resembles a TensorFlow saved model
        keras_file = filepath + ".h5"
        
        with h5py.File(keras_file, 'w') as f:
            model_group = f.create_group('model_weights')
            
            # Layer 1
            layer1 = model_group.create_group('layer1')
            layer1.create_dataset('kernel', data=self.weights['W1'])
            layer1.create_dataset('bias', data=self.weights['b1'])
            
            # Layer 2
            layer2 = model_group.create_group('layer2')
            layer2.create_dataset('kernel', data=self.weights['W2'])
            layer2.create_dataset('bias', data=self.weights['b2'])
            
            # Layer 3
            layer3 = model_group.create_group('layer3')
            layer3.create_dataset('kernel', data=self.weights['W3'])
            layer3.create_dataset('bias', data=self.weights['b3'])
            
            # Save additional model config
            model_config = {
                'model_config': {
                    'input_shape': self.state_size,
                    'output_shape': self.action_size,
                    'hidden_layers': [128, 64],
                    'activation': 'relu',
                    'output_activation': 'linear'
                }
            }
            
            f.attrs['model_config'] = json.dumps(model_config)
        
        logger.info(f"TensorFlow-compatible model saved to {keras_file}")
        
        # Create a conversion helper script
        helper_script = """
# Helper script to convert the .h5 file to a full TensorFlow model
import tensorflow as tf
import h5py
import json
import os

def convert_h5_to_tf_model(h5_path, output_dir):
    # Load the H5 file
    h5_file = h5py.File(h5_path, 'r')
    
    # Extract model config
    model_config = json.loads(h5_file.attrs['model_config'])
    
    # Build TensorFlow model based on saved config
    input_size = model_config['model_config']['input_shape']
    output_size = model_config['model_config']['output_shape']
    hidden_layers = model_config['model_config']['hidden_layers']
    
    # Create the model
    model = tf.keras.Sequential()
    model.add(tf.keras.layers.Input(shape=(input_size,)))
    
    # Add hidden layers
    for units in hidden_layers:
        model.add(tf.keras.layers.Dense(units, activation='relu'))
    
    # Add output layer
    model.add(tf.keras.layers.Dense(output_size, activation='linear'))
    
    # Compile the model
    model.compile(optimizer='adam', loss='mse')
    
    # Load weights
    w1 = h5_file['model_weights/layer1/kernel'][()]
    b1 = h5_file['model_weights/layer1/bias'][()]
    w2 = h5_file['model_weights/layer2/kernel'][()]
    b2 = h5_file['model_weights/layer2/bias'][()]
    w3 = h5_file['model_weights/layer3/kernel'][()]
    b3 = h5_file['model_weights/layer3/bias'][()]
    
    # Set weights
    model.layers[0].set_weights([w1, b1])
    model.layers[1].set_weights([w2, b2])
    model.layers[2].set_weights([w3, b3])
    
    # Save the model in TensorFlow format
    model.save(output_dir)
    print(f"Model saved to {output_dir}")

# Example usage
# convert_h5_to_tf_model('models/simple_agent.h5', 'models/tf_model')
"""
        
        with open(filepath + "_converter.py", "w") as f:
            f.write(helper_script)
        
        logger.info(f"TensorFlow converter script saved to {filepath}_converter.py")
        
    def get_model_summary(self):
        """Get a string summary of the model"""
        summary = [
            "Simple Agent Model Summary",
            "-------------------------",
            f"State size: {self.state_size}",
            f"Action size: {self.action_size}",
            f"Learning rate: {self.learning_rate}",
            f"Epsilon: {self.epsilon}",
            "",
            "Layer 1: Dense",
            f"  Input shape: {self.weights['W1'].shape[0]}",
            f"  Output shape: {self.weights['W1'].shape[1]}",
            f"  Activation: ReLU",
            "",
            "Layer 2: Dense",
            f"  Input shape: {self.weights['W2'].shape[0]}",
            f"  Output shape: {self.weights['W2'].shape[1]}",
            f"  Activation: ReLU",
            "",
            "Output Layer: Dense",
            f"  Input shape: {self.weights['W3'].shape[0]}",
            f"  Output shape: {self.weights['W3'].shape[1]}",
            f"  Activation: Linear",
        ]
        
        return "\n".join(summary)


# Main training function
def train_agents(num_agents=5, episodes=200, save_interval=20):
    """
    Train multiple agents and save their models
    
    Args:
        num_agents: Number of agents to train
        episodes: Number of training episodes per agent
        save_interval: How often to save the model (in episodes)
    """
    logger.info(f"Starting training of {num_agents} agents for {episodes} episodes each")
    
    # Set up environments and agents
    environments = []
    agents = []
    
    # Create training directory for logs
    import time
    log_dir = os.path.join("training", f"run_{int(time.time())}")
    os.makedirs(log_dir, exist_ok=True)
    
    # Create agents with different parameters
    for i in range(num_agents):
        # Create game environment
        env = GameEnvironment(player_name=f"AI_Agent_{i+1}")
        environments.append(env)
        
        # Determine state and action sizes
        state_size = env.MAP_SIZE_X * env.MAP_SIZE_Y * 5  # Example: 5 channels of map info
        action_size = 7  # Number of action types
        
        # Create agent with slightly different parameters for exploration
        epsilon = 1.0 - (i * 0.1)  # Vary initial exploration rate
        learning_rate = 0.001 + (i * 0.0005)  # Vary learning rate
        
        agent = SimpleAgent(
            state_size=state_size,
            action_size=action_size,
            name=f"agent_{i+1}"
        )
        agent.epsilon = max(0.1, epsilon)  # Min 0.1
        agent.learning_rate = min(0.01, learning_rate)  # Max 0.01
        
        agents.append(agent)
        logger.info(f"Created agent {i+1} with epsilon={agent.epsilon}, lr={agent.learning_rate}")
    
    # Training loop
    for agent_idx, (agent, env) in enumerate(zip(agents, environments)):
        logger.info(f"Training agent {agent_idx+1}/{num_agents}")
        
        for episode in range(episodes):
            state = env.reset()
            done = False
            total_reward = 0
            steps = 0
            
            # Episode loop
            while not done and steps < 500:  # Max 500 steps per episode
                action = agent.act(state)
                next_state, reward, done, info = env.step(action)
                
                agent.remember(state, action, reward, next_state, done)
                agent.replay(batch_size=32)
                
                state = next_state
                total_reward += reward
                steps += 1
            
            # Log progress
            logger.info(f"Agent {agent_idx+1}, Episode {episode+1}/{episodes}, Score: {total_reward}, Steps: {steps}, Epsilon: {agent.epsilon:.4f}")
            
            # Save model at intervals
            if (episode + 1) % save_interval == 0 or episode == episodes - 1:
                save_path = os.path.join("models", f"{agent.name}_episode_{episode+1}.h5")
                agent.save_model(save_path)
                logger.info(f"Model saved to {save_path}")
        
        # Save final model
        save_path = os.path.join("models", f"{agent.name}_final.h5")
        agent.save_model(save_path)
        logger.info(f"Final model for agent {agent_idx+1} saved to {save_path}")

# Command-line interface
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Train simple neural network agents for the Game API')
    parser.add_argument('--num-agents', type=int, default=5, help='Number of agents to train')
    parser.add_argument('--episodes', type=int, default=200, help='Number of training episodes per agent')
    parser.add_argument('--save-interval', type=int, default=20, help='How often to save the model (in episodes)')
    
    args = parser.parse_args()
    
    # Create models directory if it doesn't exist
    os.makedirs("models", exist_ok=True)
    
    # Train agents
    train_agents(
        num_agents=args.num_agents,
        episodes=args.episodes,
        save_interval=args.save_interval
    )
    
    logger.info("Training complete. All models saved to 'models/' directory.")
    logger.info("You can convert models to TensorFlow format using: python convert_to_tensorflow.py")