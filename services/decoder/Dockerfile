FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
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

# Copy certificates
COPY certs/decoder.pem /certs/
COPY certs/ca.crt /certs/

# Set proper permissions for certificates
RUN chmod 600 /certs/decoder.pem \
    && chmod 644 /certs/ca.crt

EXPOSE ${DECODER_PORT}

CMD ["python", "main.py"]
