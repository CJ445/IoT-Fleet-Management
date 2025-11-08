# 🏗️ System Architecture

Detailed architecture documentation for the IoT Fleet Management system.

---

## Overview

The system consists of three main layers:

1. **Server Infrastructure** - Core services running on Docker
2. **IoT Platform** - Telemetry and automation services
3. **Edge Devices** - Raspberry Pi fleet with clients

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVER (YOUR_SERVER_IP)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              CORE SERVICES (fleet_net)                   │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │  MeshCentral (443, 4430, 8086)                           │  │
│  │  ├── WebSocket Server                                    │  │
│  │  ├── Agent Management                                    │  │
│  │  └── Remote Terminal/Desktop                             │  │
│  │                                                           │  │
│  │  Docker Registry (5000) + UI (8081)                      │  │
│  │  ├── Image Storage                                       │  │
│  │  └── HTTP API                                            │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           IOT TELEMETRY (fleet_net)                      │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │  Mosquitto MQTT Broker (1883, 9001)                      │  │
│  │  ├── Message Routing                                     │  │
│  │  └── Pub/Sub Protocol                                    │  │
│  │                                                           │  │
│  │  ThingsBoard (9090, 1884, 5683)                          │  │
│  │  ├── Device Management                                   │  │
│  │  ├── Data Ingestion                                      │  │
│  │  ├── Rule Engine                                         │  │
│  │  ├── Dashboards                                          │  │
│  │  └── PostgreSQL Backend                                  │  │
│  │                                                           │  │
│  │  Node-RED (1880)                                         │  │
│  │  ├── Flow Editor                                         │  │
│  │  ├── MQTT Integration                                    │  │
│  │  └── Automation Logic                                    │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         MENDER OTA PLATFORM (mender_mender)              │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                           │  │
│  │  API Gateway (Traefik) (8080:443, 8090:80)               │  │
│  │  ├── TLS Termination                                     │  │
│  │  ├── Load Balancing                                      │  │
│  │  └── Routing                                             │  │
│  │                                                           │  │
│  │  Authentication & Authorization                          │  │
│  │  ├── mender-useradm (User Management)                    │  │
│  │  └── mender-device-auth (Device Auth)                    │  │
│  │                                                           │  │
│  │  Core Services                                           │  │
│  │  ├── mender-deployments (Update Management)              │  │
│  │  ├── mender-inventory (Device Inventory)                 │  │
│  │  ├── mender-workflows-server (Orchestration)             │  │
│  │  ├── mender-workflows-worker (Task Execution)            │  │
│  │  ├── mender-deviceconnect (Remote Terminal)              │  │
│  │  ├── mender-deviceconfig (Configuration)                 │  │
│  │  ├── mender-iot-manager (IoT Integration)                │  │
│  │  └── mender-create-artifact-worker (Artifact Gen)        │  │
│  │                                                           │  │
│  │  Web Interface                                           │  │
│  │  └── mender-gui (React Frontend)                         │  │
│  │                                                           │  │
│  │  Data Storage                                            │  │
│  │  ├── PostgreSQL (Relational Data)                        │  │
│  │  ├── MongoDB (Device Data & Deployments)                 │  │
│  │  ├── Redis (Cache & Sessions)                            │  │
│  │  ├── MinIO (S3-compatible Object Storage)                │  │
│  │  └── NATS (Message Queue)                                │  │
│  │                                                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ Network: 192.168.x.0/24
                     │
        ┌────────────┴─────────────┐
        │                          │
