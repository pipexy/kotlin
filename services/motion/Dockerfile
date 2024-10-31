FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libopencv-dev \
    libatlas-base-dev \
    libhdf5-dev \
    libhdf5-serial-dev \
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
COPY certs/motion.pem /certs/
COPY certs/ca.crt /certs/

# Set proper permissions for certificates
RUN chmod 600 /certs/motion.pem \
    && chmod 644 /certs/ca.crt

EXPOSE ${MOTION_PORT}

CMD ["python", "main.py"]
