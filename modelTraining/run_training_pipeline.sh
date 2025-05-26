#!/bin/bash
# Full training pipeline for the Game API AI models

# Make sure the backend service is running
echo "Checking if the backend service is running at http://localhost:8080..."
curl -s http://localhost:8080/api/status > /dev/null
if [ $? -ne 0 ]; then
    echo "The backend service doesn't appear to be running."
    echo "Please start the backend service using:"
    echo "cd ../backend_service && ./run_server.sh"
    exit 1
else
    echo "Backend service detected!"
fi

# Create directories if they don't exist
mkdir -p models/tensorflow
mkdir -p training/logs
mkdir -p self_play_training/logs
mkdir -p evaluation/logs

echo "======================================"
echo "Starting Training Pipeline"
echo "======================================"

# Phase 1: Train 5 independent AI agents
echo -e "\n[Phase 1] Training 5 independent AI agents"
echo "This phase uses the game API to train agents with different parameters"
python3 simple_agent.py --num-agents 5 --episodes 200 --save-interval 20

# Phase 2: Run self-play to improve agent performance
echo -e "\n[Phase 2] Running self-play training"
echo "This phase pits agents against each other through the game API"
python3 self_play.py --iterations 50 --matches 20

# Phase 3: Evaluate model performance
echo -e "\n[Phase 3] Evaluating model performance"
echo "This phase tests all models against each other through the game API"
python3 evaluate.py --models models/agent_*.h5 --matches 30

# Phase 4: Convert best models to TensorFlow format (if available)
echo -e "\n[Phase 4] Converting models to TensorFlow format"
echo "Checking for TensorFlow availability..."
python3 -c "import tensorflow as tf; print(f'TensorFlow {tf.__version__} detected')" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "TensorFlow is not installed. Models are saved in a TensorFlow-compatible format,"
    echo "but you need to install TensorFlow to convert them to actual TensorFlow models."
    echo "You can uncomment the TensorFlow line in requirements.txt and run pip install again."
else
    echo "TensorFlow detected! Converting models to TensorFlow format..."
    python3 convert_to_tensorflow.py
fi

# Phase 5: Visualize training results
echo -e "\n[Phase 5] Visualizing results"
echo "Creating visualizations of training results"
python3 visualize_results.py

echo -e "\n======================================"
echo "Training Pipeline Complete!"
echo "======================================"
echo "All models have been trained and saved to the 'models/' directory."
echo "TensorFlow-compatible models (if applicable) are in 'models/tensorflow/'."
echo "Evaluation results can be found in 'evaluation/logs/'."
echo "You can analyze these models or use them directly for game play."
