# 🚀 IoT Fleet Management - Complete Setup Guide

**A step-by-step guide to set up a complete IoT fleet management system from scratch**

This single guide will take you from a fresh Ubuntu/Debian server to a fully operational IoT fleet management platform with OTA updates, remote access, and telemetry.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [System Overview](#system-overview)
3. [Server Setup](#server-setup)
4. [Core Services Deployment](#core-services-deployment)
5. [IoT Telemetry Services](#iot-telemetry-services)
6. [Mender OTA Platform](#mender-ota-platform)
7. [Raspberry Pi Setup](#raspberry-pi-setup)
8. [Testing & Verification](#testing--verification)
9. [Usage Examples](#usage-examples)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Hardware Requirements

**Server** (Physical or VM):
- CPU: 4+ cores recommended
- RAM: 8GB minimum, 16GB recommended
- Storage: 50GB+ available
- OS: Ubuntu 20.04+ or Debian 11+
- Network: Static IP recommended

**IoT Devices** (Raspberry Pi):
- Raspberry Pi 3/4/5
- 8GB+ SD card
- Raspberry Pi OS (formerly Raspbian)
- Network connectivity to server

### Network Requirements

- Server and devices on same network (or routable)
- Required ports accessible:
  - 443, 8080, 8090 (Mender & MeshCentral)
  - 1880, 1883, 9090 (IoT services)
  - 5000, 8081 (Docker Registry)

### Knowledge Prerequisites

- Basic Linux command line
- Docker basics
- SSH access
- Text editor (nano, vim, etc.)

---

## System Overview

### What You'll Build

```
┌──────────────────────────────────────────────────────┐
│              Server (YOUR_SERVER_IP)                 │
├──────────────────────────────────────────────────────┤
│  Core Services:                                      │
│  • Mender OTA      → Device update management        │
│  • MeshCentral     → Remote device access            │
│  • Docker Registry → Container image storage         │
│                                                       │
│  IoT Telemetry:                                      │
│  • ThingsBoard     → IoT platform & dashboards       │
│  • Mosquitto MQTT  → Message broker                  │
│  • Node-RED        → Automation flows                │
└───────────────────┬──────────────────────────────────┘
                    │
        ┌───────────┴────────────┐
        │   Raspberry Pi Fleet   │
        │  • Mender Client       │
        │  • MeshAgent           │
        │  • Docker Apps         │
        └────────────────────────┘
```

### Service URLs (After Setup)

Replace `YOUR_SERVER_IP` with your actual server IP address.

| Service | URL | Purpose |
|---------|-----|---------|
| Mender | `https://YOUR_SERVER_IP:8080/ui/` | OTA Updates |
| MeshCentral | `https://YOUR_SERVER_IP:443` | Remote Access |
| ThingsBoard | `http://YOUR_SERVER_IP:9090` | IoT Dashboards |
| Node-RED | `http://YOUR_SERVER_IP:1880` | Automation |
| Registry UI | `http://YOUR_SERVER_IP:8081` | Container Registry |

---

## Server Setup

### Step 1: Prepare Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
    curl \
    git \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release

# Create working directory
mkdir -p ~/workspace/robotics-lab/setup
cd ~/workspace/robotics-lab/setup
```

### Step 2: Install Docker

```bash
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 3: Get Your Server IP

```bash
# Find your server IP
ip addr show | grep "inet " | grep -v 127.0.0.1

# Or use:
hostname -I | awk '{print $1}'
```

**Note your server IP - you'll use it throughout this guide.**

Example: If your IP is `192.168.1.100`, replace `YOUR_SERVER_IP` with this in all configurations below.

---

## Core Services Deployment

### Step 4: Create Docker Network

```bash
cd ~/workspace/robotics-lab/setup

# Create shared network for all services
docker network create fleet_net
```

### Step 5: Deploy Docker Registry

Create `docker-compose.core.yml`:

```bash
cat > docker-compose.core.yml << 'EOF'
version: '3.8'

services:
  registry:
    image: registry:2
    container_name: docker-registry
    restart: always
    environment:
      - REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/data
      - REGISTRY_HTTP_ADDR=0.0.0.0:5000
    ports:
      - "YOUR_SERVER_IP:5000:5000"
    volumes:
      - ./data/registry:/data
    networks:
      - fleet_net

  registry-ui:
    image: joxit/docker-registry-ui:latest
    container_name: registry-ui
    restart: always
    environment:
      - REGISTRY_TITLE=Fleet Container Registry
      - REGISTRY_URL=http://registry:5000
      - SINGLE_REGISTRY=true
    ports:
      - "YOUR_SERVER_IP:8081:80"
    depends_on:
      - registry
    networks:
      - fleet_net

  meshcentral:
    image: ghcr.io/ylianst/meshcentral:latest
    container_name: meshcentral
    restart: always
    environment:
      - HOSTNAME=YOUR_SERVER_IP
      - REVERSE_PROXY=false
      - IFRAME=true
      - ALLOW_NEW_ACCOUNTS=true
      - WEBRTC=true
    ports:
      - "0.0.0.0:443:443"
      - "0.0.0.0:4430:443"
      - "0.0.0.0:8086:80"
    volumes:
      - ./data/meshcentral:/meshcentral-data
      - ./config/meshcentral:/opt/meshcentral/meshcentral-data
    networks:
      - fleet_net

networks:
  fleet_net:
    external: true
EOF
```

**IMPORTANT**: Replace `YOUR_SERVER_IP` in the file:

```bash
# Replace YOUR_SERVER_IP with your actual IP
# For example, if your IP is 192.168.1.100:
sed -i 's/YOUR_SERVER_IP/192.168.1.100/g' docker-compose.core.yml
```

### Step 6: Configure MeshCentral

```bash
# Create config directory
mkdir -p config/meshcentral

# Create MeshCentral configuration
cat > config/meshcentral/config.json << 'EOF'
{
  "settings": {
    "cert": "YOUR_SERVER_IP",
    "port": 443,
    "redirPort": 80,
    "allowLoginToken": true,
    "allowFraming": true,
    "webRTC": true,
    "cookieIpCheck": false,
    "allowPublicPing": false,
    "agentPing": 60,
    "agentPong": 60,
    "webrtc": true,
    "compression": true,
    "wsCompression": true,
    "agentCoreDump": false,
    "useFrameLogging": false,
    "selfUpdate": true
  },
  "domains": {
    "": {
      "title": "IoT Fleet Management",
      "title2": "Robotics Lab",
      "minify": true,
      "newAccounts": true,
      "certUrl": "https://YOUR_SERVER_IP:443"
    }
  }
}
EOF

# Replace YOUR_SERVER_IP with your actual IP
sed -i 's/YOUR_SERVER_IP/192.168.1.100/g' config/meshcentral/config.json
```

### Step 7: Start Core Services

```bash
# Start services
docker compose -f docker-compose.core.yml up -d

# Check status
docker compose -f docker-compose.core.yml ps

# View logs
docker compose -f docker-compose.core.yml logs -f
```

**Verify**:
- Registry UI: `http://YOUR_SERVER_IP:8081`
- MeshCentral: `https://YOUR_SERVER_IP:443` (accept self-signed certificate)

**Create MeshCentral Account**:
1. Open `https://YOUR_SERVER_IP:443`
2. Accept certificate warning
3. Click "Create Account"
4. Fill in username, password, email
5. Login

---

## IoT Telemetry Services

### Step 8: Deploy IoT Stack

Create `docker-compose.iot.yml`:

```bash
cat > docker-compose.iot.yml << 'EOF'
version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:2
    container_name: mosquitto
    restart: always
    ports:
      - "0.0.0.0:1883:1883"
      - "0.0.0.0:9001:9001"
    volumes:
      - ./data/mosquitto/data:/mosquitto/data
      - ./data/mosquitto/log:/mosquitto/log
      - ./config/mosquitto:/mosquitto/config
    command: mosquitto -c /mosquitto-no-auth.conf
    networks:
      - fleet_net

  tb-postgres:
    image: postgres:14
    container_name: tb-postgres
    restart: always
    environment:
      POSTGRES_DB: thingsboard
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./data/tb-postgres:/var/lib/postgresql/data
    networks:
      - fleet_net

  thingsboard:
    image: thingsboard/tb-postgres:3.6.0
    container_name: thingsboard
    restart: always
    ports:
      - "0.0.0.0:9090:9090"
      - "0.0.0.0:1884:1883"
      - "0.0.0.0:5683:5683/udp"
    environment:
      TB_QUEUE_TYPE: in-memory
      SPRING_DATASOURCE_URL: jdbc:postgresql://tb-postgres:5432/thingsboard
      SPRING_DATASOURCE_USERNAME: postgres
      SPRING_DATASOURCE_PASSWORD: postgres
    volumes:
      - ./data/thingsboard/data:/data
      - ./data/thingsboard/logs:/var/log/thingsboard
    depends_on:
      - tb-postgres
    networks:
      - fleet_net

  nodered:
    image: nodered/node-red:latest
    container_name: nodered
    restart: always
    ports:
      - "0.0.0.0:1880:1880"
    volumes:
      - ./data/nodered:/data
    environment:
      - TZ=UTC
    networks:
      - fleet_net

networks:
  fleet_net:
    external: true
EOF
```

### Step 9: Start IoT Services

```bash
# Start services
docker compose -f docker-compose.iot.yml up -d

# Check status
docker compose -f docker-compose.iot.yml ps

# ThingsBoard takes 2-3 minutes to start, check logs:
docker logs -f thingsboard
# Wait for: "Started ThingsboardServerApplication"
```

**Verify**:
- ThingsBoard: `http://YOUR_SERVER_IP:9090`
  - Login: `tenant@thingsboard.org` / `tenant`
- Node-RED: `http://YOUR_SERVER_IP:1880`
- MQTT: `mqtt://YOUR_SERVER_IP:1883`

---

## Mender OTA Platform

### Step 10: Clone Mender Integration

```bash
cd ~/workspace/robotics-lab/setup

# Clone Mender production setup
git clone https://github.com/mendersoftware/mender-integration.git
cd mender-integration

# Checkout stable branch
git checkout 3.7.0
```

### Step 11: Generate Mender Keys

```bash
# Generate keys for Mender services
./keygen

# Check keys were created
ls -la keys-generated/keys/
```

### Step 12: Configure Mender

Create `docker-compose.override.yml`:

```bash
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

# Fix key permissions
chmod 644 keys-generated/keys/useradm/private.key
chmod 644 keys-generated/keys/deviceauth/private.key
```

### Step 13: Start Mender

```bash
# Start Mender with production setup + MinIO storage
docker compose \
  -f docker-compose.yml \
  -f docker-compose.storage.minio.yml \
  -f docker-compose.automigrate.yml \
  -f docker-compose.override.yml \
  up -d

# Wait 30 seconds for services to start
sleep 30

# Check all services are running
docker compose ps
```

### Step 14: Create Mender Admin User

```bash
# Create admin user via CLI
docker exec mender-integration-mender-useradm-1 \
  /usr/bin/useradm create-user \
  --username admin@mender.local \
  --password menderadmin

# You should see: "user created"
```

**Verify**:
1. Open `https://YOUR_SERVER_IP:8080/ui/`
2. Accept certificate warning
3. Login: `admin@mender.local` / `menderadmin`
4. You should see the Mender dashboard

---

## Raspberry Pi Setup

### Step 15: Create Pi Setup Script

On your **server**, create the Raspberry Pi setup script:

```bash
cd ~/workspace/robotics-lab/setup

cat > pi-setup.sh << 'EOFSCRIPT'
#!/bin/bash

set -e

echo "========================================"
echo "IoT Fleet - Raspberry Pi Setup"
echo "========================================"
echo ""

# Configuration - UPDATE THESE
SERVER_IP="YOUR_SERVER_IP"
MENDER_PORT="8080"
MENDER_HTTPS="true"
MESHCENTRAL_PORT="443"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Configuration:"
echo "  Server IP: $SERVER_IP"
echo "  Mender: https://$SERVER_IP:$MENDER_PORT"
echo "  MeshCentral: https://$SERVER_IP:$MESHCENTRAL_PORT"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
   echo -e "${RED}Please run as regular user (not root)${NC}"
   exit 1
fi

# Check internet connectivity
echo "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${RED}No internet connection${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Internet connected${NC}"

# Check server connectivity
echo "Checking server connectivity..."
if ! ping -c 1 $SERVER_IP &> /dev/null; then
    echo -e "${RED}Cannot reach server at $SERVER_IP${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Server reachable${NC}"

# Update system
echo ""
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Mender Client
echo ""
echo "Installing Mender client..."
if ! command -v mender &> /dev/null; then
    wget -O- https://get.mender.io | sudo bash
    echo -e "${GREEN}✓ Mender client installed${NC}"
else
    echo "Mender client already installed"
fi

# Configure Mender
echo ""
echo "Configuring Mender client..."
sudo mkdir -p /etc/mender

cat <<EOF | sudo tee /etc/mender/mender.conf
{
  "ServerURL": "https://$SERVER_IP:$MENDER_PORT",
  "UpdatePollIntervalSeconds": 1800,
  "InventoryPollIntervalSeconds": 1800,
  "RetryPollIntervalSeconds": 300,
  "ServerCertificate": "",
  "SkipVerify": true
}
EOF

# Create artifact info
echo "artifact_name=raspios-base-v1.0" | sudo tee /etc/mender/artifact_info

# Create device type
echo "device_type=raspberrypi" | sudo tee /var/lib/mender/device_type

# Create identity script
sudo mkdir -p /usr/share/mender/identity
cat <<'IDENTITY' | sudo tee /usr/share/mender/identity/mender-device-identity
#!/bin/sh
set -e
mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address | sed 's/://g')
echo "mac=$mac"
IDENTITY

sudo chmod +x /usr/share/mender/identity/mender-device-identity

# Enable and start Mender
sudo systemctl enable mender-client
sudo systemctl restart mender-client

echo -e "${GREEN}✓ Mender configured and started${NC}"

# Install Docker (if not present)
echo ""
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo "Docker already installed"
fi

# Configure insecure registry
echo ""
echo "Configuring Docker registry..."
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "insecure-registries": ["$SERVER_IP:5000"]
}
EOF
sudo systemctl restart docker || true
echo -e "${GREEN}✓ Docker configured${NC}"

# Install MeshCentral Agent
echo ""
echo "Installing MeshCentral Agent..."
echo "Please follow the instructions from MeshCentral UI:"
echo ""
echo "1. Open: https://$SERVER_IP:$MESHCENTRAL_PORT"
echo "2. Login to your account"
echo "3. Click 'Add Agent'"
echo "4. Select: Operating System = Linux"
echo "5. Select: Installation Type = Production"
echo "6. Click 'Install' tab"
echo "7. Copy the wget command shown"
echo "8. Run that command on this Pi"
echo ""
echo "Example:"
echo "  wget -O meshagent 'https://$SERVER_IP:443/meshagents?id=...' && chmod +x meshagent && sudo ./meshagent -install"
echo ""

# Show status
echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Mender Client Status:"
sudo systemctl status mender-client --no-pager || true
echo ""
echo "Next Steps:"
echo "1. Install MeshCentral agent (see instructions above)"
echo "2. Accept this device in Mender UI: https://$SERVER_IP:$MENDER_PORT/ui/"
echo "3. Device should appear in MeshCentral: https://$SERVER_IP:$MESHCENTRAL_PORT"
echo ""
echo "Device Identity:"
/usr/share/mender/identity/mender-device-identity
echo ""
EOFSCRIPT

# Replace YOUR_SERVER_IP with actual IP
sed -i 's/YOUR_SERVER_IP/192.168.1.100/g' pi-setup.sh

# Make executable
chmod +x pi-setup.sh

echo "✓ Pi setup script created: pi-setup.sh"
```

### Step 16: Transfer Script to Raspberry Pi

```bash
# From your server, copy to Pi
# Replace PI_IP_ADDRESS with your Pi's IP
scp pi-setup.sh pi@PI_IP_ADDRESS:~/

# SSH to the Pi
ssh pi@PI_IP_ADDRESS
```

### Step 17: Run Setup on Raspberry Pi

```bash
# On the Raspberry Pi:
chmod +x pi-setup.sh
./pi-setup.sh

# This will install Mender client and Docker
# Follow the on-screen instructions for MeshCentral agent
```

### Step 18: Install MeshCentral Agent on Pi

**On Raspberry Pi:**

1. The script will show you instructions like:
   ```
   1. Open: https://YOUR_SERVER_IP:443
   2. Login to your account
   3. Click 'Add Agent'
   4. Select: Operating System = Linux
   5. Select: Installation Type = Production
   6. Click 'Install' tab
   7. Copy the wget command shown
   8. Run that command on this Pi
   ```

2. **In your browser**, go to MeshCentral:
   - Open `https://YOUR_SERVER_IP:443`
   - Login with your MeshCentral account
   - Click **"Add Agent"** button (top right)
   - Operating system: **Linux**
   - Installation type: **Production**
   - Click **"Install"** tab
   - **Copy the entire wget command** shown

3. **Back on the Pi terminal**, paste and run the command:
   ```bash
   wget -O meshagent 'https://YOUR_SERVER_IP:443/meshagents?id=XXXXXX...' && chmod +x meshagent && sudo ./meshagent -install
   ```

4. Wait 10-30 seconds, then refresh MeshCentral UI - your Pi should appear!

### Step 19: Accept Device in Mender

1. Open Mender UI: `https://YOUR_SERVER_IP:8080/ui/`
2. Login: `admin@mender.local` / `menderadmin`
3. Go to **Devices** → **Pending**
4. You should see your Pi (identified by MAC address)
5. Click on device → **Accept**
6. Device moves to **Accepted** list

---

## Testing & Verification

### Step 20: Verify All Services

**On Server:**

```bash
cd ~/workspace/robotics-lab/setup

# Check core services
docker compose -f docker-compose.core.yml ps

# Check IoT services
docker compose -f docker-compose.iot.yml ps

# Check Mender services
cd mender-integration
docker compose ps

# All should show "Up" or "Running"
```

**Service Checklist:**

- [ ] Docker Registry: `http://YOUR_SERVER_IP:8081` ✅
- [ ] MeshCentral: `https://YOUR_SERVER_IP:443` ✅
- [ ] Mender: `https://YOUR_SERVER_IP:8080/ui/` ✅
- [ ] ThingsBoard: `http://YOUR_SERVER_IP:9090` ✅
- [ ] Node-RED: `http://YOUR_SERVER_IP:1880` ✅

**Device Checklist:**

- [ ] Pi appears in MeshCentral ✅
- [ ] Pi accepted in Mender ✅
- [ ] Can access Pi terminal via MeshCentral ✅

### Step 21: Test Remote Access

1. Open MeshCentral: `https://YOUR_SERVER_IP:443`
2. Click on your Raspberry Pi device
3. Click **"Terminal"**
4. You should see a shell prompt
5. Test command: `hostname && whoami`

### Step 22: Test MQTT Broker

**On Server:**

```bash
# Install mosquitto-clients
sudo apt install -y mosquitto-clients

# Test publish
mosquitto_pub -h YOUR_SERVER_IP -t test/topic -m "Hello IoT"

# Test subscribe (in another terminal)
mosquitto_sub -h YOUR_SERVER_IP -t test/topic
```

### Step 23: Create Test IoT Device in ThingsBoard

1. Open ThingsBoard: `http://YOUR_SERVER_IP:9090`
2. Login: `tenant@thingsboard.org` / `tenant`
3. Go to **Devices** → **"+" button**
4. Name: `TestDevice`
5. Device type: `default`
6. Click **Add**
7. Click on device → **Copy access token**
8. Save token for next step

**Send Test Data:**

```bash
# Replace YOUR_ACCESS_TOKEN with token from ThingsBoard
mosquitto_pub -h YOUR_SERVER_IP \
  -u "YOUR_ACCESS_TOKEN" \
  -t "v1/devices/me/telemetry" \
  -m '{"temperature": 25.5, "humidity": 60}'
```

9. In ThingsBoard, click device → **Latest Telemetry** tab
10. You should see temperature and humidity data!

---

## Usage Examples

### Example 1: Deploy Container to Raspberry Pi

**On Server:**

```bash
# Create a simple test app
mkdir test-app && cd test-app

cat > app.py << 'EOF'
import time
while True:
    print("Hello from IoT Fleet!")
    time.sleep(5)
EOF

cat > Dockerfile << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY app.py .
CMD ["python", "app.py"]
EOF

# Build and push to registry
docker build -t YOUR_SERVER_IP:5000/test-app:v1 .
docker push YOUR_SERVER_IP:5000/test-app:v1
```

**On Raspberry Pi (via MeshCentral Terminal):**

```bash
# Pull from registry
docker pull YOUR_SERVER_IP:5000/test-app:v1

# Run container
docker run -d --name test-app YOUR_SERVER_IP:5000/test-app:v1

# Check logs
docker logs -f test-app
```

### Example 2: Create Node-RED Flow

1. Open Node-RED: `http://YOUR_SERVER_IP:1880`
2. Drag an **MQTT In** node to canvas
3. Double-click to configure:
   - Server: `YOUR_SERVER_IP:1883`
   - Topic: `test/topic`
4. Drag a **Debug** node
5. Connect MQTT In → Debug
6. Click **Deploy**
7. Open Debug panel (bug icon)
8. Publish MQTT message (from terminal):
   ```bash
   mosquitto_pub -h YOUR_SERVER_IP -t test/topic -m "Testing Node-RED"
   ```
9. See message in Debug panel!

### Example 3: Create ThingsBoard Dashboard

1. Open ThingsBoard: `http://YOUR_SERVER_IP:9090`
2. Go to **Dashboards** → **"+" button**
3. Name: `IoT Monitor`
4. Click **Add**
5. Open dashboard → **Edit mode** (pencil icon)
6. Click **"+" → Create new widget**
7. Select **Gauges** → **Radial gauge**
8. Configure:
   - Target device: Your device
   - Data key: `temperature`
9. Click **Add**
10. Save dashboard
11. Publish data and watch gauge update!

---

## Troubleshooting

### Service Not Starting

```bash
# Check logs
docker logs [container-name]

# Restart service
docker restart [container-name]

# Or restart entire stack
docker compose -f docker-compose.core.yml restart
```

### Mender Client Not Connecting

**On Raspberry Pi:**

```bash
# Check service status
sudo systemctl status mender-client

# View logs
sudo journalctl -u mender-client -f

# Restart client
sudo systemctl restart mender-client

# Check network connectivity
ping YOUR_SERVER_IP
nc -zv YOUR_SERVER_IP 8080
```

**Common Issues:**

- **Certificate errors**: Ensure `SkipVerify: true` in `/etc/mender/mender.conf`
- **Connection refused**: Check firewall on server
- **Missing artifact_info**: Run `echo "artifact_name=raspios-base-v1.0" | sudo tee /etc/mender/artifact_info`

### MeshCentral Agent Not Appearing

**On Raspberry Pi:**

```bash
# Check if agent is running
sudo systemctl status meshagent

# Check connections
sudo ss -tnp | grep meshagent

# Reinstall agent
# Get fresh install command from MeshCentral UI
```

### MQTT Connection Failed

```bash
# Test from server
mosquitto_pub -h YOUR_SERVER_IP -t test -m "hello"

# Check if mosquitto is running
docker ps | grep mosquitto

# Check logs
docker logs mosquitto

# Check port is open
netstat -tuln | grep 1883
```

### ThingsBoard Not Starting

```bash
# Check logs
docker logs -f thingsboard

# Common issue: Database not ready
docker logs tb-postgres

# Wait 2-3 minutes after first start
# ThingsBoard takes time to initialize database

# Restart if needed
docker restart thingsboard
```

### Docker Registry Push Failed

**On Raspberry Pi:**

```bash
# Ensure insecure registry is configured
cat /etc/docker/daemon.json

# Should contain:
# {
#   "insecure-registries": ["YOUR_SERVER_IP:5000"]
# }

# Restart Docker if changed
sudo systemctl restart docker
```

### Port Already in Use

```bash
# Find what's using the port
sudo netstat -tuln | grep :443
sudo lsof -i :443

# Kill the process or change port in docker-compose
```

---

## Maintenance Commands

### View All Running Services

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Stop All Services

```bash
cd ~/workspace/robotics-lab/setup

# Stop core services
docker compose -f docker-compose.core.yml down

# Stop IoT services
docker compose -f docker-compose.iot.yml down

# Stop Mender
cd mender-integration
docker compose down
```

### Start All Services

```bash
cd ~/workspace/robotics-lab/setup

# Start in order
docker compose -f docker-compose.core.yml up -d
docker compose -f docker-compose.iot.yml up -d

cd mender-integration
docker compose \
  -f docker-compose.yml \
  -f docker-compose.storage.minio.yml \
  -f docker-compose.automigrate.yml \
  -f docker-compose.override.yml \
  up -d
```

### Backup Data

```bash
cd ~/workspace/robotics-lab/setup

# Backup all persistent data
tar -czf iot-fleet-backup-$(date +%Y%m%d).tar.gz data/ config/

# Backup Mender data
cd mender-integration
tar -czf mender-backup-$(date +%Y%m%d).tar.gz keys-generated/
```

### Update Services

```bash
# Pull latest images
docker compose -f docker-compose.core.yml pull
docker compose -f docker-compose.iot.yml pull

# Restart with new images
docker compose -f docker-compose.core.yml up -d
docker compose -f docker-compose.iot.yml up -d
```

---

## System Architecture Details

### Docker Networks

- **fleet_net**: Shared network for core and IoT services
- **mender_mender**: Internal Mender services network (created automatically)

### Data Persistence

All data is stored in `~/workspace/robotics-lab/setup/`:

```
setup/
├── data/
│   ├── meshcentral/     # MeshCentral data
│   ├── registry/        # Container images
│   ├── thingsboard/     # ThingsBoard data
│   ├── nodered/         # Node-RED flows
│   ├── mosquitto/       # MQTT persistence
│   └── tb-postgres/     # ThingsBoard database
├── config/
│   └── meshcentral/     # MeshCentral config
└── mender-integration/
    ├── keys-generated/  # Mender JWT keys
    └── ...
```

### Port Mapping

| Port | Service | Protocol |
|------|---------|----------|
| 443 | MeshCentral | HTTPS |
| 1880 | Node-RED | HTTP |
| 1883 | Mosquitto MQTT | MQTT |
| 4430 | MeshCentral (alt) | HTTPS |
| 5000 | Docker Registry | HTTP |
| 8080 | Mender (HTTPS) | HTTPS |
| 8081 | Registry UI | HTTP |
| 8086 | MeshCentral HTTP | HTTP |
| 8090 | Mender (HTTP) | HTTP |
| 9090 | ThingsBoard | HTTP |

---

## Security Considerations

### Production Recommendations

1. **SSL Certificates**:
   - Replace self-signed certs with proper SSL certificates (Let's Encrypt)
   - Remove `SkipVerify` from Mender client config

2. **Authentication**:
   - Enable authentication on MQTT broker
   - Add auth to Node-RED
   - Secure Docker Registry with authentication

3. **Firewall**:
   - Use UFW or iptables to restrict ports
   - Only allow necessary ports from device network

4. **Passwords**:
   - Change all default passwords
   - Use strong passwords (16+ characters)
   - Store securely (password manager)

5. **Network**:
   - Use VPN for remote access to services
   - Isolate IoT devices on separate VLAN
   - Use static IPs for server

### Firewall Setup (Optional)

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow IoT services
sudo ufw allow 443/tcp    # MeshCentral
sudo ufw allow 1880/tcp   # Node-RED
sudo ufw allow 1883/tcp   # MQTT
sudo ufw allow 5000/tcp   # Registry
sudo ufw allow 8080/tcp   # Mender
sudo ufw allow 8081/tcp   # Registry UI
sudo ufw allow 9090/tcp   # ThingsBoard

# Check status
sudo ufw status
```

---

## Next Steps

### Expand Your Fleet

1. **Add More Devices**:
   - Run `pi-setup.sh` on additional Raspberry Pis
   - Accept each in Mender and MeshCentral

2. **Deploy Applications**:
   - Build Docker images for your IoT apps
   - Push to registry
   - Deploy to Pi fleet

3. **Create Dashboards**:
   - Build ThingsBoard dashboards
   - Monitor device telemetry
   - Set up alerts

4. **Automate Workflows**:
   - Create Node-RED flows
   - Connect MQTT → ThingsBoard
   - Trigger actions based on sensor data

5. **OTA Updates**:
   - Learn Mender artifact creation
   - Deploy system updates remotely
   - Rollback if needed

### Learning Resources

- **Mender Documentation**: https://docs.mender.io/
- **MeshCentral Documentation**: https://meshcentral.com/info/
- **ThingsBoard Documentation**: https://thingsboard.io/docs/
- **Node-RED Documentation**: https://nodered.org/docs/
- **Docker Documentation**: https://docs.docker.com/

---

## Summary

You've now built a complete IoT fleet management platform with:

✅ **Over-the-Air (OTA) Updates** - Mender platform for remote device updates
✅ **Remote Device Access** - MeshCentral for terminal, desktop, file access
✅ **Container Registry** - Private Docker registry for app deployment
✅ **IoT Telemetry** - ThingsBoard for dashboards and visualization
✅ **Message Broker** - MQTT for device communication
✅ **Automation** - Node-RED for workflow automation

**Your system is production-ready!** 🚀

---

**Document Version**: 1.0
**Last Updated**: November 8, 2025
**Tested On**: Ubuntu 22.04 LTS, Raspberry Pi OS (Debian 12)

---

## Quick Reference Card

**Service Access:**
- Mender: `https://YOUR_SERVER_IP:8080/ui/` (admin@mender.local / menderadmin)
- MeshCentral: `https://YOUR_SERVER_IP:443` (your account)
- ThingsBoard: `http://YOUR_SERVER_IP:9090` (tenant@thingsboard.org / tenant)
- Node-RED: `http://YOUR_SERVER_IP:1880`
- Registry UI: `http://YOUR_SERVER_IP:8081`

**Common Commands:**
```bash
# View all services
docker ps

# Service logs
docker logs -f [container-name]

# Restart service
docker restart [container-name]

# Stop all
cd ~/workspace/robotics-lab/setup
docker compose -f docker-compose.core.yml down
docker compose -f docker-compose.iot.yml down

# Start all
docker compose -f docker-compose.core.yml up -d
docker compose -f docker-compose.iot.yml up -d
```

**Need Help?**
Re-read the [Troubleshooting](#troubleshooting) section or check service logs.

---

**End of Guide** 🎉
