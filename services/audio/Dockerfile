FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libportaudio2 \
    libportaudiocpp0 \
    portaudio19-dev \
    libsndfile1 \
    libasound2-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY src/ .

# Create necessary directories
RUN mkdir -p /var/log/pipexy
RUN mkdir -p /certs
RUN mkdir -p /models

# Copy certificates
COPY certs/audio.pem /certs/
COPY certs/ca.crt /certs/

# Set proper permissions for certificates
RUN chmod 600 /certs/audio.pem \
    && chmod 644 /certs/ca.crt

EXPOSE ${AUDIO_PORT}

CMD ["python", "main.py"]
