#!/bin/bash
# scripts/build/build.sh
set -e

echo "Building project..."

# Clean previous builds
rm -rf dist/ build/

# Build Python package
python setup.py sdist bdist_wheel

# Build Android app if present
if [ -f "gradlew" ]; then
    ./gradlew assembleRelease
fi

#!/bin/bash
# scripts/build/build_docker.sh
set -e

echo "Building Docker images..."

# Build base image
docker build -t pipeline-router:base -f docker/Dockerfile.base .

# Build service images
docker-compose build

# Tag images
docker tag pipeline-router:base pipeline-router:latest

#!/bin/bash
# scripts/build/build_android.sh
set -e

echo "Building Android APK..."

# Check environment
if [ -z "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME not set"
    exit 1
fi

# Clean project
./gradlew clean

# Build release APK
./gradlew assembleRelease

# Sign APK
./scripts/utils/sign_apk.sh

#!/bin/bash
# scripts/build/build_release.sh
set -e

VERSION=$(cat VERSION)
echo "Building release version $VERSION..."

# Update version
sed -i "s/version=.*/version=$VERSION/" setup.py

# Build packages
python setup.py sdist bdist_wheel

# Build Docker images
docker build -t pipeline-router:$VERSION .

# Generate documentation
./scripts/utils/generate_docs.sh