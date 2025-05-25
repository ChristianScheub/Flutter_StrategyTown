#!/bin/bash

# Change to backend service directory
cd "$(dirname "$0")"

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: Dart SDK not found. Please install Dart SDK before running this script."
    exit 1
fi

# Install dependencies if needed
if [ ! -d "packages" ]; then
    echo "Installing dependencies..."
    dart pub get
fi

# Run the example client
echo "Running API client example..."
dart run example/client_example.dart
