
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
