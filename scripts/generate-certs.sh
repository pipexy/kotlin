#!/bin/bash

# Exit on any error
set -e

# Directory for certificates
CERT_DIR="certs"
mkdir -p "$CERT_DIR"
cd "$CERT_DIR"

# Generate root CA
echo "Generating root CA..."
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "/CN=PipeXY-CA"

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
services=("decoder" "encoder" "scaler" "motion" "object" "audio")

for service in "${services[@]}"; do
    generate_service_cert "$service"
done

# Generate client certificate
echo "Generating client certificate..."
generate_service_cert "client"

echo "Certificates generated successfully in $CERT_DIR"
echo "Root CA certificate: $CERT_DIR/ca.crt"
echo "Service certificates are in individual .pem files"

# Create symbolic links in service directories
cd ..
for service in "${services[@]}"; do
    mkdir -p "../services/${service}/certs"
    ln -sf "../../../${CERT_DIR}/${service}.pem" "../services/${service}/certs/"
    ln -sf "../../../${CERT_DIR}/ca.crt" "../services/${service}/certs/"
done

echo "Certificate symbolic links created in service directories"
