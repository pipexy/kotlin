# Build stage
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3-pip \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy source code
WORKDIR /build
COPY proto/ /build/proto/
COPY services/object/src/ /build/src/

# Generate gRPC code
RUN protoc -I proto \
    --python_out=src \
    --grpc_python_out=src \
    proto/*.proto

# Runtime stage
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy built application
WORKDIR /app
COPY --from=builder /build/src /app/src
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Create directories
RUN mkdir -p /app/models /app/config /app/logs

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    MODEL_PATH=/app/models/yolov4-tiny.weights \
    CONFIG_PATH=/app/models/yolov4-tiny.cfg \
    GRPC_PORT=50061

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import grpc; channel = grpc.insecure_channel('localhost:${GRPC_PORT}'); channel.channel_ready_future().result(timeout=10)"

# Start service
CMD ["python3", "-m", "src.main"]