┌───────▼──────────┐    ┌──────────▼────────┐
│  Raspberry Pi 1  │    │  Raspberry Pi N   │
├──────────────────┤    ├───────────────────┤
│                  │    │                   │
│  Mender Client   │    │  Mender Client    │
│  ├── Update Agent│    │  ├── Update Agent │
│  └── Inventory   │    │  └── Inventory    │
│                  │    │                   │
│  MeshAgent       │    │  MeshAgent        │
│  ├── WS Client   │    │  ├── WS Client    │
│  └── Remote Exec │    │  └── Remote Exec  │
│                  │    │                   │
│  Docker Engine   │    │  Docker Engine    │
│  └── App Containers   │  └── App Containers
│                  │    │                   │
│  IoT Apps        │    │  IoT Apps         │
│  └── MQTT Pub    │    │  └── MQTT Pub     │
│                  │    │                   │
└──────────────────┘    └───────────────────┘
```

---

## Component Details

### 1. Core Services Layer

#### MeshCentral
- **Purpose**: Remote device management and access
- **Ports**: 443 (HTTPS), 4430 (alt HTTPS), 8086 (HTTP redirect)
- **Technology**: Node.js, WebSockets
- **Data**: Self-signed TLS certificates, device sessions
- **Key Features**:
  - Remote terminal access
  - Remote desktop (VNC/RDP)
  - File transfer
  - Device groups and permissions

#### Docker Registry
- **Purpose**: Private container image storage
- **Ports**: 5000 (Registry API), 8081 (Web UI)
- **Technology**: Docker Registry v2, Joxit UI
- **Storage**: Local filesystem
- **Security**: Insecure registry (LAN only)

### 2. IoT Telemetry Layer

#### Mosquitto MQTT Broker
- **Purpose**: Message broker for device communication
- **Ports**: 1883 (MQTT), 9001 (WebSocket)
- **Protocol**: MQTT v3.1.1/v5.0
- **Configuration**: No authentication (can be enabled)
- **Use Cases**:
  - Device telemetry publishing
  - Command & control
  - Inter-device messaging

#### ThingsBoard
- **Purpose**: IoT platform for data visualization and management
- **Ports**: 9090 (HTTP), 1884 (MQTT), 5683 (CoAP/UDP)
- **Technology**: Java Spring Boot, Angular frontend
- **Database**: PostgreSQL
- **Key Features**:
  - Device management
  - Rule engine
  - Customizable dashboards
  - REST API
  - Multi-tenancy

#### Node-RED
- **Purpose**: Flow-based automation and integration
- **Port**: 1880 (HTTP)
- **Technology**: Node.js
- **Storage**: Local filesystem (flows)
- **Key Features**:
  - Visual flow editor
  - MQTT integration
  - HTTP endpoints
  - Function nodes (JavaScript)
  - Dashboard nodes

### 3. Mender OTA Platform

#### API Gateway (Traefik)
- **Purpose**: Reverse proxy and TLS termination
- **Ports**: 8080 (HTTPS), 8090 (HTTP)
- **Configuration**: Dynamic service discovery
- **Features**:
  - Automatic HTTPS
  - Load balancing
  - Path-based routing

#### Authentication Services
- **mender-useradm**: User account management, JWT token generation
- **mender-device-auth**: Device authentication, device key validation

#### Core Services
- **mender-deployments**: OTA update orchestration, artifact storage (MinIO)
- **mender-inventory**: Device attributes and metadata
- **mender-workflows-server**: Workflow orchestration engine
- **mender-workflows-worker**: Asynchronous task execution
- **mender-deviceconnect**: Remote terminal to devices
- **mender-deviceconfig**: Device configuration management
- **mender-iot-manager**: IoT hub integration
- **mender-create-artifact-worker**: Mender artifact generation

#### Data Stores
- **PostgreSQL**: User accounts, authentication tokens
- **MongoDB**: Deployments, device inventory, audit logs
- **Redis**: Session cache, rate limiting
- **MinIO**: Mender artifact storage (S3 API)
- **NATS**: Inter-service messaging

---

## Network Architecture

### Docker Networks

**fleet_net** (Bridge network):
- MeshCentral
- Docker Registry + UI
- Mosquitto MQTT
- ThingsBoard + PostgreSQL
- Node-RED
- Connects core and IoT services

**mender_mender** (Bridge network - auto-created):
- All Mender services
- Isolated from other services
- Internal DNS resolution

### Port Mapping

External ports exposed on `YOUR_SERVER_IP`:

| Port | Service | Protocol | Purpose |
|------|---------|----------|---------|
| 443 | MeshCentral | HTTPS/WSS | Remote access, agent communication |
| 1880 | Node-RED | HTTP | Flow editor, dashboards |
| 1883 | Mosquitto | MQTT | Device messaging |
| 4430 | MeshCentral | HTTPS | Alternative access port |
| 5000 | Docker Registry | HTTP | Container image push/pull |
| 8080 | Mender Gateway | HTTPS | Mender UI and API |
| 8081 | Registry UI | HTTP | Registry web interface |
| 8086 | MeshCentral | HTTP | HTTP redirect |
| 8090 | Mender Gateway | HTTP | Mender HTTP fallback |
| 9090 | ThingsBoard | HTTP | IoT platform UI and API |

---

## Data Flow

### 1. Device Onboarding

```
Raspberry Pi
    │
    ├─> Mender Client starts
    │   ├─> Reads /etc/mender/mender.conf
    │   ├─> Generates device key
    │   ├─> Calls /api/devices/v1/authentication/auth_requests
    │   └─> Waits for acceptance
    │
    └─> MeshAgent starts
        ├─> Reads agent configuration
        ├─> Connects WSS to MeshCentral
        └─> Registers device
```

### 2. OTA Update Deployment

```
Mender UI
    │
    ├─> Admin creates deployment
    │   ├─> Uploads artifact to MinIO
    │   └─> Targets device group
    │
    ├─> mender-deployments orchestrates
    │   └─> Stores deployment in MongoDB
    │
    └─> Mender Client polls
        ├─> GET /api/devices/v1/deployments/device/deployments/next
        ├─> Downloads artifact from MinIO
        ├─> Verifies signature
        ├─> Installs update
        └─> Reports status
