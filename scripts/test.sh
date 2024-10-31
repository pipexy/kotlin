#!/bin/bash

# Exit on any error
set -e

echo "Running PipeXY tests..."

# Array of services to test
services=("decoder" "encoder" "scaler" "motion" "object" "audio")

# Function to run tests for a service
run_service_tests() {
    local service=$1
    echo "Testing $service service..."
    
    # Create test container
    docker-compose run --rm "$service" python -m pytest /app/tests \
        --cov=/app \
        --cov-report=term-missing \
        --cov-report=xml:/app/coverage.xml \
        -v

    if [ $? -eq 0 ]; then
        echo "✓ $service tests passed"
    else
        echo "✗ $service tests failed"
        exit 1
    fi
}

# Run integration tests first
echo "Running integration tests..."
docker-compose up -d
sleep 10  # Wait for services to be ready

# Run test suite for each service
for service in "${services[@]}"; do
    run_service_tests "$service"
done

# Cleanup
docker-compose down

echo "All tests completed successfully!"
