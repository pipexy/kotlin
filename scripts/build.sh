#!/bin/bash

# Exit on any error
set -e

echo "Building PipeXY services..."

# Build all services
services=("decoder" "encoder" "scaler" "motion" "object" "audio")

for service in "${services[@]}"; do
    echo "Building $service service..."
    docker-compose build "$service"
done

echo "Building monitoring services..."
docker-compose build prometheus grafana

echo "All services built successfully!"
