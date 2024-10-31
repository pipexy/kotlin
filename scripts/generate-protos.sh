#!/bin/bash

# Exit on any error
set -e

# Check if protoc is installed
if ! command -v protoc &> /dev/null; then
    echo "protoc is not installed. Please install Protocol Buffers compiler first."
    exit 1
fi

echo "Generating Protocol Buffers code..."

# Create python package directory if it doesn't exist
mkdir -p generated/python

# Generate Python code
PROTO_FILES=(
    "proto/common.proto"
    "proto/video.proto"
    "proto/audio.proto"
    "proto/ai.proto"
)

for proto_file in "${PROTO_FILES[@]}"; do
    echo "Generating code for $proto_file..."
    protoc -I=. \
           --python_out=generated/python \
           --grpc_python_out=generated/python \
           "$proto_file"
done

# Fix Python imports
find generated/python -type f -name "*.py" -exec sed -i 's/^import common_pb2/from . import common_pb2/g' {} \;
find generated/python -type f -name "*.py" -exec sed -i 's/^import video_pb2/from . import video_pb2/g' {} \;
find generated/python -type f -name "*.py" -exec sed -i 's/^import audio_pb2/from . import audio_pb2/g' {} \;
find generated/python -type f -name "*.py" -exec sed -i 's/^import ai_pb2/from . import ai_pb2/g' {} \;

# Create __init__.py files
touch generated/python/__init__.py
touch generated/python/proto/__init__.py

echo "Protocol Buffers code generation completed successfully!"
