#!/bin/bash

set -e

echo "========================================"
echo "IoT Fleet Management - Full Deployment"
echo "========================================"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    echo "Please install Docker first"
    exit 1
fi

echo "✓ Docker found"

# Check docker compose
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose plugin not found"
    exit 1
fi

echo "✓ Docker Compose found"
echo ""

# Create network
echo "Creating Docker network..."
docker network create fleet_net 2>/dev/null || echo "Network already exists"
echo "✓ Network ready"
echo ""

# Deploy core services
echo "Deploying Core Services..."
echo "  - MeshCentral"
echo "  - Docker Registry"
echo ""
docker compose -f docker-compose.core.yml up -d

echo "✓ Core services started"
echo ""

# Wait a bit
echo "Waiting 10 seconds..."
sleep 10

# Deploy IoT services
echo "Deploying IoT Services..."
echo "  - Mosquitto MQTT"
echo "  - ThingsBoard"
echo "  - Node-RED"
echo ""
docker compose -f docker-compose.iot.yml up -d

echo "✓ IoT services started"
echo ""

# Deploy Mender if directory exists
if [ -d "mender-integration" ]; then
    echo "Deploying Mender OTA Platform..."
    cd mender-integration
    ./deploy-mender.sh
    cd ..
    echo "✓ Mender deployed"
else
    echo "⚠ Mender integration not found, skipping..."
    echo "  Clone mender-integration to deploy Mender OTA"
fi

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -15
echo ""
echo "Access your services:"
echo "  MeshCentral:  https://YOUR_SERVER_IP:443"
echo "  Mender:       https://YOUR_SERVER_IP:8080/ui/"
echo "  ThingsBoard:  http://YOUR_SERVER_IP:9090"
echo "  Node-RED:     http://YOUR_SERVER_IP:1880"
echo "  Registry UI:  http://YOUR_SERVER_IP:8081"
echo ""
echo "Next steps:"
echo "  1. Create MeshCentral account"
echo "  2. Setup Raspberry Pi devices (./scripts/pi-setup.sh)"
echo "  3. See COMPLETE_SETUP_GUIDE.md for details"
echo ""
