# 🤖 IoT Fleet Management System

A complete, production-ready IoT fleet management platform with OTA updates, remote device access, container deployment, and telemetry visualization.

![System Architecture](https://img.shields.io/badge/Platform-IoT%20Fleet-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Docker](https://img.shields.io/badge/Docker-Required-2496ED?logo=docker)

---

## 🎯 What You Get

A fully integrated IoT management platform running on Docker:

- **🔄 OTA Updates** - Mender platform for remote device updates
- **🖥️ Remote Access** - MeshCentral for terminal, desktop, and file access
- **📦 Container Registry** - Private Docker registry for application deployment
- **📊 IoT Telemetry** - ThingsBoard for dashboards and data visualization
- **📡 MQTT Broker** - Mosquitto for device messaging
- **🔗 Automation** - Node-RED for workflow automation

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Server (YOUR_SERVER_IP)                  │
├─────────────────────────────────────────────────────────────┤
│  Core Services                                              │
│  ├── Mender OTA (HTTPS:8080) ─────────┐                   │
│  │   ├── Device Auth                   │                   │
│  │   ├── Deployments ──> MinIO        │                   │
│  │   ├── User Management               │                   │
│  │   └── API Gateway (Traefik)        │                   │
│  │                                      │                   │
│  ├── MeshCentral (HTTPS:443) ──────────┼─> Remote Access │
│  ├── Docker Registry (:5000)           │                   │
│  └── Registry UI (:8081)               │                   │
│                                         │                   │
│  IoT Telemetry Services                │                   │
│  ├── MQTT Broker (:1883) ◄─────────────┤                   │
│  ├── ThingsBoard (:9090) ◄─────┐      │                   │
│  └── Node-RED (:1880)           │      │                   │
│                                 │      │                   │
│  Supporting Infrastructure      │      │                   │
│  ├── PostgreSQL                 │      │                   │
│  ├── MongoDB                    │      │                   │
│  ├── Redis                      │      │                   │
│  └── MinIO                      │      │                   │
└─────────────────────────────────┼──────┼───────────────────┘
                                  │      │
                  ┌───────────────┼──────┼───────────────┐
                  │         Raspberry Pi Fleet          │
                  │         (IoT Devices)               │
                  ├─────────────────────────────────────┤
                  │  Mender Client ──────────┘          │
                  │  MeshAgent ──────────────────────┘  │
                  │  Docker Engine (for apps)           │
                  └─────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- Ubuntu 20.04+ or Debian 11+ server
- 4+ CPU cores, 8GB+ RAM, 50GB+ storage
- Raspberry Pi devices (for edge deployment)
- Basic Docker knowledge

### Installation

**1. Clone this repository:**

```bash
git clone https://github.com/YOUR_USERNAME/IoT-Fleet-Management.git
cd IoT-Fleet-Management
```

**2. Follow the complete setup guide:**

📖 **[COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)** - Step-by-step installation instructions

The guide includes:
- Server preparation and Docker installation
- All service deployments with configurations
- Raspberry Pi setup automation
- Testing and verification steps
- Usage examples and troubleshooting

**3. Deploy services:**

```bash
# Deploy core services
docker compose -f docker-compose.core.yml up -d

# Deploy IoT telemetry services
docker compose -f docker-compose.iot.yml up -d

# Deploy Mender OTA platform
cd mender-integration
./deploy-mender.sh
```

**4. Setup Raspberry Pi:**

```bash
# Transfer setup script to your Pi
scp scripts/pi-setup.sh pi@YOUR_PI_IP:~/

# SSH to Pi and run
ssh pi@YOUR_PI_IP
./pi-setup.sh
```

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[COMPLETE_SETUP_GUIDE.md](COMPLETE_SETUP_GUIDE.md)** | Complete installation guide from scratch |
| **[QUICK_START.md](docs/QUICK_START.md)** | Quick reference for URLs, credentials, and commands |
| **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** | Detailed system architecture |
| **[TESTING.md](docs/TESTING.md)** | Integration testing procedures |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Common issues and solutions |

---

## 🎯 Service Access

After deployment, access your services at:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **Mender OTA** | `https://YOUR_SERVER_IP:8080/ui/` | admin@mender.local / menderadmin |
| **MeshCentral** | `https://YOUR_SERVER_IP:443` | (create account on first visit) |
| **ThingsBoard** | `http://YOUR_SERVER_IP:9090` | tenant@thingsboard.org / tenant |
| **Node-RED** | `http://YOUR_SERVER_IP:1880` | (no authentication) |
| **Docker Registry UI** | `http://YOUR_SERVER_IP:8081` | (no authentication) |

---

## 💡 Usage Examples

### Deploy Container to Raspberry Pi

```bash
# Build your app
docker build -t YOUR_SERVER_IP:5000/myapp:v1 .

# Push to registry
docker push YOUR_SERVER_IP:5000/myapp:v1

# On Raspberry Pi (via MeshCentral terminal):
docker pull YOUR_SERVER_IP:5000/myapp:v1
docker run -d YOUR_SERVER_IP:5000/myapp:v1
```

### Send IoT Telemetry

```bash
# Publish sensor data via MQTT
mosquitto_pub -h YOUR_SERVER_IP \
  -u "THINGSBOARD_ACCESS_TOKEN" \
  -t "v1/devices/me/telemetry" \
  -m '{"temperature": 25.5, "humidity": 60}'

# View in ThingsBoard dashboard
```

### Remote Access Devices

1. Open MeshCentral: `https://YOUR_SERVER_IP:443`
2. Click on your device
3. Choose: Terminal / Desktop / Files

---

## 📁 Repository Structure

```
IoT-Fleet-Management/
├── README.md                        # This file
├── COMPLETE_SETUP_GUIDE.md          # Complete installation guide
├── docker-compose.core.yml          # Core services (Registry, MeshCentral)
├── docker-compose.iot.yml           # IoT services (MQTT, ThingsBoard, Node-RED)
├── mender-integration/              # Mender OTA platform setup
│   ├── deploy-mender.sh             # Mender deployment script
│   └── docker-compose.override.yml  # Mender custom configuration
├── config/                          # Service configurations
│   ├── meshcentral/
│   │   └── config.json             # MeshCentral configuration
│   └── mosquitto/
│       └── mosquitto.conf          # MQTT broker configuration
├── scripts/                         # Helper scripts
│   ├── pi-setup.sh                 # Raspberry Pi automated setup
│   └── deploy-all.sh               # Deploy all services
├── docs/                            # Additional documentation
│   ├── QUICK_START.md
│   ├── ARCHITECTURE.md
│   ├── TESTING.md
│   └── TROUBLESHOOTING.md
└── examples/                        # Usage examples
    ├── iot-sensor-app/             # Sample IoT application
    └── nodered-flows/              # Sample Node-RED flows
```

---

## 🔧 Management Commands

### View All Services

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Check Service Logs

```bash
# Core services
docker compose -f docker-compose.core.yml logs -f

# IoT services
docker compose -f docker-compose.iot.yml logs -f

# Specific service
docker logs -f [container-name]
```

### Restart Services

```bash
# Restart all core services
docker compose -f docker-compose.core.yml restart

# Restart specific service
docker restart meshcentral
```

### Backup Data

```bash
# Backup all persistent data
tar -czf iot-fleet-backup-$(date +%Y%m%d).tar.gz data/ config/
```

---

## 🧪 Testing

Run the complete integration test workflow:

```bash
# Follow the testing guide
cat docs/TESTING.md

# Or run automated tests
./scripts/run-tests.sh
```

Tests include:
- Remote terminal access via MeshCentral
- Container deployment from registry to Pi
- MQTT message flow
- ThingsBoard telemetry ingestion
- Node-RED automation flows
- Mender OTA update simulation

---

## 🛡️ Security Considerations

### Production Deployment

For production use, implement these security measures:

1. **SSL Certificates**: Replace self-signed certs with Let's Encrypt
2. **Authentication**: Enable auth on MQTT and Node-RED
3. **Firewall**: Restrict ports with UFW/iptables
4. **Strong Passwords**: Change all default credentials
5. **Network Isolation**: Use VLANs for IoT devices
6. **Regular Updates**: Keep all services updated

See [SECURITY.md](docs/SECURITY.md) for detailed recommendations.

---

## 🐛 Troubleshooting

Common issues and solutions:

**Mender client not connecting:**
```bash
# On Raspberry Pi
sudo journalctl -u mender-client -f
sudo systemctl restart mender-client
```

**MeshCentral agent offline:**
```bash
sudo systemctl restart meshagent
```

**Service not starting:**
```bash
docker logs [container-name]
docker restart [container-name]
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more solutions.

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

This platform integrates:

- [Mender](https://mender.io/) - OTA update management
- [MeshCentral](https://meshcentral.com/) - Remote device management
- [ThingsBoard](https://thingsboard.io/) - IoT platform
- [Node-RED](https://nodered.org/) - Flow-based automation
- [Eclipse Mosquitto](https://mosquitto.org/) - MQTT broker
- [Docker Registry](https://docs.docker.com/registry/) - Container registry

---

## 📞 Support

- **Documentation**: See [docs/](docs/) folder
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/IoT-Fleet-Management/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/IoT-Fleet-Management/discussions)

---

## 🗺️ Roadmap

- [ ] Kubernetes deployment option
- [ ] Grafana monitoring integration
- [ ] Multi-tenancy support
- [ ] Cloud backend option (AWS/Azure/GCP)
- [ ] Mobile app for fleet management
- [ ] Advanced security hardening guide

---

## 📊 Statistics

- **Total Services**: 7 main + 20 supporting
- **Container Count**: ~27 containers
- **Supported Devices**: Raspberry Pi 3/4/5, other Linux ARM devices
- **Languages**: Python, JavaScript, Shell

---

**Built with ❤️ for IoT and edge computing**

**Star ⭐ this repo if you find it useful!**


## Screenshots
<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/393571ed-552c-4643-a0b9-c632ff7d1c7e" />

<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/7ea58937-83f5-4ff0-9d7f-d57e26a78d82" />

<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/9cce081d-64f2-42ad-a232-ad8649a32688" />

<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/95390bf8-7ef9-4778-be80-bf70d4405b18" />


<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/6ab07998-1f44-4377-b21d-2dee61bf2cb1" />

<img width="2879" height="1578" alt="image" src="https://github.com/user-attachments/assets/5d7ef00e-82d3-429a-a855-140ec3895819" />

---

**Version**: 1.0.0
**Last Updated**: November 2025
**Status**: Production Ready 🟢

