# 🚀 Quick Start Guide

Quick reference for common tasks and URLs.

---

## Service Access

Replace `YOUR_SERVER_IP` with your actual server IP address.

| Service | URL | Credentials |
|---------|-----|-------------|
| **Mender OTA** | `https://YOUR_SERVER_IP:8080/ui/` | admin@mender.local / menderadmin |
| **MeshCentral** | `https://YOUR_SERVER_IP:443` | Your created account |
| **ThingsBoard** | `http://YOUR_SERVER_IP:9090` | tenant@thingsboard.org / tenant |
| **Node-RED** | `http://YOUR_SERVER_IP:1880` | No auth required |
| **Registry UI** | `http://YOUR_SERVER_IP:8081` | No auth required |
| **MQTT Broker** | `mqtt://YOUR_SERVER_IP:1883` | No auth required |

---

## Common Commands

### View All Services

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Start Services

```bash
# Core services
docker compose -f docker-compose.core.yml up -d

# IoT services
docker compose -f docker-compose.iot.yml up -d

# Mender
cd mender-integration
./deploy-mender.sh
```

### Stop Services

```bash
# Core services
docker compose -f docker-compose.core.yml down

# IoT services
docker compose -f docker-compose.iot.yml down

# Mender
cd mender-integration
docker compose down
```

### View Logs

```bash
# All core services
docker compose -f docker-compose.core.yml logs -f

# Specific service
docker logs -f meshcentral

# Last 50 lines
docker logs --tail 50 thingsboard
```

### Restart Service

```bash
docker restart [container-name]

# Or via compose
docker compose -f docker-compose.core.yml restart meshcentral
```

---

## Quick Tasks

### Deploy Container to Raspberry Pi

```bash
# On server - build and push
docker build -t YOUR_SERVER_IP:5000/myapp:v1 .
docker push YOUR_SERVER_IP:5000/myapp:v1

# On Pi (via MeshCentral terminal)
docker pull YOUR_SERVER_IP:5000/myapp:v1
docker run -d --name myapp YOUR_SERVER_IP:5000/myapp:v1
```

### Send MQTT Test Message

```bash
mosquitto_pub -h YOUR_SERVER_IP -t test/topic -m "Hello IoT"
```

### Check Raspberry Pi Connection

**Mender:**
1. Open `https://YOUR_SERVER_IP:8080/ui/`
2. Go to Devices
3. Look for your Pi in Accepted list

**MeshCentral:**
1. Open `https://YOUR_SERVER_IP:443`
2. Your Pi should appear in device list
3. Click → Terminal for shell access

---

## Troubleshooting Quick Fixes

### Service Not Starting

```bash
docker logs [container-name]
docker restart [container-name]
```

### Pi Not Connecting to Mender

```bash
# On Pi
sudo journalctl -u mender-client -f
sudo systemctl restart mender-client
```

### MeshCentral Agent Offline

```bash
# On Pi
sudo systemctl restart meshagent
sudo ss -tnp | grep meshagent
```

---

## System Management

### Backup Data

```bash
tar -czf backup-$(date +%Y%m%d).tar.gz data/ config/
```

### Update Services

```bash
docker compose -f docker-compose.core.yml pull
docker compose -f docker-compose.core.yml up -d

docker compose -f docker-compose.iot.yml pull
docker compose -f docker-compose.iot.yml up -d
```

### Add New Raspberry Pi

```bash
# Copy setup script
scp scripts/pi-setup.sh pi@NEW_PI_IP:~/

# SSH and run
ssh pi@NEW_PI_IP
./pi-setup.sh

# Accept in Mender UI
# Install MeshAgent via MeshCentral UI
```

---

For complete setup instructions, see [COMPLETE_SETUP_GUIDE.md](../COMPLETE_SETUP_GUIDE.md)
