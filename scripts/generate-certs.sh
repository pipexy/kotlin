#!/bin/bash

# Exit on any error
set -e

# Directory for certificates
CERT_DIR="certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# Generate root CA
echo "Generating root CA..."
openssl req -x509 -newkey rsa:4096 -nodes \
    -keyout ca.key \
    -out ca.crt \
    -days 365 \
    -subj "/CN=PipeXY-CA"

# Function to generate service certificate
generate_service_cert() {
    local service=$1
    echo "Generating certificate for $service..."
    
    # Generate private key
    openssl genrsa -out "${service}.key" 2048
    
    # Generate CSR
    openssl req -new \
        -key "${service}.key" \
        -out "${service}.csr" \
        -subj "/CN=${service}.pipexy.local"
    
    # Generate config file for SAN
    cat > "${service}.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.pipexy.local
DNS.3 = localhost
EOF
    
    # Sign the certificate
    openssl x509 -req \
        -in "${service}.csr" \
        -CA ca.crt \
        -CAkey ca.key \
        -CAcreateserial \
        -out "${service}.crt" \
        -days 365 \
        -extfile "${service}.ext"
    
    # Clean up CSR and config
    rm "${service}.csr" "${service}.ext"
    
    # Generate combined PEM file
    cat "${service}.crt" "${service}.key" > "${service}.pem"
    
    # Set permissions
    chmod 644 "${service}.crt"
    chmod 600 "${service}.key" "${service}.pem"
}

# Generate certificates for all services
services=("router" "decoder" "encoder" "scaler" "motion" "object" "audio" "grpc-web-proxy")

for service in "${services[@]}"; do
    generate_service_cert "$service"
done

echo "Certificates generated successfully in $CERT_DIR"
echo "Root CA certificate: $CERT_DIR/ca.crt"
echo "Service certificates are in individual .pem files"

# Create symbolic links in service directories
cd ..
for service in "${services[@]}"; do
    if [ "$service" != "grpc-web-proxy" ]; then
        mkdir -p "../services/${service}/certs"
        ln -sf "../../../${CERT_DIR}/${service}.pem" "../services/${service}/certs/"
        ln -sf "../../../${CERT_DIR}/ca.crt" "../services/${service}/certs/"
    fi
done

echo "Certificate symbolic links created in service directories"
