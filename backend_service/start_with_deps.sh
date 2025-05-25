#!/bin/zsh

# This script installs all dependencies and starts the server

# Show commands as they're executed
set -x

# Change to the project directory
cd "$(dirname "$0")"

# Install dependencies for both projects
echo "Installing main project dependencies..."
cd ..
flutter pub get

echo "Installing backend service dependencies..."
cd backend_service
dart pub get

# Start the server
echo "Starting backend API server..."
dart run bin/server.dart
