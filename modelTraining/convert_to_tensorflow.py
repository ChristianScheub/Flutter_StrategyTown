#!/usr/bin/env python3
"""
Convert Simple Neural Network models to TensorFlow format

This script takes the h5py-saved models from the simple agent and converts them
into proper TensorFlow/Keras models that can be used for inference.
"""

import os
import argparse
import logging
import numpy as np
import h5py
from pathlib import Path
from typing import List, Dict, Tuple, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)
logger = logging.getLogger(__name__)

def try_import_tensorflow():
    """
    Try to import TensorFlow and return True if successful, False otherwise.
    """
    try:
        import tensorflow as tf
        logger.info(f"TensorFlow version {tf.__version__} is available.")
        return True, tf
    except ImportError:
        logger.error("TensorFlow is not installed. Please install it with 'pip install tensorflow==2.12.0'")
        return False, None

def load_h5_weights(model_path: str) -> Tuple[Dict[str, np.ndarray], Dict]:
    """
    Load weights from an H5 file created by simple_agent.py
    
    Args:
        model_path: Path to the h5 file
        
    Returns:
        Tuple of (weights dictionary, metadata dictionary)
    """
    weights = {}
    metadata = {}
    
    with h5py.File(model_path, 'r') as f:
        # Load weights
        weight_group = f['weights']
        for layer_name in weight_group.keys():
            layer_weights = []
            layer_group = weight_group[layer_name]
            for i in range(len(layer_group)):
                weight = np.array(layer_group[f'weight_{i}'])
                layer_weights.append(weight)
            weights[layer_name] = layer_weights
            
        # Load metadata
        metadata_group = f['metadata']
        for key in metadata_group.attrs:
            metadata[key] = metadata_group.attrs[key]
            
        # Load architecture info
        if 'architecture' in f:
            arch_group = f['architecture']
            architecture = {}
            for key in arch_group.attrs:
                architecture[key] = arch_group.attrs[key]
            
            # Parse layer sizes from architecture
            layer_sizes = []
            i = 0
            while f'layer_{i}_size' in architecture:
                layer_sizes.append(architecture[f'layer_{i}_size'])
                i += 1
                
            metadata['layer_sizes'] = layer_sizes
            
    return weights, metadata

def create_tensorflow_model(input_dim: int, layer_sizes: List[int], output_dim: int) -> 'tf.keras.Model':
    """
    Create a TensorFlow model with the given architecture
    
    Args:
        input_dim: Input dimension
        layer_sizes: List of hidden layer sizes
        output_dim: Output dimension
        
    Returns:
        TensorFlow model
    """
    import tensorflow as tf
    from tensorflow.keras import layers, models
    
    model = models.Sequential()
    
    # Input layer
    model.add(layers.Input(shape=(input_dim,)))
    
    # Hidden layers
    for size in layer_sizes:
        model.add(layers.Dense(size, activation='relu'))
        
    # Output layer
    model.add(layers.Dense(output_dim, activation='linear'))
    
    return model

def set_weights_to_tf_model(model: 'tf.keras.Model', weights: Dict[str, List[np.ndarray]]) -> 'tf.keras.Model':
    """
    Set weights to TensorFlow model
    
    Args:
        model: TensorFlow model
        weights: Dictionary of weights from H5 file
        
    Returns:
        Updated TensorFlow model
    """
    tf_weights = []
    
    # For each layer in the model
    for i, layer in enumerate(model.layers):
        layer_name = f'layer_{i}'
        if layer_name in weights:
            layer_weights = weights[layer_name]
            tf_weights.extend(layer_weights)
    
    model.set_weights(tf_weights)
    return model

def convert_model(input_path: str, output_path: str) -> bool:
    """
    Convert a model from H5 to TensorFlow format
    
    Args:
        input_path: Path to input H5 file
        output_path: Path to save TensorFlow model
        
    Returns:
        True if conversion was successful, False otherwise
    """
    # Try to import TensorFlow
    tf_available, tf = try_import_tensorflow()
    if not tf_available:
        return False
    
    # Load weights from H5 file
    logger.info(f"Loading weights from {input_path}")
    weights, metadata = load_h5_weights(input_path)
    
    # Get architecture information
    if 'layer_sizes' not in metadata:
        logger.error("Architecture information not found in model file")
        return False
        
    layer_sizes = metadata['layer_sizes']
    input_dim = layer_sizes[0]
    output_dim = layer_sizes[-1]
    hidden_layers = layer_sizes[1:-1]
    
    logger.info(f"Model architecture: input_dim={input_dim}, hidden_layers={hidden_layers}, output_dim={output_dim}")
    
    # Create TensorFlow model
    model = create_tensorflow_model(input_dim, hidden_layers, output_dim)
    
    # Set weights to TensorFlow model
    model = set_weights_to_tf_model(model, weights)
    
    # Save model
    model.save(output_path)
    logger.info(f"Saved TensorFlow model to {output_path}")
    
    return True

def convert_models_in_directory(input_dir: str, output_dir: str) -> List[str]:
    """
    Convert all H5 models in a directory to TensorFlow format
    
    Args:
        input_dir: Directory containing H5 files
        output_dir: Directory to save TensorFlow models
        
    Returns:
        List of paths to converted models
    """
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Find all H5 files
    input_path = Path(input_dir)
    h5_files = list(input_path.glob('*.h5'))
    
    if not h5_files:
        logger.warning(f"No H5 files found in {input_dir}")
        return []
    
    # Convert each H5 file
    converted_models = []
    for h5_file in h5_files:
        model_name = h5_file.stem
        output_path = os.path.join(output_dir, f"{model_name}_tf")
        
        success = convert_model(str(h5_file), output_path)
        if success:
            converted_models.append(output_path)
    
    return converted_models

def main():
    parser = argparse.ArgumentParser(description='Convert Simple Agent models to TensorFlow format')
    parser.add_argument('--input-dir', type=str, default='models',
                        help='Directory containing H5 model files')
    parser.add_argument('--output-dir', type=str, default='models/tensorflow',
                        help='Directory to save TensorFlow models')
    parser.add_argument('--input-model', type=str,
                        help='Specific model file to convert')
    parser.add_argument('--output-model', type=str,
                        help='Output path for specific model')
    
    args = parser.parse_args()
    
    # Check if TensorFlow is available
    tf_available, _ = try_import_tensorflow()
    if not tf_available:
        logger.error("TensorFlow is required for conversion. Please install it first.")
        return 1
    
    if args.input_model:
        # Convert specific model
        if not args.output_model:
            model_name = os.path.splitext(os.path.basename(args.input_model))[0]
            args.output_model = os.path.join(args.output_dir, f"{model_name}_tf")
            os.makedirs(os.path.dirname(args.output_model), exist_ok=True)
        
        success = convert_model(args.input_model, args.output_model)
        if not success:
            return 1
    else:
        # Convert all models in directory
        converted = convert_models_in_directory(args.input_dir, args.output_dir)
        logger.info(f"Converted {len(converted)} models: {converted}")
    
    return 0

if __name__ == '__main__':
    exit(main())
