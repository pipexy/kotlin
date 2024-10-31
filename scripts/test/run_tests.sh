#!/bin/bash
# scripts/test/run_tests.sh
set -e

echo "Running test suite..."

# Activate virtual environment
source venv/bin/activate

# Run Python tests
pytest tests/ \
    --cov=app \
    --cov-report=term-missing \
    --cov-report=html:coverage_report

# Run Android tests if present
if [ -f "gradlew" ]; then
    ./gradlew test
    ./gradlew connectedAndroidTest
fi

#!/bin/bash
# scripts/test/integration_tests.sh
set -e

echo "Running integration tests..."

# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Wait for services
./scripts/utils/wait-for-it.sh localhost:8080 -t 60

# Run integration tests
pytest tests/integration/ -v

#!/bin/bash
# scripts/test/benchmark.sh
set -e

echo "Running benchmarks..."

# Python benchmarks
pytest tests/benchmarks/ --benchmark-only

# API benchmarks
ab -n 1000 -c 10 http://localhost:8080/health

# Stream processing benchmarks
./scripts/test/stream_benchmark.sh

#!/bin/bash
# scripts/test/setup_test_env.sh
set -e

# Create test database
docker-compose -f docker-compose.test.yml up -d db

# Load test data
python scripts/utils/load_test_data.py

# Start test RTSP server
docker run --rm -d \
    -p 8554:8554 \
    -v $(pwd)/test-media:/media \
    ullaakut/rtspatt