```

### 3. IoT Telemetry Flow

```
IoT Sensor (on Raspberry Pi)
    │
    ├─> Reads sensor data
    ├─> Publishes MQTT message
    │   └─> mosquitto_pub -h SERVER_IP -t v1/devices/me/telemetry
    │
    ├─> Mosquitto Broker receives
    │   └─> Routes to subscribers
    │
    ├─> ThingsBoard consumes
    │   ├─> Stores in PostgreSQL
    │   ├─> Executes rule engine
    │   └─> Updates dashboards
    │
    └─> Node-RED processes (optional)
        ├─> MQTT In node receives
        ├─> Function node transforms
        └─> Triggers automation
```

### 4. Remote Access

```
Admin Browser
    │
    ├─> Opens https://SERVER_IP:443
    ├─> Authenticates to MeshCentral
    ├─> Selects Raspberry Pi device
    └─> Clicks "Terminal"
        │
        ├─> WebSocket established
        │   └─> Browser ←WSS→ MeshCentral ←WSS→ MeshAgent ←→ Bash
        │
        └─> Real-time shell access
```

---

## Security Model

### Authentication

1. **Mender**:
   - JWT tokens (RSA-signed)
   - Device keys (pre-authorization required)
   - User passwords (bcrypt hashed)

2. **MeshCentral**:
   - Username/password
   - 2FA support (optional)
   - TLS client certificates (optional)

3. **ThingsBoard**:
   - User/password
   - Device access tokens
   - OAuth2 (optional)

### Authorization

- **Mender**: Role-based (Admin, User, Read-only)
- **MeshCentral**: Device groups and user permissions
- **ThingsBoard**: Tenant-based multi-tenancy

### Network Security

- **TLS**: Self-signed certificates (can use Let's Encrypt)
- **Firewall**: Restrict ports to device network
- **VPN**: Recommended for remote admin access
- **Isolation**: Separate Docker networks

---

## Scalability

### Horizontal Scaling

Services that can be scaled:

- **mender-workflows-worker**: Add more workers for parallel deployments
- **mender-api-gateway**: Load balance with multiple Traefik instances
- **Node-RED**: Deploy multiple instances with shared MQTT
- **ThingsBoard**: Clustering mode (requires license)

### Vertical Scaling

Resource allocation per service:

| Service | Minimum RAM | Recommended RAM |
|---------|-------------|-----------------|
| MeshCentral | 512 MB | 1 GB |
| ThingsBoard | 1 GB | 2 GB |
| Mender Services | 2 GB total | 4 GB total |
| PostgreSQL | 512 MB | 1 GB |
| MongoDB | 512 MB | 1 GB |
| **Total** | **5 GB** | **10 GB** |

### Device Limits

- **MeshCentral**: Tested with 10,000+ devices
- **Mender**: Production deployments with 50,000+ devices
- **ThingsBoard**: Community edition ~1,000 devices recommended
- **MQTT**: Mosquitto can handle 100,000+ connections

---

## Monitoring & Observability

### Built-in Monitoring

- **Docker**: `docker stats`, `docker ps`
- **Mender UI**: Device status, deployment progress
- **MeshCentral**: Agent connection status
- **ThingsBoard**: Rule engine alarms

### Recommended Add-ons

- **Prometheus + Grafana**: Metrics visualization
- **ELK Stack**: Centralized logging
- **Netdata**: Real-time system monitoring
- **Uptime Kuma**: Service uptime monitoring

---

## Backup Strategy

### Critical Data

| Component | Data Location | Backup Method |
|-----------|---------------|---------------|
| MeshCentral | `./data/meshcentral/` | Daily tar.gz |
| Mender Keys | `./mender-integration/keys-generated/` | One-time secure backup |
| ThingsBoard | `./data/tb-postgres/` | PostgreSQL dump |
| Node-RED Flows | `./data/nodered/` | Git repository |
| Docker Registry | `./data/registry/` | Rsync to backup server |

### Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/iot-fleet"
DATE=$(date +%Y%m%d)

# Stop services for consistent backup
docker compose -f docker-compose.core.yml down
docker compose -f docker-compose.iot.yml down

# Backup data
tar -czf $BACKUP_DIR/iot-fleet-$DATE.tar.gz \
    data/ config/ mender-integration/keys-generated/

# Restart services
docker compose -f docker-compose.core.yml up -d
docker compose -f docker-compose.iot.yml up -d
```

---

## Disaster Recovery

### Recovery Steps

1. **Fresh server setup**
2. **Install Docker**
3. **Clone repository**
4. **Restore backup**: `tar -xzf backup.tar.gz`
5. **Start services**: `docker compose up -d`
6. **Verify**: Check all service URLs

**RTO**: ~30 minutes
**RPO**: Last backup (recommend daily)

---

For deployment instructions, see [COMPLETE_SETUP_GUIDE.md](../COMPLETE_SETUP_GUIDE.md)
