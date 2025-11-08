# IoT Sensor Simulator - Example Application

A simple IoT sensor simulator that publishes telemetry data via MQTT.

## Features

- Generates random sensor data (temperature, humidity, pressure, CPU temp)
- Publishes to MQTT broker
- ThingsBoard integration support
- Runs as Docker container or standalone Python script

## Quick Start

### Option 1: Run Locally

```bash
# Install dependencies
pip install paho-mqtt

# Run with default settings
python3 app.py

# Run with custom settings
MQTT_BROKER=192.168.1.100 python3 app.py
```

### Option 2: Run in Docker

```bash
# Build image
docker build -t iot-sensor-app:v1 .

# Run container
docker run -d \
  -e MQTT_BROKER=192.168.1.100 \
  -e ACCESS_TOKEN=your_thingsboard_token \
  --name sensor \
  iot-sensor-app:v1

# View logs
docker logs -f sensor
```

### Option 3: Deploy to Fleet

```bash
# Build and push to your registry
docker build -t YOUR_SERVER_IP:5000/iot-sensor-app:v1 .
docker push YOUR_SERVER_IP:5000/iot-sensor-app:v1

# On Raspberry Pi (via MeshCentral terminal):
docker pull YOUR_SERVER_IP:5000/iot-sensor-app:v1
docker run -d \
  -e MQTT_BROKER=YOUR_SERVER_IP \
  -e ACCESS_TOKEN=your_token \
  --name sensor \
  --restart unless-stopped \
  YOUR_SERVER_IP:5000/iot-sensor-app:v1
```

## Configuration

Environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MQTT_BROKER` | MQTT broker hostname | `192.168.1.100` |
| `MQTT_PORT` | MQTT broker port | `1883` |
| `MQTT_TOPIC` | MQTT topic | `v1/devices/me/telemetry` |
| `ACCESS_TOKEN` | ThingsBoard device token | (none) |
| `INTERVAL` | Publish interval (seconds) | `5` |

## ThingsBoard Integration

1. Create device in ThingsBoard
2. Copy access token
3. Set `ACCESS_TOKEN` environment variable
4. Data will appear in device's Latest Telemetry tab

## Data Format

Published JSON:

```json
{
  "temperature": 25.3,
  "humidity": 62.5,
  "cpu_temp": 45.2,
  "pressure": 1013.2,
  "timestamp": "2025-11-08T12:00:00.123456"
}
```

## Example Output

```
==================================================
IoT Sensor Simulator
==================================================
MQTT Broker: 192.168.1.100:1883
MQTT Topic:  v1/devices/me/telemetry
Interval:    5 seconds
ThingsBoard: Enabled (token: AbCdEfGh...)
==================================================

✓ Connected to MQTT broker at 192.168.1.100:1883
Starting sensor readings... (Ctrl+C to stop)

[0001] ✓ Published: {"temperature": 24.5, "humidity": 58.3, ...}
[0002] ✓ Published: {"temperature": 25.1, "humidity": 59.7, ...}
[0003] ✓ Published: {"temperature": 24.8, "humidity": 61.2, ...}
```

## Use Cases

- Testing MQTT connectivity
- Demonstrating ThingsBoard integration
- Learning Docker containerization
- IoT application template
