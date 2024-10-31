import os
import grpc
from concurrent import futures
import logging
from prometheus_client import start_http_server

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_credentials():
    with open('/certs/encoder.pem', 'rb') as f:
        private_key = f.read()
    with open('/certs/encoder.pem', 'rb') as f:
        certificate_chain = f.read()
    with open('/certs/ca.crt', 'rb') as f:
        root_certificates = f.read()
    
    return grpc.ssl_server_credentials(
        [(private_key, certificate_chain)],
        root_certificates=root_certificates,
        require_client_auth=True
    )

def serve():
    # Start Prometheus metrics server
    metrics_port = int(os.getenv('METRICS_PORT', '8000'))
    start_http_server(metrics_port)
    
    # Create gRPC server
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    
    # Add services to the server
    # TODO: Add service implementations
    
    # Load SSL/TLS credentials
    credentials = load_credentials()
    
    # Add secure port
    port = os.getenv('ENCODER_PORT', '5002')
    server.add_secure_port(f'[::]:{port}', credentials)
    
    # Start server
    server.start()
    logger.info(f'Encoder service started on port {port}')
    
    # Keep thread alive
    server.wait_for_termination()

if __name__ == '__main__':
    serve()
