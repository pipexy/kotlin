# Quick Start Guide

## 1. Basic Setup

### Clone Repository
```bash
git clone https://github.com/your-org/video-processor.git
cd video-processor
```

### Set Up Environment
```bash
# Copy environment file
cp .env.example .env

# Edit configuration
vim .env
```

### Start Services
```bash
# Using Docker Compose
docker-compose up -d

# Or using management script
./scripts/manage.sh start
```

## 2. Create Your First Pipeline

### Basic RTSP to HLS Pipeline
```yaml
pipelines:
  - name: "first-pipeline"
    from: "rtsp://camera.local:554/stream"
    processors:
      - "grpc://decoder:50051/videoprocessing.Decoder/decode"
    to: "hls://localhost/stream.m3u8"
```

### Start Pipeline
```bash
# Apply configuration
kubectl apply -f config/pipelines.yaml

# Check status
kubectl get pods -l pipeline=first-pipeline
```

## 3. Monitor Your Pipeline

### Access Dashboards
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

### Check Logs
```bash
# View pipeline logs
kubectl logs -l pipeline=first-pipeline

# View specific service logs
kubectl logs -l service=decoder
```

## 4. Next Steps
1. Explore more complex pipelines
2. Add AI processing
3. Configure monitoring alerts
4. Scale your deployment