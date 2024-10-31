#!/bin/bash
# scripts/setup/install.sh
set -e

echo "Starting installation process..."

# Environment setup
source setup/setup_env.sh

# Install dependencies
source setup/install_dependencies.sh

# Setup Docker environment
source setup/setup_docker.sh

echo "Installation completed successfully!"

#!/bin/bash
# scripts/setup/setup_env.sh
set -e

# Create virtual environment
python -m venv venv

# Activate virtual environment
source venv/bin/activate

# Set environment variables
export PYTHONPATH=$PYTHONPATH:$(pwd)
export ANDROID_HOME=$HOME/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Create necessary directories
mkdir -p logs
mkdir -p data
mkdir -p temp

#!/bin/bash
# scripts/setup/install_dependencies.sh
set -e

# System dependencies
if [ "$(uname)" == "Darwin" ]; then
    # macOS
    brew install ffmpeg
    brew install opencv
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Linux
    sudo apt-get update
    sudo apt-get install -y \
        ffmpeg \
        libopencv-dev \
        python3-dev \
        build-essential
fi

# Python dependencies
pip install -r requirements.txt

# Android dependencies
if [ -n "$ANDROID_HOME" ]; then
    $ANDROID_HOME/tools/bin/sdkmanager --install \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"
fi

#!/bin/bash
# scripts/setup/setup_docker.sh
set -e

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
fi

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Build Docker images
docker-compose build