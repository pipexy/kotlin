# kotlin
kotlin implementation on kubernetes


# Protocol Router Project Documentation

## 1. Project Structure

```
/protocol-router
├── src/
│   ├── main/
│   │   ├── kotlin/
│   │   │   ├── com/example/router/
│   │   │   │   ├── protocols/
│   │   │   │   │   ├── FileProtocolHandler.kt
│   │   │   │   │   ├── KafkaProtocolHandler.kt
│   │   │   │   │   ├── RtspHandler.kt
│   │   │   │   │   ├── WebRTCHandler.kt
│   │   │   │   │   ├── GrpcHandler.kt
│   │   │   │   │   └── WssHandler.kt
│   │   │   │   ├── core/
│   │   │   │   │   ├── Router.kt
│   │   │   │   │   ├── ProtocolRegistry.kt
│   │   │   │   │   └── RouteDefinition.kt
│   │   │   │   └── config/
│   │   │   │       ├── AppConfig.kt
│   │   │   │       └── SecurityConfig.kt
│   │   └── resources/
│   │       ├── application.yaml
│   │       └── logback.xml
│   └── test/
│       └── kotlin/
│           └── com/example/router/
│               ├── protocols/
│               │   └── *Test.kt
│               └── core/
│                   └── *Test.kt
├── config/
│   ├── nginx/
│   │   └── nginx.conf
│   ├── envoy/
│   │   └── envoy.yaml
│   ├── coturn/
│   │   └── turnserver.conf
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── dashboards/
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.test
│   └── docker-compose.yml
├── scripts/
│   ├── setup.sh
│   ├── generate-certs.sh
│   └── test/
│       ├── run-tests.sh
│       └── performance-test.sh
└── certs/
    ├── cert.pem
    └── key.pem
```

## 2. Prerequisites

- JDK 17 or later
- Docker and Docker Compose
- Kotlin 1.9.0 or later
- Gradle 8.4 or later
- OpenSSL (for certificate generation)
- FFmpeg (for media processing)

## 3. Setup Procedure

### 3.1. Initial Setup

```bash
# Clone the repository
git clone https://github.com/your-org/protocol-router.git
cd protocol-router

# Generate certificates
./scripts/generate-certs.sh

# Build the project
./gradlew build

# Build Docker images
docker-compose build
```

### 3.2. Configuration

1. Create environment file:
```bash
cp .env.example .env
```

2. Configure environment variables:
```env
KAFKA_BOOTSTRAP_SERVERS=kafka:9092
REDIS_HOST=redis
TURN_USERNAME=admin
TURN_PASSWORD=your_secure_password
```

3. Configure SSL certificates:
```bash
# Generate self-signed certificates for development
./scripts/generate-certs.sh development

# For production, place your certificates in:
cp your-cert.pem certs/cert.pem
cp your-key.pem certs/key.pem
```

## 4. Running the Application

### 4.1. Development Environment

```bash
# Start dependencies
docker-compose up -d kafka redis mongodb mosquitto

# Run the application
./gradlew bootRun
```

### 4.2. Production Environment

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f router

# Check health
curl http://localhost:8080/health
```

## 5. Testing

### 5.1. Running Tests

```bash
# Unit tests
./gradlew test

# Integration tests
./gradlew integrationTest

# Performance tests
./gradlew performanceTest
```

### 5.2. Protocol Testing

#### HTTP/WebSocket
```bash
# Test HTTP endpoint
curl -X POST http://localhost:8080/api/message \
  -H "Content-Type: application/json" \
  -d '{"data": "test"}'

# Test WebSocket
wscat -c wss://localhost:8443/ws
```

#### RTSP/HLS
```bash
# Stream RTSP
ffmpeg -i test.mp4 -f rtsp rtsp://localhost:554/stream

# Play HLS
vlc http://localhost:8082/hls/stream.m3u8
```

#### gRPC
```bash
# Using grpcurl
grpcurl -plaintext localhost:9000 list
grpcurl -plaintext localhost:9000 RouterService/StreamData
```

### 5.3. Load Testing
```bash
# Run performance test suite
./scripts/test/performance-test.sh

# Monitor metrics
open http://localhost:3000  # Grafana
```

## 6. Monitoring

### 6.1. Available Dashboards

- Grafana: http://localhost:3000
   - System Metrics Dashboard
   - Protocol Metrics Dashboard
   - Streaming Performance Dashboard

- Prometheus: http://localhost:9090
- Jaeger: http://localhost:16686

### 6.2. Health Checks

```bash
# Router health
curl http://localhost:8080/health

