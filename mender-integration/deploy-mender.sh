#!/bin/bash

set -e

echo "========================================"
echo "Mender OTA Platform Deployment"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found"
    echo "Please run this script from the mender-integration directory"
    exit 1
fi

# Generate keys if they don't exist
if [ ! -d "keys-generated" ]; then
    echo "Generating Mender keys..."
    ./keygen
    echo "✓ Keys generated"
else
    echo "✓ Keys already exist"
fi

# Fix key permissions
echo "Setting key permissions..."
chmod 644 keys-generated/keys/useradm/private.key 2>/dev/null || true
chmod 644 keys-generated/keys/deviceauth/private.key 2>/dev/null || true
echo "✓ Permissions set"

# Create override file if it doesn't exist
if [ ! -f "docker-compose.override.yml" ]; then
    echo "Creating docker-compose.override.yml..."
    cat > docker-compose.override.yml << 'EOF'
services:
  mender-api-gateway:
    ports:
      - "8080:443"
      - "8090:80"

  mender-useradm:
    volumes:
      - ./keys-generated/keys/useradm/private.key:/etc/useradm/rsa/private.pem:ro

  mender-device-auth:
    volumes:
      - ./keys-generated/keys/deviceauth/private.key:/etc/deviceauth/rsa/private.pem:ro

  mender-deployments:
    environment:
      DEPLOYMENTS_AWS_AUTH_KEY: minioadmin
      DEPLOYMENTS_AWS_AUTH_SECRET: minioadmin
      DEPLOYMENTS_AWS_URI: http://minio:9000
EOF
    echo "✓ Override file created"
else
    echo "✓ Override file exists"
fi

echo ""
echo "Starting Mender services..."
echo "This may take 2-3 minutes..."
echo ""

# Start Mender with all required compose files
docker compose \
  -f docker-compose.yml \
  -f docker-compose.storage.minio.yml \
  -f docker-compose.automigrate.yml \
  -f docker-compose.override.yml \
  up -d

echo ""
echo "Waiting for services to start (30 seconds)..."
sleep 30

# Check if useradm container exists
if docker ps | grep -q "mender-useradm"; then
    USERADM_CONTAINER=$(docker ps --filter name=mender-useradm --format "{{.Names}}" | head -1)

    echo ""
    echo "Creating admin user..."
    echo ""

    # Create admin user
    docker exec $USERADM_CONTAINER \
      /usr/bin/useradm create-user \
      --username admin@mender.local \
      --password menderadmin || echo "User may already exist"

    echo ""
fi

echo ""
echo "========================================"
echo "Mender Deployment Complete!"
echo "========================================"
echo ""
echo "Access Mender UI at:"
echo "  https://YOUR_SERVER_IP:8080/ui/"
echo ""
echo "Default credentials:"
echo "  Username: admin@mender.local"
echo "  Password: menderadmin"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Check status:"
echo "  docker compose ps"
echo ""
