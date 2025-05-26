#!/bin/bash
#!/bin/bash
# Setup script for the Model Training environment

# Create required directories
mkdir -p models
mkdir -p models/tensorflow
mkdir -p training/logs
mkdir -p self_play_training/logs
mkdir -p evaluation/logs

# Install Python dependencies
echo "Installing required Python dependencies..."
pip3 install -r requirements.txt

# Check if TensorFlow should be installed
echo "Do you want to install TensorFlow for model conversion? (y/N)"
read install_tensorflow

if [[ $install_tensorflow == "y" || $install_tensorflow == "Y" ]]; then
    echo "Installing TensorFlow..."
    pip3 install tensorflow==2.12.0
    echo "TensorFlow installed successfully!"
else
    echo "Skipping TensorFlow installation."
    echo "Note: You can still convert models to TensorFlow format later by running:"
    echo "  pip3 install tensorflow==2.12.0"
    echo "  python3 convert_to_tensorflow.py"
fi

# Check if the backend service is running
echo "Checking if the backend service is running at http://localhost:8080..."
curl -s http://localhost:8080/api/status > /dev/null
if [ $? -ne 0 ]; then
    echo "The backend service doesn't appear to be running."
    echo "Make sure to start the backend service using:"
    echo "cd ../backend_service && ./run_server.sh"
    exit 1
else
    echo "Backend service detected!"
fi

# Check for TensorFlow availability
echo "Checking if TensorFlow is available..."
python3 -c "import tensorflow as tf; print(f'TensorFlow {tf.__version__} detected')" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "TensorFlow is not installed. Models will be saved in a TensorFlow-compatible format,"
    echo "but you'll need to install TensorFlow to convert them to actual TensorFlow models."
    echo "You can uncomment the TensorFlow line in requirements.txt and run pip install again."
else
    echo "TensorFlow detected! Models can be directly converted to TensorFlow format."
fi

# Make scripts executable
chmod +x convert_to_tensorflow.py
chmod +x test_system.py
chmod +x run_training_pipeline.sh

# Print instructions
echo ""
echo "=== Setup Complete ==="
echo ""
echo "First, test if the system can connect to the game API:"
echo "   python3 test_system.py"
echo ""
echo "You can now run the following commands to train AI for the game:"
echo ""
echo "=== Recommended Training Pipeline ==="
echo "1. Train basic models (uses the game API directly):"
echo "   python3 simple_agent.py --num-agents 5 --episodes 200 --save-interval 20"
echo ""
echo "2. Run self-play to improve agents (competing against each other through the game API):"
echo "   python3 self_play.py --iterations 50 --matches 20"
echo ""
echo "3. Evaluate the trained models (via the game API):"
echo "   python3 evaluate.py --models models/agent_*.h5 --matches 30"
echo ""
echo "4. Convert best models to TensorFlow format (for advanced use):"
echo "   python3 convert_to_tensorflow.py --input-dir models --output-dir models/tensorflow"
echo ""
echo "5. Visualize training results and agent performance:"
echo "   python3 visualize_results.py --training-logs training/logs --evaluation-logs evaluation/logs"
echo ""
echo "=== Advanced Features ==="
echo "- To train directly with TensorFlow DQN if available:"
echo "  python3 train.py --num-agents 5 --episodes 1000 --steps 500"
echo ""
echo "- To view real-time training metrics:"
echo "  tensorboard --logdir=training/logs (if TensorFlow is installed)"
echo ""
echo "Remember the game API must be running at http://localhost:8080 during all training!"
echo "Check the README.md for more detailed instructions and command options."
echo ""
echo "To run self-play training with simple agents:"
echo "python3 self_play.py --num-agents 5 --episodes 50 --steps 200 --simple"
echo ""
echo "To evaluate trained models:"
echo "python3 evaluate.py --num-agents 5 --episodes 20 --model-paths models/agent_1.joblib models/agent_2.joblib models/agent_3.joblib models/agent_4.joblib models/agent_5.joblib --simple"
echo ""
echo "To visualize training results:"
echo "python3 visualize_results.py training/run_TIMESTAMP"
echo ""
