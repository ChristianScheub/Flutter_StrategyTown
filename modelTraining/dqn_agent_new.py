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
        # Define state dimensions
        window_size = 20  # 20x20 observation windows
        
        # Feature counts for each type
        terrain_features = 4    # grass, water, mountain, forest
        resource_features = 4    # food, wood, stone, iron
        unit_features = 8       # settler, archer, knight, farmer, lumberjack, miner, commander, architect
        building_features = 7    # cityCenter, farm, lumberCamp, mine, barracks, defensiveTower, wall
        visibility_features = 1  # binary visibility mask
        combat_features = 1     # combat influence
        resource_levels = 4     # global resource amounts
        
        # Calculate total features per window
        window_features = (
            terrain_features +    # One-hot encoded terrain types
            resource_features +   # One-hot encoded resource types
            unit_features +       # One-hot encoded unit types
            building_features +   # One-hot encoded building types
            visibility_features + # Binary visibility mask
            combat_features      # Combat influence values
        )
        
        # Calculate total state size
        state_size = window_size * window_size * window_features + resource_levels
        self.state_shape = (state_size,)
            
        # Store parameters
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
        """Build the deep Q-network model"""
        model = models.Sequential([
            # Input layer
            layers.Dense(512, activation='relu', input_shape=self.state_shape),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            # Hidden layers
            layers.Dense(1024, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.2),
            
            # Output layer
            layers.Dense(self.action_space, activation='linear')
        ])
        
        # Use Adam optimizer
        optimizer = Adam(learning_rate=self.learning_rate)
        model.compile(optimizer=optimizer, loss='mse')
        
        return model
    
    def _preprocess_state(self, state):
        """Convert dictionary state to flat vector"""
        if isinstance(state, dict):
            # Process each component
            terrain = state['terrain'].reshape(-1)
            resources = state['resources'].reshape(-1)
            units = state['units'].reshape(-1)
            buildings = state['buildings'].reshape(-1)
            visibility = state['visibility'].reshape(-1)
            combat = state['combat'].reshape(-1)
            resource_levels = state['resource_levels']
            
            # Concatenate all components
            return np.concatenate([
                terrain,
                resources,
                units,
                buildings,
                visibility,
                combat,
                resource_levels
            ])
        return state.flatten() if len(state.shape) > 1 else state
    
    def remember(self, state, action, reward, next_state, done):
        """Store experience in replay buffer"""
        # Preprocess states
        state_array = self._preprocess_state(state)
        next_state_array = self._preprocess_state(next_state)
        
        # Store in memory
        self.memory.append((state_array, action, reward, next_state_array, done))
        
    def act(self, state, action_mask=None):
        """Choose an action using epsilon-greedy policy"""
        # Preprocess state
        state_array = self._preprocess_state(state)
        
        # Get action mask from state dict if available
        if isinstance(state, dict):
            action_mask = state.get('action_mask')
        
        # Get valid actions from mask
        if action_mask is not None:
            valid_actions = np.where(action_mask > 0)[0]
            if len(valid_actions) == 0:
                return self.ACTION_END_TURN
        else:
            valid_actions = np.arange(self.action_space)
        
        # Epsilon-greedy action selection
        if random.random() < self.epsilon:
            return np.random.choice(valid_actions)
        
        # Get Q-values and select best valid action
        state_array = np.expand_dims(state_array, axis=0)
        q_values = self.model.predict(state_array, verbose=0)[0]
        
        # Mask invalid actions
        if action_mask is not None:
            q_values = np.where(action_mask > 0, q_values, float('-inf'))
        
        return np.argmax(q_values)
    
    def train(self):
        """Train the model on a batch of experiences"""
        if len(self.memory) < self.batch_size:
            return 0.0
        
        # Sample batch
        minibatch = random.sample(self.memory, self.batch_size)
        
        # Prepare training data
        states = np.array([exp[0] for exp in minibatch])
        actions = np.array([exp[1] for exp in minibatch])
        rewards = np.array([exp[2] for exp in minibatch])
        next_states = np.array([exp[3] for exp in minibatch])
        dones = np.array([exp[4] for exp in minibatch])
        
        # Get Q-values for next states
        target_q_values = self.target_model.predict(next_states, verbose=0)
        
        # Calculate target values
        targets = rewards + (1 - dones) * self.gamma * np.max(target_q_values, axis=1)
        
        # Update Q-values for actions taken
        target_f = self.model.predict(states, verbose=0)
        for i, action in enumerate(actions):
            target_f[i][action] = targets[i]
            
        # Train the model
        history = self.model.fit(states, target_f, batch_size=self.batch_size, verbose=0)
        
        # Update target network periodically
        self.train_step += 1
        if self.train_step % self.update_target_freq == 0:
            self.target_model.set_weights(self.model.get_weights())
            
        # Decay exploration rate
        if self.epsilon > self.epsilon_min:
            self.epsilon *= self.epsilon_decay
            
        return history.history['loss'][0]
    
    def save_model(self, filepath):
        """Save model weights"""
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        self.model.save_weights(f"{filepath}.weights.h5")
        logger.info(f"Model saved to {filepath}.weights.h5")
        
    def load_model(self, filepath):
        """Load model weights"""
        self.model.load_weights(f"{filepath}.weights.h5")
        logger.info(f"Model loaded from {filepath}.weights.h5")