# Protocol-specific health
curl http://localhost:8080/health/kafka
curl http://localhost:8080/health/redis
```

## 7. Protocol Support

### 7.1. Supported Protocols

- Messaging:
   - Kafka
   - RabbitMQ
   - MQTT
   - Redis

- Streaming:
   - RTSP
   - HLS
   - DASH
   - WebRTC

- Web:
   - HTTP/REST
   - WebSocket (WSS)
   - gRPC
   - GraphQL

- Storage:
   - File
   - FTP/SFTP
   - S3

### 7.2. Protocol Configuration

Example route configuration:
```yaml
routes:
  - from: "rtsp://camera:554/stream"
    transform:
      type: "transcode"
      codec: "h264"
    to: "webrtc://browser/stream"
```

## 8. Troubleshooting

### 8.1. Common Issues

1. Connection Issues:
```bash
# Check network
docker network ls
docker network inspect router-net

# Check service logs
docker-compose logs kafka
```

2. Performance Issues:
```bash
# Check metrics
curl http://localhost:8080/metrics

# Check resource usage
docker stats
```

### 8.2. Logs

```bash
# Application logs
docker-compose logs -f router

# Protocol-specific logs
docker-compose logs -f kafka
docker-compose logs -f webrtc-signaling
```

## 9. Maintenance

### 9.1. Backup

```bash
# Backup configurations
./scripts/backup-config.sh

# Backup data
./scripts/backup-data.sh
```

### 9.2. Updates

```bash
# Update dependencies
./gradlew dependencyUpdates

# Update Docker images
docker-compose pull

# Apply updates
docker-compose up -d
```

## 10. Security

### 10.1. Certificate Management

```bash
# Rotate certificates
./scripts/rotate-certs.sh

# Check certificate expiration
./scripts/check-certs.sh
```

### 10.2. Authentication

Configure authentication in `config/security.yaml`:
```yaml
security:
  jwt:
    enabled: true
    secret: ${JWT_SECRET}
  ssl:
    enabled: true
    certPath: /certs/cert.pem
```

## 11. Development

### 11.1. Adding New Protocols

1. Create handler:
```kotlin
class NewProtocolHandler : ProtocolHandler {
    override suspend fun startReceiving(uri: String, channel: Channel<ByteArray>) {
        // Implementation
    }

    override suspend fun send(uri: String, message: ByteArray) {
        // Implementation
    }
}
```

2. Register protocol:
```kotlin
protocolRegistry.registerHandler("new-protocol", NewProtocolHandler())
```

### 11.2. Building

```bash
# Build project
./gradlew build

# Build Docker image
docker build -t protocol-router .
```

## 12. Contact and Support

- GitHub Issues: [Project Issues](https://github.com/your-org/protocol-router/issues)
- Documentation: [Project Wiki](https://github.com/your-org/protocol-router/wiki)
- Support Email: support@example.com







# Video Processing System Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Installation Guide](#installation-guide)
4. [Configuration Guide](#configuration-guide)
5. [API Reference](#api-reference)
6. [Pipeline Examples](#pipeline-examples)
7. [Monitoring & Operations](#monitoring--operations)
8. [Troubleshooting](#troubleshooting)
9. [Development Guide](#development-guide)
10. [Security Guidelines](#security-guidelines)

## System Overview

### Introduction
The Video Processing System is a scalable, distributed platform for real-time video processing using gRPC-based microservices. It supports various input sources, processing modules, and output formats.

### Key Features
- Real-time video processing
- Modular architecture
- Scalable deployment options
- AI-powered processing capabilities
- Monitoring and alerting
- Multiple protocol support

### Use Cases
- Security and surveillance
- Live streaming
- Video conferencing
- Sports analytics
- Content delivery

## Architecture

### Component Overview
```plaintext
┌─────────┐     ┌──────────────┐     ┌──────────────┐     ┌─────────┐
│  Input  │ ──► │   Decoder    │ ──► │  Processors  │ ──► │ Output  │
└─────────┘     └──────────────┘     └──────────────┘     └─────────┘
   RTSP            gRPC Service         AI/Processing        HLS/RTMP
   WebRTC                               Motion/Object        WebRTC
   SRT                                  Audio/Video          gRPC
```

### Service Communication
- gRPC for inter-service communication
- Protocol buffers for data serialization
- Asynchronous processing pipeline
- Load balancing and service discovery

## Installation Guide

### Prerequisites
```bash
# System Requirements
- Docker 20.10+
- Kubernetes 1.22+
- NVIDIA GPU (optional)
- 8GB RAM minimum
- 4 CPU cores minimum

# Required Software
- Python 3.8+
- OpenCV
- FFmpeg
- CUDA Toolkit (for GPU support)
```

### Quick Start
```bash
# Clone repository
git clone https://github.com/your-org/video-processor.git
cd video-processor

# Setup environment
cp .env.example .env

# Start services
./scripts/manage.sh start
```

```bash
# Version Information
# Python >= 3.9
# CUDA >= 11.0 (if using GPU)
# FFmpeg >= 4.4

# Platform-specific dependencies
# Linux: libgl1-mesa-glx, libglib2.0-0
# Windows: Visual C++ Redistributable
# macOS: brew install ffmpeg

# Install with:
# pip install -r requirements.txt

