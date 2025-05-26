#!/usr/bin/env python3
"""
Deep Q-Network Agent for the Game
"""

import os
import random
import numpy as np
from keras import layers, models
from keras.optimizers import Adam
from typing import Dict, List, Tuple, Union
from collections import deque
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class DQNAgent:
    """Deep Q-Network reinforcement learning agent"""
    
    # Action space definitions  
    ACTION_MOVE_UNIT = 0
    ACTION_FOUND_CITY = 1
    ACTION_BUILD = 2
    ACTION_TRAIN_UNIT = 3
    ACTION_HARVEST = 4
    ACTION_UPGRADE_BUILDING = 5
    ACTION_ATTACK = 6
    ACTION_END_TURN = 7
    
    def __init__(
        self,
        state_shape: Union[Tuple[int, ...], int],
        action_space: int,
        model_name: str = "dqn_agent",
        learning_rate: float = 1e-4,
        gamma: float = 0.99,
        epsilon: float = 1.0,
        epsilon_decay: float = 0.995,
        epsilon_min: float = 0.1,
        batch_size: int = 64,
        update_target_freq: int = 1000,
        memory_size: int = 10000
    ):
        """Initialize DQN Agent with parameters"""
        # Calculate total state size from all components
        # For 20x20 windows with each feature type
        window_dim = 20  # 20x20 observation windows
        
        # Number of features for each type
        num_terrain_types = 4     # grass, water, mountain, forest
        num_resource_types = 4     # food, wood, stone, iron
        num_unit_types = 9        # settler, warrior, archer, knight, farmer, lumberjack, miner, commander, architect
        num_building_types = 7     # cityCenter, farm, lumberCamp, mine, barracks, defensiveTower, wall
        num_visibility = 1        # binary visibility mask
        num_combat = 1           # combat influence
        
        # Calculate total size of flattened observation windows
        window_features = (
            num_terrain_types + 
            num_resource_types + 
            num_unit_types + 
            num_building_types + 
            num_visibility + 
            num_combat
        )
        state_size = window_dim * window_dim * window_features
        
        # Add resource levels (food, wood, stone, iron)
        num_resource_levels = 4
        
        # Calculate total state size
        total_state_size = window_dim * window_dim * window_features + num_resource_levels
        self.state_shape = (total_state_size,)
            
        self.action_space = action_space
        self.model_name = model_name
        self.learning_rate = learning_rate
        self.gamma = gamma  # discount factor
        self.epsilon = epsilon  # exploration rate
        self.epsilon_decay = epsilon_decay
        self.epsilon_min = epsilon_min
        self.batch_size = batch_size
        self.update_target_freq = update_target_freq
        
        # Experience replay buffer
        self.memory = deque(maxlen=memory_size)
        
        # Build and compile models
        self.model = self._build_model()
        self.target_model = self._build_model()
        self.target_model.set_weights(self.model.get_weights())
        
        # Training step counter
        self.train_step = 0
        
    def _build_model(self):
        """Builds a deep Q-network model with feed-forward architecture for the game state"""
        model = models.Sequential([
            # Input layer
            layers.Dense(512, activation='relu', input_shape=self.state_shape),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            # Deep layers for processing high-dimensional state
            layers.Dense(1024, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            # Output processing layers
            layers.Dense(128, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            # Output layer - one neuron per action
            layers.Dense(self.action_space, activation='linear')
        ])
        
        # Use Adam optimizer with lower learning rate for stability
        optimizer = Adam(learning_rate=self.learning_rate)
        model.compile(
            optimizer=optimizer,
            loss='mse',
            metrics=['mae']  # Track mean absolute error for monitoring
        )
        
        logger.info(f"Built model with input shape {self.state_shape} and {self.action_space} outputs")
        model.summary(print_fn=logger.info)
        return model
        
    def remember(self, state, action, reward, next_state, done):
        """Store experience in replay buffer"""
        # Convert dictionary states to flat vectors
        if isinstance(state, dict):
            state_array = np.concatenate([
                state['terrain'].reshape(-1),
                state['resources'].reshape(-1),
                state['units'].reshape(-1),
                state['buildings'].reshape(-1),
                state['visibility'].reshape(-1),
                state['combat'].reshape(-1),
                state['resource_levels']
            ])
        else:
            state_array = state.flatten() if len(state.shape) > 1 else state
        
        if isinstance(next_state, dict):
            next_state_array = np.concatenate([
                next_state['terrain'].reshape(-1),
                next_state['resources'].reshape(-1),
                next_state['units'].reshape(-1),
                next_state['buildings'].reshape(-1),
                next_state['visibility'].reshape(-1),
                next_state['combat'].reshape(-1),
                next_state['resource_levels']
            ])
        else:
            next_state_array = next_state.flatten() if len(next_state.shape) > 1 else next_state
        
        logger.info(f"[DEBUG] remember() state shape: {state_array.shape}, next_state shape: {next_state_array.shape}")
        self.memory.append((state_array, action, reward, next_state_array, done))
        
    def act(self, state):
        """Choose an action using epsilon-greedy policy (no action mask, no available_actions)"""
        # Handle dictionary state input
        if isinstance(state, dict):
            state_array = np.concatenate([
                state['terrain'].reshape(-1),
                state['resources'].reshape(-1),
                state['units'].reshape(-1),
                state['buildings'].reshape(-1),
                state['visibility'].reshape(-1),
                state['combat'].reshape(-1),
                state['resource_levels']
            ])
        else:
            state_array = state
        # Epsilon-greedy exploration
        if random.random() < self.epsilon:
            return random.randint(0, self.action_space - 1)
        state_array = np.expand_dims(state_array, axis=0)
        q_values = self.model.predict(state_array, verbose=0)[0]
        return int(np.argmax(q_values))
            
    def train(self):
        """Train the model on a batch of experiences with action masking"""
        if len(self.memory) < self.batch_size:
            return 0.0
            
        # Sample a batch of experiences
        minibatch = random.sample(self.memory, self.batch_size)
        
        # Prepare arrays for training
        states = np.array([exp[0] for exp in minibatch])
        actions = np.array([exp[1] for exp in minibatch])
        rewards = np.array([exp[2] for exp in minibatch])
        next_states = np.array([exp[3] for exp in minibatch])
        dones = np.array([exp[4] for exp in minibatch])
        masks = np.array([exp[5] if len(exp) > 5 else np.ones(self.action_space) for exp in minibatch])
        
        # Get target Q-values from target network
        target_q_values = self.target_model.predict(next_states, verbose=0)
        
        # Apply action masks to target Q-values
        masked_target_q_values = np.where(masks > 0, target_q_values, float('-inf'))
        max_target_q_values = np.max(masked_target_q_values, axis=1)
        
        # Calculate target values with masking
        target_values = rewards + (1 - dones) * self.gamma * max_target_q_values
        
        # Get current Q-values and update them for actions taken
        current_q_values = self.model.predict(states, verbose=0)
        for i, (action, target) in enumerate(zip(actions, target_values)):
            current_q_values[i][action] = target
        
        # Train the model
        history = self.model.fit(
            states, 
            current_q_values, 
            batch_size=self.batch_size,
            verbose=0
        )
        
        # Update target network periodically
        self.train_step += 1
        if self.train_step % self.update_target_freq == 0:
            self.target_model.set_weights(self.model.get_weights())
        
        # Decay exploration rate
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
        
        return history.history['loss'][0]
        
    def update_target_network(self):
        """Update target network with current network weights"""
        self.target_model.set_weights(self.model.get_weights())
        logger.info("Target network updated")
    
    def update_epsilon(self):
        """Update epsilon for exploration decay"""
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
            self.epsilon = max(self.epsilon_min, self.epsilon)
    
    def save_model(self, filepath):
        """Save the model weights"""
        try:
            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            self.model.save_weights(f"{filepath}.weights.h5")
            logger.info(f"Model saved to {filepath}.weights.h5")
        except Exception as e:
            logger.error(f"Error saving model to {filepath}: {e}")
            
    def load_model(self, filepath):
        """Load the model weights"""
        try:
            self.model.load_weights(f"{filepath}.weights.h5")
            logger.info(f"Model loaded from {filepath}.weights.h5")
        except Exception as e:
            logger.error(f"Error loading model from {filepath}: {e}")
