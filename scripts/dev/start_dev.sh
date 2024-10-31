#!/bin/bash
# scripts/dev/start_dev.sh
set -e

echo "Starting development environment..."

# Activate virtual environment
source venv/bin/activate

# Start development services
docker-compose up -d redis kafka mongodb

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

#!/bin/bash
# scripts/dev/watch.sh
set -e

# Watch for file changes and restart server
watchmedo auto-restart \
    --patterns="*.py;*.yaml" \
    --recursive \
    --directory="." \
    python -m uvicorn app.main:app --reload

#!/bin/bash
# scripts/dev/lint.sh
set -e

echo "Running linters..."

# Run black
black .

# Run flake8
flake8 .

# Run mypy
mypy .

# Run Android lint if in Android project
if [ -f "gradlew" ]; then
    ./gradlew lint
fi

#!/bin/bash
# scripts/dev/format.sh
set -e

# Format Python code
black .
isort .

# Format Kotlin code if present
if [ -f "gradlew" ]; then
    ./gradlew ktlintFormat
fi