# For development:
# pip install -r requirements.txt[dev]

# For testing:
# pip install -r requirements.txt[test]

# Optional GPU support:
# pip install -r requirements.txt[gpu]

# Create environment with:
python -m venv venv
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

### Docker Deployment
```bash
# Build images
docker-compose build

# Start services
docker-compose up -d
```

### Kubernetes Deployment
```bash
# Create namespace
kubectl create namespace video-processing

# Apply configurations
kubectl apply -f k8s/

# Verify deployment
kubectl get pods -n video-processing
```

## Configuration Guide

### Pipeline Configuration
```yaml
pipelines:
  - name: "live-stream"
    from: "rtsp://camera.local:554/stream"
    processors:
      - "grpc://decoder:50051/videoprocessing.Decoder/decode"
      - "grpc://object:50061/ai.ObjectDetector/detect"
    to: "rtmp://streaming:1935/live"
```

### Service Configuration
```yaml
services:
  decoder:
    port: 50051
    workers: 4
    gpu_enabled: true
    pixel_format: "yuv420p"

  object_detector:
    port: 50061
    model: "yolov4-tiny"
    confidence: 0.6
    gpu_enabled: true
```

### Environment Variables
```plaintext
GRPC_PORT=50051
WORKERS_PER_SERVICE=4
MAX_MEMORY_PER_SERVICE=2G
LOG_LEVEL=INFO
```

## API Reference

### Video Processing Service
```protobuf
service VideoProcessor {
    rpc Decode(stream Frame) returns (stream VideoFrame);
    rpc Process(VideoFrame) returns (ProcessingResult);
    rpc Configure(Configuration) returns (ConfigResponse);
}
```

### Common Data Types
```protobuf
message Frame {
    bytes data = 1;
    int64 timestamp = 2;
    string format = 3;
    map<string, string> metadata = 4;
}

message ProcessingResult {
    bool success = 1;
    string error = 2;
    Frame frame = 3;
}
```

### Error Codes
```plaintext
INVALID_FRAME: Frame data is corrupted or invalid
SERVICE_UNAVAILABLE: Processing service is not available
CONFIGURATION_ERROR: Invalid service configuration
PROCESSING_ERROR: Error during frame processing
```

## Pipeline Examples

### Security Camera Pipeline
```yaml
pipelines:
  - name: "security"
    from: "rtsp://camera1.local:554/stream1"
    processors:
      - "grpc://decoder:50051/videoprocessing.Decoder/decode"
      - "grpc://motion:50060/ai.MotionDetector/detect"
    to: "hls://cdn.local/security.m3u8"
```

### Live Streaming Pipeline
```yaml
pipelines:
  - name: "live"
    from: "webrtc://conference.local:8443/stream"
    processors:
      - "grpc://decoder:50051/videoprocessing.Decoder/decode"
      - "grpc://audio:50070/audio.Normalizer/normalize"
    to: "rtmp://streaming:1935/live"
```

## Monitoring & Operations

### Metrics
```plaintext
video_frames_processed_total{service="decoder"} 
video_processing_latency_seconds{service="decoder"}
video_errors_total{service="decoder", error_type="invalid_frame"}
```

### Grafana Dashboards
1. System Overview
    - Service health status
    - Processing throughput
    - Error rates
    - Resource usage

2. Pipeline Performance
    - Frame processing latency
    - Queue lengths
    - Success rates
    - Bandwidth usage

### Alerts
```yaml
alerts:
  - name: HighProcessingLatency
    condition: latency > 100ms
    for: 5m
    severity: warning

  - name: ServiceDown
    condition: up == 0
    for: 1m
    severity: critical
```

## Troubleshooting

### Common Issues

1. **High Latency**
```bash
# Check service logs
kubectl logs -f deployment/video-processor

# Monitor metrics
curl localhost:9090/metrics | grep processing_latency
```

2. **Service Crashes**
```bash
# Check pod status
kubectl describe pod video-processor

# View crash logs
kubectl logs pod/video-processor --previous
```

3. **Memory Issues**
```bash
# Check memory usage
kubectl top pods

# View resource limits
kubectl describe pod video-processor
```

## Development Guide

### Setting Up Development Environment
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements-dev.txt

# Generate gRPC code
./scripts/generate-protos.sh
```

### Adding New Processors
```python
class NewProcessor(BaseProcessor):
    async def process(self, frame: VideoFrame) -> ProcessingResult:
        # Implementation
        pass

    async def configure(self, config: dict) -> bool:
        # Configuration logic
        pass
```

### Running Tests
```bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# Load tests
python tests/load_testing.py --streams 10
```

## Security Guidelines

### Network Security
- Enable TLS for all gRPC connections
- Implement network policies
- Use service mesh for traffic encryption

### Access Control
- Enable RBAC for Kubernetes resources
- Implement API authentication
- Secure sensitive configurations

### Data Protection
- Encrypt sensitive data at rest
- Implement secure key management
- Regular security audits